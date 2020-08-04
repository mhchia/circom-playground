CIRCUIT = circuit.circom

all: after_ptau

complete: ptau after_ptau

after_ptau: compile witness proof verify

ptau:
	# 1. Start a new powers of tau ceremony
	snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
	# 2. Contribute to the ceremony
	snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v
	# 3. Provide a second contribution
	snarkjs powersoftau contribute pot12_0001.ptau pot12_0002.ptau --name="Second contribution" -v -e="some random text"
	# 4. Provide a third contribution using third party software
	snarkjs powersoftau export challenge pot12_0002.ptau challenge_0003
	snarkjs powersoftau challenge contribute bn128 challenge_0003 response_0003 -e="some random text"
	snarkjs powersoftau import response pot12_0002.ptau response_0003 pot12_0003.ptau -n="Third contribution name"
	# 5. Verify the protocol so far
	snarkjs powersoftau verify pot12_0003.ptau
	# 6. Apply a random beacon
	snarkjs powersoftau beacon pot12_0003.ptau pot12_beacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"
	# 7. Prepare phase 2
	snarkjs powersoftau prepare phase2 pot12_beacon.ptau pot12_final.ptau -v
	# 8. Verify the final ptau
	snarkjs powersoftau verify pot12_final.ptau

compile: circuit.circom
	circom circuit.circom --r1cs --wasm --sym -v
	snarkjs r1cs info circuit.r1cs
	snarkjs r1cs print circuit.r1cs circuit.sym
	snarkjs r1cs export json circuit.r1cs circuit.r1cs.json
	# Generate zkey
	snarkjs zkey new circuit.r1cs pot12_final.ptau circuit_0000.zkey
	# First
	snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v -e="entropy"
	# Second
	snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Second contribution Name" -v -e="Another random entropy"
	# Third
	snarkjs zkey export bellman circuit_0002.zkey  challenge_phase2_0003
	snarkjs zkey bellman contribute bn128 challenge_phase2_0003 response_phase2_0003 -e="some random text"
	snarkjs zkey import bellman circuit_0002.zkey response_phase2_0003 circuit_0003.zkey -n="Third contribution name"
	# Verify zky
	snarkjs zkey verify circuit.r1cs pot12_final.ptau circuit_0003.zkey
	# Apply random beacon
	snarkjs zkey beacon circuit_0003.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"
	# Verify final zkey
	snarkjs zkey verify circuit.r1cs pot12_final.ptau circuit_final.zkey
	# Export verification key
	snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

witness: circuit.wasm input.json
	snarkjs wtns calculate circuit.wasm input.json witness.wtns

proof: circuit_final.zkey witness.wtns
	snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json

verify: verification_key.json public.json proof.json
	snarkjs groth16 verify verification_key.json public.json proof.json

.PHONY: clean

clean_ptau_intermediaries:
	rm -f challenge_* response_* pot12_000*.ptau pot12_beacon.ptau

clean_ptau_final:
	rm -f pot12_final.ptau

clean_compile_interdiaries:
	rm -f circuit.sym circuit.wasm circuit.r1cs circuit.r1cs.json circuit_000*.zkey

clean_compile_final:
	rm -f circuit_final.zkey verification_key.json

clean_proofs:
	rm -f witness.wtns proof.json public.json verifier.sol

clean_except_ptau_final: clean_ptau_intermediaries clean_compile_interdiaries clean_compile_final clean_proofs

clean: clean_except_ptau_final

cleanall: clean_ptau_final clean_except_ptau_final


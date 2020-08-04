CIRCUIT = circuit.circom

all: compile witness proof verify

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

clean_ptau:
	rm -f challenge_* response_*

clean_compiled:
	rm -f circuit.sym circuit.wasm circuit.r1cs circuit.r1cs.json *.zkey verification_key.json

clean_proofs:
	rm -f witness.wtns proof.json public.json verifier.sol

clean: clean_ptau clean_compiled clean_proofs



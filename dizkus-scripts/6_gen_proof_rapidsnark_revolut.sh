#!/bin/bash

source circuit.env

# echo "****MAKE CPP FILE FOR WITNESS GENERATION****"
# start=$(date +%s)
# set -x
# make -C "$BUILD_DIR"/"$CIRCUIT_NAME"_cpp/
# { set +x; } 2>/dev/null
# end=$(date +%s)
# echo "DONE ($((end - start))s)"
# echo

# echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
# start=`date +%s`
# set -x
# ./"$BUILD_DIR"/"$CIRCUIT_NAME"_cpp/"$CIRCUIT_NAME" input_"$CIRCUIT_NAME".json "$BUILD_DIR"/witness.wtns
# { set +x; } 2>/dev/null
# end=`date +%s`
# echo "DONE ($((end-start))s)"
# echo

echo "****GENERATING PROOF FOR SAMPLE INPUT****"
start=$(date +%s)
set -x
../../../../rapidsnark/build/prover ../build/revolut_send/revolut_send.zkey ../build/revolut_send/revolut_send_witness.wtns ../build/revolut_send/rapidsnark_proof_revolut.json ../build/revolut_send/rapidsnark_public_revolut.json
{ set +x; } 2>/dev/null
end=$(date +%s)
echo "DONE ($((end - start))s)"
echo

$SNARKJS_PATH zkey export soliditycalldata ../build/revolut_send/rapidsnark_public.json ../build/revolut_send/rapidsnark_proof.json

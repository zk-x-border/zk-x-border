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
../../../../rapidsnark/build/prover ../build/venmo_send/venmo_send.zkey ../build/venmo_send/venmo_send_witness.wtns ../build/venmo_send/rapidsnark_proof_venmo.json ../build/venmo_send/rapidsnark_public_venmo.json
{ set +x; } 2>/dev/null
end=$(date +%s)
echo "DONE ($((end - start))s)"
echo

$SNARKJS_PATH zkey export soliditycalldata ../build/venmo_send/rapidsnark_public_venmo.json ../build/venmo_send/rapidsnark_proof_venmo.json

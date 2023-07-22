#!/bin/bash
source circuit.env

echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=$(date +%s)
set -x
node ../build/revolut_send/revolut_send_js/generate_witness.js ../build/revolut_send/revolut_send_js/revolut_send.wasm ../circuits/inputs/input_revolut.json ../build/revolut_send/revolut_send_witness.wtns
{ set +x; } 2>/dev/null
end=$(date +%s)
echo "DONE ($((end - start))s)"
echo

#!/bin/bash
source circuit.env

echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=$(date +%s)
set -x
node ../build/venmo_send/venmo_send_js/generate_witness.js ../build/venmo_send/venmo_send_js/venmo_send.wasm ../circuits/inputs/input_venmo.json ../build/venmo_send/venmo_send_witness.wtns
{ set +x; } 2>/dev/null
end=$(date +%s)
echo "DONE ($((end - start))s)"
echo

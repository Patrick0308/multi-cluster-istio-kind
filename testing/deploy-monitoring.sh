#!/usr/bin/env bash

set -o xtrace
#set -o errexit
set -o nounset
set -o pipefail


NUM_CLUSTERS="${1:-2}"

for i in $(seq "${NUM_CLUSTERS}"); do
  echo "Starting with cluster${i}"
  kubectl apply --context="cluster${i}" -f monitoring/
  echo
done

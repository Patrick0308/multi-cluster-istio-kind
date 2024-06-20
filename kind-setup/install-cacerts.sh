#!/usr/bin/env bash

set -o xtrace
#set -o errexit
set -o nounset
set -o pipefail


NUM_CLUSTERS="${1:-2}"
script_dir=$(dirname "$(readlink -f "$0")")

mkdir -p ${script_dir}/certs
pushd ${script_dir}/certs
make -f ${script_dir}/tools/certs/Makefile.selfsigned.mk root-ca

for i in $(seq "${NUM_CLUSTERS}"); do
  make -f ${script_dir}/tools/certs/Makefile.selfsigned.mk "cluster${i}-cacerts"
  kubectl create namespace istio-system --context "cluster${i}"
  kubectl delete secret cacerts -n istio-system --context "cluster${i}"
  kubectl create secret generic cacerts -n istio-system --context "cluster${i}" \
      --from-file="cluster${i}/ca-cert.pem" \
      --from-file="cluster${i}/ca-key.pem" \
      --from-file="cluster${i}/root-cert.pem" \
      --from-file="cluster${i}/cert-chain.pem"
  echo "----"
done


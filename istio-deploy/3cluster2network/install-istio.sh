#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail



OS="$(uname)"
NUM_CLUSTERS=3
script_dir=$(dirname "$(readlink -f "$0")")
${script_dir}/../../kind-setup/create-cluster.sh 
${script_dir}/../../kind-setup/install-cacerts.sh

for i in $(seq "${NUM_CLUSTERS}"); do
  echo "Starting istio deployment in cluster${i}"
  network=network${i}
  if [ ${i} == 2 ]
  then
    network=network1
  fi

  kubectl --context="cluster${i}" get namespace istio-system && \
    kubectl --context="cluster${i}" label namespace istio-system topology.istio.io/network="${network}" --overwrite=true

  istioctl install --force --context="cluster${i}" -f "${script_dir}/cluster${i}.yaml" -y

  echo "Generate eastwest gateway in cluster${i}"
  samples/multicluster/gen-eastwest-gateway.sh \
      --mesh "mesh1" --cluster "cluster${i}" --network "${network}" | \
      istioctl --context="cluster${i}" install -y -f -

  echo "Expose services in cluster${i}"
  kubectl --context="cluster${i}" apply -n istio-system -f ${script_dir}/samples/multicluster/expose-services.yaml

  echo
done

${script_dir}/enable-endpoint-discovery.sh

#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail



OS="$(uname)"
NUM_CLUSTERS=3
script_dir=$(dirname "$(readlink -f "$0")")
${script_dir}/../../kind-setup/create-cluster.sh ${NUM_CLUSTERS}
${script_dir}/../../kind-setup/install-cacerts.sh ${NUM_CLUSTERS}

for i in $(seq "${NUM_CLUSTERS}"); do
  echo "Starting istio deployment in cluster${i}"

  kubectl --context="cluster${i}" get namespace istio-system && \
    kubectl --context="cluster${i}" label namespace istio-system topology.istio.io/network="network${i}" --overwrite=true

   sed -e "s/{i}/${i}/" cluster.yaml > "cluster${i}.yaml"
  istioctl install --force --context="cluster${i}" -f "${script_dir}/cluster${i}.yaml" -y

  echo "Generate eastwest gateway in cluster${i}"
  ${script_dir}/samples/multicluster/gen-eastwest-gateway.sh \
      --mesh "mesh${i}" --cluster "cluster${i}" --network "network${i}" | \
      istioctl --context="cluster${i}" install -y -f -

  echo "Expose services in cluster${i}"
  kubectl --context="cluster${i}" apply -n istio-system -f ${script_dir}/samples/multicluster/expose-services.yaml

  echo
done

${script_dir}/enable-endpoint-discovery.sh

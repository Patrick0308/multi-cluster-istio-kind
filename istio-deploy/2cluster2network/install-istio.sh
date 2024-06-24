#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail



OS="$(uname)"
NUM_CLUSTERS=2
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
REPO_ROOT=$(git rev-parse --show-toplevel)
${REPO_ROOT}/kind-setup/create-cluster.sh ${NUM_CLUSTERS}
${REPO_ROOT}/kind-setup/install-cacerts.sh ${NUM_CLUSTERS}

for i in $(seq "${NUM_CLUSTERS}"); do
  echo "Starting istio deployment in cluster${i}"

  kubectl --context="cluster${i}" get namespace istio-system && \
    kubectl --context="cluster${i}" label namespace istio-system topology.istio.io/network="network${i}" --overwrite=true

  echo "Delete eastwest gateway in cluster${i}"
  kubectl delete deploy -n istio-system --context="cluster${i}" istio-eastwestgateway --ignore-not-found

  istioctl install --force --context="cluster${i}" -f "${SCRIPT_DIR}/cluster${i}.yaml" -y

  echo "Generate eastwest gateway in cluster${i}"
  ${REPO_ROOT}/istio-setup/samples/multicluster/gen-eastwest-gateway.sh \
      --mesh "mesh${i}" --cluster "cluster${i}" --network "network${i}" | \
      istioctl --context="cluster${i}" install -y -f -

  echo "Expose services in cluster${i}"
  kubectl --context="cluster${i}" apply -n istio-system -f ${REPO_ROOT}/istio-setup/samples/multicluster/expose-services.yaml

  echo
done

${SCRIPT_DIR}/enable-endpoint-discovery.sh

# Multi-Cluster Istio on Kind

This repo contains the minimal configuration to deploy istio in multi-cluster(on different networks) mode using kind.

## Dependencies

- docker
- kubectl
- kind
- istioctl
- [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind)

---

### Run cloud-provider-kind

Both ingress and egress gateway created by istio need to External IP. Cloud provider kind allocates it for them.

```shell
sudo cloud-provider-kind
```

---

## Istio Setup

It does the following for each cluster:

- install istiod with configuration
- install a gateway dedicated to east-west traffic
- expose all services (\*.local) on the east-west gateway
- install remote secret of this cluster in the other cluster to enable k8s api server endpoint discovery

```shell
./istio-deploy/${topology}/install.yaml
```

---

## Testing

### Deploy Test Applications [4](https://istio.io/latest/docs/setup/install/multicluster/verify/)

It does the following:

- create ns sample in all the cluster
- create service helloworld in all the cluster
- deploy v1 and v2 of helloworld alternatively in each cluster

```shell
./testing/deploy-application.sh ${clusters_num}
```

### Test the magic [4](https://istio.io/latest/docs/setup/install/multicluster/verify/)

Go inside a pod and try: `curl -s "helloworld.sample:5000/hello"`. The response should be like when run multiple times

```
while true; do curl -s "helloworld.sample:5000/hello"; done
```

```
Hello version: v1, instance: helloworld-v1-776f57d5f6-znwk5
Hello version: v2, instance: helloworld-v2-54df5f84b-qmg8t..
...
```

## Debug

- Go inside the proxy pod and use curl localhost:15000/help

## References:

- [Istio: Install Multi-Primary on different networks](https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/)
- [Istio: Plugin CA Cert](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)
- [Kind: MetalLB](https://kind.sigs.k8s.io/docs/user/loadbalancer/)
- [Istio: Verify MultiCluster Installation](https://istio.io/latest/docs/setup/install/multicluster/verify/)

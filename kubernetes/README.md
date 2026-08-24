[![Pods](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Fcluster_pods_running&&logo=kubernetes&color=blue)](https://kubernetes.io/)&nbsp;
[![Nodes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Fcluster_node_count&label=Nodes&logo=kubernetes&color=blue)](https://kubernetes.io/)&nbsp;
[![Uptime](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Fcluster_uptime_days&label=Uptime&logo=kubernetes&color=blue)](https://kubernetes.io/)&nbsp;
[![CPU](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Fcluster_cpu_usage&&logo=kubernetes&label=CPU)](https://kubernetes.io/)&nbsp;
[![RAM](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Fcluster_memory_usage&&logo=kubernetes&label=RAM)](https://kubernetes.io/)&nbsp;
[![Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Fkubernetes_version&label=Kubernetes&logo=kubernetes&color=blue)](https://kubernetes.io/)&nbsp;
[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.mafyuh.dev%2Ftalos_version&&logo=talos&color=blue)](https://kubernetes.io/)&nbsp;

Physical cluster on 3 Optiplex 7040 Micro's with Talos OS.

## ☁️ Core Components

- **[cert-manager](https://cert-manager.io/)** - Certificate management and Let's Encrypt integration
- **[cilium](https://github.com/cilium/cilium)** - eBPF-based networking, security, and observability
- **[rook-ceph](https://github.com/rook/rook)** - Distributed storage system providing block, object, and file storage with Ceph
- **[envoy-gateway](https://gateway.envoyproxy.io/)** - Ingress controller for routing and load balancing
- **[prometheus](https://prometheus.io/)** - Monitoring and alerting stack with Grafana Alloy
- **[external-secrets](https://external-secrets.io/latest/)** - Secrets pulled from Bitwarden Secrets.
- **[flux](https://fluxcd.io/)** - GitOps continuous delivery

### Cluster Setup

Flux is installed with [flux-aio](https://github.com/stefanprodan/flux-aio) via [Timoni](https://timoni.sh) instead of flux-operator. This cluster is bare-metal Talos with no CNI installed at first boot — flux-operator's controllers run as separate pods and can't schedule without pod networking. flux-aio bundles all Flux controllers into a single pod on `hostNetwork: true`, so it comes up before Cilium exists and is what deploys Cilium (from `kubernetes/cluster`) in the first place. This is a permanent choice for this cluster, not a bootstrap-only workaround.

Do **not** add a Cilium (or any other cluster-addon) instance to `bootstrap/flux-aio.cue`. Cilium stays owned by `kubernetes/cluster`; the bundle's only job is to get the `iac` GitRepository/Kustomization onto the cluster so Flux can take over.

The whole bootstrap is two commands (iac is public, so no `GITHUB_TOKEN` is needed):

```bash
# one-time: install Timoni and create the SOPS-age secret Flux needs for decryption
brew install stefanprodan/tap/timoni
kubectl create ns flux-system
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey=/home/$USER/.sops/key.txt

# install Flux + the iac git-sync that points Flux at ./kubernetes/flux
timoni bundle apply -f bootstrap/flux-aio.cue
```

That's the whole bootstrap. `kubernetes/flux/cluster.yaml` is picked up automatically from here on — no `kubectl apply -f kubernetes/flux/cluster.yaml` step anymore.

#### Upgrading Flux later

```bash
timoni bundle apply -f bootstrap/flux-aio.cue --dry-run --diff   # preview
timoni bundle apply -f bootstrap/flux-aio.cue                      # after bumping version: in the .cue file
```

#### Uninstall (if ever needed)

```bash
flux -n flux-system uninstall
```

#### Bootstrap gotchas (learned the hard way)

These are non-obvious constraints baked into `bootstrap/flux-aio.cue` and the repo layout. Skim before re-bootstrapping or editing the bundle.

- **Two separate security fields.** The flux-aio Timoni module has `securityProfile` (sets pod-level `securityContext`) **and** `podSecurityProfile` (sets the `pod-security.kubernetes.io/enforce` namespace label). Both must be `privileged` here. Setting only `securityProfile` leaves the namespace on Talos's cluster-wide `baseline:latest` default, and the pod is rejected with `violates PodSecurity "baseline:latest": host namespaces (hostNetwork=true), hostPort ...`. If you fix the namespace label after a failed apply, the ReplicaSet stays in backoff — `kubectl -n flux-system rollout restart deploy/flux` to break it loose.
- **kubePrism env override.** kube-proxy is disabled on this Talos cluster (Cilium's `kubeProxyReplacement` takes over), so the default `KUBERNETES_SERVICE_HOST`/`PORT` env vars kubelet injects aren't routable until Cilium is up. The bundle pins them to `localhost:7445` (kubePrism's local LB) so Flux can reach the API server before the CNI exists. Don't remove these env vars unless Cilium is already running.
- **ExternalSecret can't live in the bootstrap path.** `kubernetes/flux/` is reconciled by the `iac` Kustomization, which can't become Ready until `kubernetes/flux/cluster.yaml` is applied — and `cluster.yaml` is what creates the `cluster` Kustomization that installs external-secrets. Any `ExternalSecret` CR placed under `kubernetes/flux/` makes Flux's kustomize dry-run fail (`no matches for kind "ExternalSecret"`) and deadlocks the whole bootstrap. The `n8n-flux` ExternalSecret therefore lives at `kubernetes/cluster/external-secrets/flux/`, applied by the `external-secrets-flux` Flux Kustomization which `dependsOn: external-secrets`. Keep ExternalSecrets (and any other CR whose CRD isn't installed at bootstrap time) out of `kubernetes/flux/`.
- **Flux ports.** The flux-aio pod runs on the host network and binds `9292` (notification webhook receiver), `9690` (notification events receiver), `9790` (source-controller storage), `9791-9799` (metrics/liveness/readiness). Keep these free on whichever node the pod lands on.
- **Renovate.** Renovate's existing config tracks Helm chart versions elsewhere in this repo, but it will not automatically recognize the `version:` field inside `bootstrap/flux-aio.cue` (it's a Timoni/CUE file, not a format Renovate knows out of the box). A custom regex manager entry is needed if you want Renovate to open PRs for flux-aio version bumps too — not yet configured.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches the [kubernetes](./kubernetes) folder and applies everything defined here to the cluster. Git is the single source of truth.

Each app in [kubernetes/apps](./kubernetes/apps) has a `kustomization.yaml` that defines its namespace and Flux `Kustomization` resources, which then manage `HelmRelease` or other Kubernetes objects.

[Renovate](https://github.com/renovatebot/renovate) automatically scans for dependency updates, opens pull requests, and once merged, Flux applies the changes to the cluster.

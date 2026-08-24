bundle: {
	apiVersion: "v1alpha1"
	name:       "flux-aio"
	instances: {
		// Single-pod Flux distribution. hostNetwork + privileged profile are
		// required because this is a bare-metal Talos cluster with no CNI
		// installed yet — flux-operator's multi-pod controllers can't schedule
		// without pod networking, but this pod can, and it's what deploys
		// Cilium (from kubernetes/apps) in the first place.
		"flux": {
			module: {
				url:     "oci://ghcr.io/stefanprodan/modules/flux-aio"
				version: "2.9.4-0" // pin instead of "latest" so Renovate can bump it in a PR
			}
			namespace: "flux-system"
			values: {
				hostNetwork:        true
				securityProfile:    "privileged"
				// Required so the namespace carries the
				// pod-security.kubernetes.io/enforce=privileged label; without it
				// Talos's cluster-wide baseline:latest default blocks the pod's
				// hostNetwork/hostPorts.
				podSecurityProfile: "privileged"
				// kube-proxy is disabled on this Talos cluster (Cilium's
				// kubeProxyReplacement takes over), so the default
				// KUBERNETES_SERVICE_HOST/PORT env vars injected by kubelet
				// aren't routable until Cilium is up. 
        // Point at kubePrism's local LB instead
				env: {
					"KUBERNETES_SERVICE_HOST": "localhost"
					"KUBERNETES_SERVICE_PORT": "7445"
				}
			}
		}

		// Creates a GitRepository + Kustomization both named "iac", so that
		// kubernetes/flux/cluster.yaml's sourceRef.name: iac resolves.
		// Syncs ./kubernetes/flux, which is cluster.yaml itself — Flux then
		// self-manages the "apps" and "cluster" Kustomizations from git,
		// so there's no more manual `kubectl apply -f kubernetes/flux/cluster.yaml` step.
		"iac": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-git-sync"
			namespace: "flux-system"
			values: {
				git: {
					url:  "https://github.com/klaborda/iac"
					ref:  "refs/heads/main"
					path: "./kubernetes/flux"
				}
				sync: wait: false
			}
		}
	}
}

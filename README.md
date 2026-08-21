<div align="center">

# iac

This is my homelab infrastructure, defined in code.

</div>

---

<div align="center">

| Hypervisor                                                                                      | OS                                                                                                                                                                                                                                                                                                                                                                                             | Tools                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Networking                                                                                              | Misc. Automations                                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [![Proxmox](https://img.shields.io/badge/-Proxmox-black?logo=Proxmox)](https://www.proxmox.com) | [![Talos](https://img.shields.io/badge/Talos-black?&logo=talos)](https://www.talos.dev/) [![Ubuntu](https://img.shields.io/badge/Ubuntu-black?&logo=ubuntu&logoColor=red)](https://releases.ubuntu.com/noble/) [![Arch](https://img.shields.io/badge/Arch-black?&logo=archlinux)](https://archlinux.org/) [![NixOS](https://img.shields.io/badge/NixOS-black?&logo=nixos)](https://nixos.org/) | [![Docker](https://img.shields.io/badge/-Docker-black?logo=docker)](https://www.docker.com/) [![Kubernetes](https://img.shields.io/badge/-Kubernetes-black?logo=kubernetes)](https://k3s.io/) [![Renovate](https://img.shields.io/badge/-Renovate-black?logo=renovate&logoColor=blue)](https://github.com/renovatebot/renovate) [![OpenTofu](https://img.shields.io/badge/-OpenTofu-black?logo=opentofu)](https://opentofu.org/) [![Packer](https://img.shields.io/badge/-Packer-black?logo=packer)](https://www.packer.io/) [![Ansible](https://img.shields.io/badge/-Ansible-black?logo=ansible&logoColor=red)](https://www.ansible.com/) [![Flux](https://img.shields.io/badge/-Flux-black?logo=flux)](https://fluxcd.io/) | [![Unifi](https://img.shields.io/badge/-Unifi-black?logo=ubiquiti&logoColor=blue)](https://www.ui.com/) | [![n8n](https://img.shields.io/badge/-n8n-black?logo=n8n)](https://n8n.io/) [![Actions](https://img.shields.io/badge/-Actions-black?logo=github&logoColor=white)](https://github.com/features/actions) |

</div>

## 📖 **Overview**

This repository contains the IaC ([Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code)) configuration for my homelab.

My homelab runs two infrastructure stacks: Kubernetes and Proxmox VMs running Docker. Legacy VMs are Ubuntu cloned from templates I created with [Packer](https://www.packer.io/), I have been migrating my Ubuntu VM's over to NixOS, see Nix config [here](./nixos) and going forward all VM's will be NixOS. My Kubernetes nodes are all defined as code using [Talos Linux](https://www.talos.dev/) with [talhelper](https://github.com/budimanjojo/talhelper).

Everything is containerized — either managed with Docker Compose or orchestrated through Kubernetes. My long-term goal is to move it all to Kubernetes using **[GitOps](https://en.wikipedia.org/wiki/DevOps) practices**, and the migration is ongoing. Docker Compose sticks around mainly due to hardware limitations; scaling a homelab Kubernetes cluster means buying alot of hardware.

To automate infrastructure updates, I use **Github Actions**, which trigger workflows upon changes to this repo. This ensures seamless deployment and maintenance across my homelab:

- **[Flux](https://fluxcd.io/)** manages Continuous Deployment (CD) for Kubernetes, deployed via [Flux Operator](https://fluxcd.control-plane.io/).
- **[Docker CD Workflow](https://github.com/klaborda/iac/blob/main/.github/workflows/CD.yml)** handles Continuous Deployment for Docker services.
- **[Renovate](https://github.com/renovatebot/renovate)** keeps services updated by opening PRs for new versions.
- **[Ansible](https://github.com/ansible/ansible)** is used to execute playbooks on all of my VMs, automating management and configurations
- [**Comin**](https://github.com/nlewo/comin) keeps NixOS flakes in sync with this repo

### 🔒 **Security & Networking**

For Secret management I use [Bitwarden Secrets](https://bitwarden.com/products/secrets-manager/) and their various [integrations](https://bitwarden.com/help/ansible-integration/) into the tools used.

> Kubernetes is using External Secrets implementation of BWS, not official. BWS Access Key is SOPS encrypted.

**[GitLeaks](https://github.com/gitleaks/gitleaks)** makes sure before every commit no secrets are exposed, **[GitGuardian](https://www.gitguardian.com/)** makes sure to alert me if something slips through GitLeaks.

Each container image is automatically scanned by **[Trivy](https://trivy.dev/latest/)**, with detected vulnerabilities published to **[Github Security](https://github.com/security)**

I use **RackNerd** for their very reasonably priced VPS and deploy Docker services that require uptime here. [Tailscale](https://www.tailscale.com/) is used to connect my home network to the various VPS's securely using [Zero Trust architecture](https://en.wikipedia.org/wiki/Zero_trust_architecture).

I use [**Cloudflare**](https://www.cloudflare.com/) for my DNS provider with [**Cloudflare Tunnels**](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) to expose some of the services to the world. [**Cloudflare Access**](https://www.cloudflare.com/access/) is used as Zero Trust for public websites, this is paired with [**Fail2Ban**](https://www.fail2ban.org/) looking through all my reverse proxy logs for malicious actors who made it through [**Access**](https://www.cloudflare.com/access/) and banning them via [**Cloudflare WAF**](https://www.cloudflare.com/web-application-firewall/).

I also utilize Unifi's IDS/IPS for intrusion detection on my home network, and use **[Wazuh](https://wazuh.com/)** as a SIEM to monitor and generate security alerts across all my hosts.

### **📊 Monitoring & Observability**

I use a combination of **Grafana, fluent-bit, VictoriaLogs and Prometheus** with various exporters to collect and visualize system metrics, logs, and alerts. This helps maintain visibility into my infrastructure and detect issues proactively.

- **Prometheus** – Metrics collection and alerting
- **Victoria Logs** – Centralized logging
- **Grafana** – Dashboarding and visualization
- **Exporters** – Blackbox Exporter, Speedtest Exporter, etc.

## 🧑‍💻 **Getting Started**

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/klaborda/iac)

This repo is not structured like a project you can easily replicate. Although if you are new to any of the tools used I encourage you to read through the directories that make up each tool to see how I am using them.

Over time I will try to add more detailed instructions in each directories README.

Some good references for how I learned this stuff (other than RTFM)

- [Kubernetes Cluster Setup](https://technotim.live/posts/k3s-etcd-ansible/)
- [Kubernetes + Flux](https://technotim.live/posts/flux-devops-gitops/)
- [Kubernetes Secrets with SOPS](https://technotim.live/posts/secret-encryption-sops/)
- [Finding Kubernetes HelmReleases](https://kubesearch.dev)
- [Packer with Proxmox](https://www.youtube.com/watch?v=1nf3WOEFq1Y)
- [Terraform with Proxmox](https://www.youtube.com/watch?v=dvyeoDBUtsU)
- [Docker](https://www.youtube.com/watch?v=eGz9DS-aIeY)
- [Ansible](https://www.youtube.com/watch?v=goclfp6a2IQ)

Special thank you to [@chkpwd](https://github.com/chkpwd) for helping me get this started. [His repo](https://github.com/chkpwd/iac) was the inspiration for this.

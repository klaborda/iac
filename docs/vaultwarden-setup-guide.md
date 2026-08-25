# Vaultwarden + External Secrets Migration Guide

This guide covers migrating from Bitwarden Secrets Manager (BWS) to a
self-hosted Vaultwarden instance using the
[eznix86/bitwarden-external-secrets](https://github.com/eznix86/bitwarden-external-secrets)
chart.

## Prerequisites

- A working Vaultwarden instance (self-hosted or external)
- `sops` CLI installed (`v3.13+`)
- `age` CLI installed
- Your SOPS age private key at `~/.sops/key.txt`
- The age public key: `age1rh7m647fsdmm7a2yy6un6fn845e8gmfxwnjz0gtdku77n0jsjsyqfqegpf`
- `kubectl` access to the cluster
- Flux CLI (optional, for manual reconciliation)

---

## Phase 1: Create Vaultwarden Credentials

### 1.1 Deploy Vaultwarden (if not already running)

Deploy a Vaultwarden instance (container, VM, or Kubernetes manifest). Note the
URL — you'll need it for `bw_host`. Example:

```
https://vaultwarden.yourdomain.com
```

### 1.2 Create a Vaultwarden Account

1. Navigate to your Vaultwarden URL
2. Create an account with:
   - Email
   - Master password (this becomes `bw_password`)
3. Verify the email if required

### 1.3 Get the API Key (client ID + client secret)

1. Log into Vaultwarden
2. Go to **Settings** → **Account info** → **API Key** (or
   `https://vaultwarden.yourdomain.com/#/settings/account`)
3. Enter master password to view the API Key
4. Copy:
   - **Client ID** — this becomes `bw_clientid`
   - **Client Secret** — this becomes `bw_clientsecret`

> **Warning:** These credentials grant full vault access. Treat them like
> root passwords. They will be SOPS-encrypted in the repo.

### 1.4 Test the credentials

Use the Bitwarden CLI to verify:

```bash
# Install bw CLI if needed
npm install -g @bitwarden/cli

# Login with API key
export BW_HOST=https://vaultwarden.yourdomain.com
bw login --apikey
# Enter client ID and client secret when prompted
# Enter master password when prompted

# Verify vault access
bw sync
bw list items
```

If the above works, your credentials are valid.

---

## Phase 2: Encrypt Credentials with SOPS

### 2.1 Edit the SOPS-encrypted credentials file

The file is at:
```
kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml
```

To edit it:

```bash
# Set the SOPS age key file path
export SOPS_AGE_KEY_FILE=~/.sops/key.txt

# Decrypt and edit in-place (SOPS opens your $EDITOR)
sops kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml
```

Replace the placeholder values:

| Field | Replace with |
|---|---|
| `bw_clientid` | Your Vaultwarden Client ID |
| `bw_clientsecret` | Your Vaultwarden Client Secret |
| `bw_password` | Your Vaultwarden Master Password |
| `bw_host` | Your Vaultwarden URL (e.g. `https://vaultwarden.yourdomain.com`) |

Save and exit your editor. SOPS will re-encrypt automatically.

### 2.2 Verify encryption

```bash
# Should show ENC[...] values (encrypted)
cat kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml

# Decrypt to verify values are correct (without saving)
sops -d kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml
```

### 2.3 How SOPS works in this repo

- `.sops.yaml` at the repo root defines encryption rules
- Files matching `kubernetes/.*\.sops\.ya?ml` are encrypted with your age key
- Only `data` and `stringData` fields are encrypted (the rest stays plaintext)
- Flux's kustomize-controller decrypts at apply time using the `sops-age`
  Secret in `flux-system` namespace

---

## Phase 3: Create Vault Items

For each secret in the migration table (see
[`docs/vaultwarden-migration.md`](./vaultwarden-migration.md)), create a
corresponding item in your Vaultwarden vault.

### 3.1 Item types and their ClusterSecretStore

The eznix86 chart creates 4 ClusterSecretStores automatically:

| Store Name | Item Type | `remoteRef.property` |
|---|---|---|
| `bitwarden-login` | Login item | `username` or `password` |
| `bitwarden-field` | Any item with custom fields | field name (e.g. `api_key`) |
| `bitwarden-note` | Secure note | (no property needed) |
| `bitwarden-ssh-key` | SSH key item | `privateKey`, `publicKey`, or `keyFingerprint` |

### 3.2 Creating items

For most secrets (API tokens, passwords, etc.), the simplest approach is:

1. Create a **Login item** in Vaultwarden
2. Put the secret value in the `password` field (or `username` if it's a
   user identifier)
3. For secrets that don't fit the login model (e.g. URLs, connection strings),
   use a **Secure Note** or add a **custom field** to any item

### 3.3 Getting the item ID

After creating an item in Vaultwarden:

1. Click on the item in the web vault
2. Look at the URL in your browser:
   ```
   https://vaultwarden.yourdomain.com/#/vault/item/<ITEM_ID>
   ```
3. Copy the `<ITEM_ID>` — this goes into `remoteRef.key` in the ExternalSecret

> **Tip:** You can also get item IDs via the CLI:
> ```bash
> bw sync
> bw list items --search "Grafana" | jq '.[].id'
> ```

### 3.4 Shared secrets

Some secrets are reused across multiple ExternalSecrets (noted in the
migration table). You only need to create these once in Vaultwarden:

| Secret | Used by |
|---|---|
| MinIO secret key | postgres component, crunchy-pgo, immich, tofu-controller |
| Kopia password | kopia, volsync component |
| PostgreSQL host | netbox, authentik |
| PostgreSQL name/user | authentik (same value for both fields) |

---

## Phase 4: Update ExternalSecret Resources

For each of the 21 ExternalSecret files listed in
[`docs/vaultwarden-migration.md`](./vaultwarden-migration.md):

### 4.1 Change the secretStoreRef

```yaml
# Before (BWS)
secretStoreRef:
  name: bitwarden-secrets-manager
  kind: ClusterSecretStore

# After (Vaultwarden)
secretStoreRef:
  name: bitwarden-login  # or bitwarden-field, bitwarden-note, bitwarden-ssh-key
  kind: ClusterSecretStore
```

### 4.2 Update remoteRef

```yaml
# Before (BWS — UUID was the secret ID, no property needed)
data:
  - secretKey: GF_SECURITY_ADMIN_PASSWORD
    remoteRef:
      key: "c98a3540-e2ee-465d-9c48-b371015bc053"

# After (Vaultwarden — key is the item ID, property specifies which field)
data:
  - secretKey: GF_SECURITY_ADMIN_PASSWORD
    remoteRef:
      key: "<vaultwarden-item-id>"  # from the Vaultwarden URL
      property: password  # "username", "password", or custom field name
```

### 4.3 Template-based ExternalSecrets

Five ExternalSecrets use `target.template` to render multi-key secrets (e.g.
`s3.conf`, `TUNNEL_TOKEN`). These work as-is — the template references the
`secretKey` names, not the provider. Only update the `secretStoreRef` and
`remoteRef` fields.

Affected files:
- `kubernetes/apps/default/immich/app/external-secret.yaml`
- `kubernetes/components/volsync/external-secrets.yaml`
- `kubernetes/apps/networking/cloudflared/app/external-secret.yaml`
- `kubernetes/components/postgres/external-secret.yaml`
- `kubernetes/apps/databases/crunchy-pgo/app/external-secret.yaml`

---

## Phase 5: Deploy and Verify

### 5.1 Commit and push

```bash
git add -A
git commit -m "feat(external-secrets): update ExternalSecrets for Vaultwarden"
git push
```

### 5.2 Trigger Flux reconciliation

```bash
# Force GitRepository to fetch new commit
kubectl annotate gitrepository iac -n flux-system \
  source.toolkit.fluxcd.io/reconcileAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite

# Wait ~30s, then trigger iac kustomization
kubectl annotate kustomization iac -n flux-system \
  kustomize.toolkit.fluxcd.io/reconcileAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite

# Wait ~30s, then trigger cluster kustomization
kubectl annotate kustomization cluster -n flux-system \
  kustomize.toolkit.fluxcd.io/reconcileAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite

# Wait ~30s, then trigger bitwarden-cli
kubectl annotate kustomization bitwarden-cli -n security \
  kustomize.toolkit.fluxcd.io/reconcileAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite
```

### 5.3 Check the bitwarden-cli deployment

```bash
# Pods should be Running
kubectl get pods -n security -l app.kubernetes.io/instance=bitwarden-external-secrets

# Check the bitwarden-cli service
kubectl get svc -n security bitwarden-cli

# Check the ClusterSecretStores (should be Valid)
kubectl get clustersecretstore -A
```

### 5.4 Verify ExternalSecrets

```bash
# All ExternalSecrets should be Synced=True
kubectl get externalsecret -A

# Check a specific one
kubectl describe externalsecret grafana-admin-secret -n monitoring
```

### 5.5 Troubleshooting

If ExternalSecrets are not syncing:

1. **Check the ClusterSecretStore status:**
   ```bash
   kubectl describe clustersecretstore bitwarden-login
   ```

2. **Check bitwarden-cli pod logs:**
   ```bash
   kubectl logs -n security -l app.kubernetes.io/instance=bitwarden-external-secrets
   ```

3. **Test the bitwarden-cli API directly:**
   ```bash
   kubectl exec -n security deploy/bitwarden-cli -- \
     wget -qO- http://127.0.0.1:8087/sync?force=true
   ```

4. **Verify the vaultwarden-credentials secret was decrypted:**
   ```bash
   kubectl get secret vaultwarden-credentials -n security -o jsonpath='{.data}' | jq -r 'keys[]'
   ```

5. **Common issues:**
   - `SecretSyncError`: Wrong item ID — verify in Vaultwarden web vault
   - `401 Unauthorized`: Wrong client ID/secret or master password
   - `Connection refused`: `bw_host` URL is wrong or unreachable from cluster
   - `property not found`: The item doesn't have the specified field — check
     the item type and property name

---

## Quick Reference

### Files changed in this migration

| File | Change |
|---|---|
| `.sops.yaml` | Updated age key to cluster's own |
| `kubernetes/flux/charts/eznix86-chart.yaml` | New HelmRepository |
| `kubernetes/flux/charts/kustomization.yaml` | Added eznix86-chart |
| `kubernetes/cluster/bitwarden-cli/app/helmrelease.yaml` | New HelmRelease |
| `kubernetes/cluster/bitwarden-cli/app/kustomization.yaml` | New kustomization |
| `kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml` | SOPS-encrypted credentials |
| `kubernetes/cluster/bitwarden-cli/ks.yaml` | New Flux Kustomization |
| `kubernetes/cluster/kustomization.yaml` | Added bitwarden-cli/ks.yaml |
| `kubernetes/cluster/external-secrets/app/helmrelease.yaml` | Removed BWS SDK block |
| `kubernetes/cluster/external-secrets/app/kustomization.yaml` | Removed secretstore + bws-access-token |
| `kubernetes/cluster/external-secrets/ks.yaml` | Removed SOPS decryption |
| `kubernetes/cluster/external-secrets/app/secretstore.yaml` | Deleted |
| `kubernetes/cluster/external-secrets/app/bws-access-token.sops.yaml` | Deleted |

### ClusterSecretStores created by the eznix86 chart

| Name | Provider | Use Case |
|---|---|---|
| `bitwarden-login` | webhook | Login items (`username`, `password`) |
| `bitwarden-field` | webhook | Custom fields on any item |
| `bitwarden-note` | webhook | Secure notes |
| `bitwarden-ssh-key` | webhook | SSH keys (`privateKey`, `publicKey`, `keyFingerprint`) |

### SOPS commands cheat sheet

```bash
# Set the age key file
export SOPS_AGE_KEY_FILE=~/.sops/key.txt

# Edit an encrypted file (decrypts, opens editor, re-encrypts on save)
sops kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml

# Decrypt to stdout (does not modify file)
sops -d kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml

# Re-encrypt after changing .sops.yaml rules
sops updatekeys kubernetes/cluster/bitwarden-cli/app/vaultwarden-credentials.sops.yaml

# Encrypt a new file from scratch
sops --encrypt --in-place kubernetes/cluster/some-app/app/secret.sops.yaml
```

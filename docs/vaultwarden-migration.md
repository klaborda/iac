# ExternalSecret Migration Mapping: BWS -> Vaultwarden

This table tracks all 21 ExternalSecret resources that need to be migrated from
Bitwarden Secrets Manager (BWS) to the eznix86 bitwarden-external-secrets webhook
provider backed by your Vaultwarden instance.

## How to use this table

1. Log into your Vaultwarden instance
2. Create each item (login, secure note, SSH key, or item with custom fields)
3. Copy the item ID from the URL: `https://vaultwarden.example.com/#/vault/<item-type>/<ITEM_ID>`
4. Fill in the `New Item ID` and `Property` columns
5. Update the corresponding `external-secret.yaml` file

## ClusterSecretStore Reference

The eznix86 chart creates 4 ClusterSecretStores automatically:

| Store Name | Use Case | remoteRef.property values |
|---|---|---|
| `bitwarden-login` | Login items (username/password) | `username`, `password` |
| `bitwarden-field` | Custom fields on any item | field name (e.g. `api_key`, `token`) |
| `bitwarden-note` | Secure notes | (no property needed) |
| `bitwarden-ssh-key` | SSH keys | `privateKey`, `publicKey`, `keyFingerprint` |

## Migration Table

### 1. pgadmin (databases)
- **File:** `kubernetes/apps/databases/pgadmin/app/external-secret.yaml`
- **ExternalSecret:** `pgadmin-secret`
- **Store:** `bitwarden-login` (for password), `bitwarden-field` or `bitwarden-login` (for email)

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| PGADMIN_DEFAULT_PASSWORD | `86f62c21-8919-48cb-ab91-b3100173e3cf` | `bitwarden-login` | _____ | `password` |
| PGADMIN_DEFAULT_EMAIL | `1a8ec95e-4c56-49e8-ab9d-b3cd00274b2d` | `bitwarden-login` | _____ | `username` |

### 2. postgres component (shared, used by crunchy-pgo/immich)
- **File:** `kubernetes/components/postgres/external-secret.yaml`
- **ExternalSecret:** `${APP}-crunchy-postgres` (templated, used by multiple apps)
- **Store:** `bitwarden-field` (MinIO secret key is a custom field on a login item)

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| PG_MINIO_SECRET_KEY | `444d8094-5d11-4b3b-92a7-b371017e2269` | `bitwarden-field` | _____ | `minio_secret_key` |

### 3. crunchy-pgo (databases)
- **File:** `kubernetes/apps/databases/crunchy-pgo/app/external-secret.yaml`
- **ExternalSecret:** `pg-cluster-crunchy-postgres`
- **Store:** `bitwarden-field`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| PG_MINIO_SECRET_KEY | `444d8094-5d11-4b3b-92a7-b371017e2269` | `bitwarden-field` | _____ | `minio_secret_key` |

### 4. kopia (storage)
- **File:** `kubernetes/apps/storage/kopia/app/external-secret.yaml`
- **ExternalSecret:** `kopia`
- **Store:** `bitwarden-field` or `bitwarden-note`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| KOPIA_PASSWORD | `7bdf35e6-c19c-4b65-aa6d-b38c0108a1ad` | `bitwarden-field` | _____ | `kopia_password` |

### 5. crd-schema-publisher (cluster)
- **File:** `kubernetes/cluster/crd-schema-publisher/app/external-secret.yaml`
- **ExternalSecret:** `crd-schema-publisher-cloudflare`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| CLOUDFLARE_API_TOKEN | `cebf1df0-cbe0-4f31-80f1-b453003aad10` | `bitwarden-field` | _____ | `api_token` |
| CLOUDFLARE_ACCOUNT_ID | `c37639ff-ffd3-41cc-b875-b2b7012859d7` | `bitwarden-field` | _____ | `account_id` |

### 6. netbox (networking)
- **File:** `kubernetes/apps/networking/netbox/app/external-secret.yaml`
- **ExternalSecret:** `netbox-secrets`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| NETBOX_ADMIN_PASSWORD | `9b30f1cd-39ac-4420-9258-b372000f935a` | `bitwarden-login` | _____ | `password` |
| MAIN_PG_DB_HOST | `3ce5db00-b092-4fca-b295-b3710189f0b1` | `bitwarden-field` | _____ | `pg_host` |

### 7. flux-instance (flux-system)
- **File:** `kubernetes/cluster/flux-instance/app/external-secret.yaml`
- **ExternalSecret:** `flux-webhook-token`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| token | `2bb99d70-abd9-4b1e-9530-b37101017a9d` | `bitwarden-field` | _____ | `webhook_token` |

### 8. immich (default) - shared MinIO secret
- **File:** `kubernetes/apps/default/immich/app/external-secret.yaml`
- **ExternalSecret:** `immich-crunchy-postgres`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| PG_MINIO_SECRET_KEY | `444d8094-5d11-4b3b-92a7-b371017e2269` | `bitwarden-field` | _____ | `minio_secret_key` |

### 9. cloudflared (networking) - uses target.template
- **File:** `kubernetes/apps/networking/cloudflared/app/external-secret.yaml`
- **ExternalSecret:** `cloudflared-secret`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| token | `e7e4e774-0571-4a28-8040-b39e00143446` | `bitwarden-field` | _____ | `tunnel_token` |

### 10. n8n-flux (flux-system)
- **File:** `kubernetes/cluster/external-secrets/flux/external-secret.yaml`
- **ExternalSecret:** `n8n-flux`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| address | `018aed97-d779-4d84-8688-b37b01246808` | `bitwarden-field` | _____ | `n8n_address` |

### 11. homepage (default) - 15 entries
- **File:** `kubernetes/apps/default/homepage/app/external-secret.yaml`
- **ExternalSecret:** `homepage-secret`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| HOMEPAGE_VAR_UNIFI_TOKEN | `e9d80f2d-726a-4bf9-89fb-b3e700364930` | `bitwarden-field` | _____ | `unifi_token` |
| HOMEPAGE_VAR_TRUENAS_TOKEN | `a0e2a2fa-14a0-4391-9d76-b3e70033c518` | `bitwarden-field` | _____ | `truenas_token` |
| HOMEPAGE_VAR_PROXMOX_TOKEN | `b58b92cd-a565-4e9e-a19e-b3e701874d89` | `bitwarden-field` | _____ | `proxmox_token` |
| HOMEPAGE_VAR_PBS_TOKEN | `b279b6fd-a11d-44ab-8d35-b3e8002e922b` | `bitwarden-field` | _____ | `pbs_token` |
| HOMEPAGE_VAR_BAZARR_TOKEN | `489316a4-8c2f-4fa7-acf9-b25b005e006b` | `bitwarden-field` | _____ | `bazarr_token` |
| HOMEPAGE_VAR_PROWLARR_TOKEN | `b38013bc-4caf-4788-8fb2-b25b005d6b02` | `bitwarden-field` | _____ | `prowlarr_token` |
| HOMEPAGE_VAR_RADARR_TOKEN | `46efe854-cfff-49aa-9403-b25b005b8bb8` | `bitwarden-field` | _____ | `radarr_token` |
| HOMEPAGE_VAR_SONARR_TOKEN | `eb97b60f-f7f1-4f37-b6c9-b258004aca85` | `bitwarden-field` | _____ | `sonarr_token` |
| HOMEPAGE_VAR_LIDARR_TOKEN | `bfddd2d0-ba79-47b6-b706-b371017bea28` | `bitwarden-field` | _____ | `lidarr_token` |
| HOMEPAGE_VAR_JELLYFIN_API_KEY | `243b914d-d5c4-442e-87ad-b3e70181ee5c` | `bitwarden-field` | _____ | `jellyfin_api_key` |
| HOMEPAGE_VAR_JELLYSEERR_TOKEN | `9f3c9356-b984-42a8-aa29-b3e80014f1a7` | `bitwarden-field` | _____ | `jellyseerr_token` |
| HOMEPAGE_VAR_SABNZBD_API_KEY | `76f700af-4d22-4377-991f-b25b005de1b0` | `bitwarden-field` | _____ | `sabnzbd_api_key` |
| HOMEPAGE_VAR_AUTHENTIK_TOKEN | `6c906ff4-9465-415d-832e-b3e70034a347` | `bitwarden-field` | _____ | `authentik_token` |
| HOMEPAGE_VAR_GOTIFY_TOKEN | `28cc26b9-eb3f-4601-bc2b-b3e80033d288` | `bitwarden-field` | _____ | `gotify_token` |
| HOMEPAGE_VAR_IMMICH_TOKEN | `6b12d46e-4290-4526-a722-b3e70032ca2e` | `bitwarden-field` | _____ | `immich_token` |
| PUBLIC_DOMAIN | `fa7aa6c7-7c9e-4db1-b5c7-b372002cd0a2` | `bitwarden-field` | _____ | `public_domain` |

### 12. authentik (security) - 8 entries
- **File:** `kubernetes/apps/security/authentik/app/external-secret.yaml`
- **ExternalSecret:** `authentik-secrets`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| AUTHENTIK_POSTGRESQL_HOST | `3ce5db00-b092-4fca-b295-b3710189f0b1` | `bitwarden-field` | _____ | `pg_host` |
| AUTHENTIK_POSTGRESQL_NAME | `2f426546-93ef-46d9-a172-b371018a22e1` | `bitwarden-field` | _____ | `pg_name` |
| AUTHENTIK_POSTGRESQL_USER | `2f426546-93ef-46d9-a172-b371018a22e1` | `bitwarden-field` | _____ | `pg_name` |
| AUTHENTIK_POSTGRESQL_PASSWORD | `61cb3b41-6ce2-4c76-bdfd-b371018a5b3a` | `bitwarden-field` | _____ | `pg_password` |
| AUTHENTIK_POSTGRESQL_PORT | `0febaa04-47db-488f-a6a7-b371018aa144` | `bitwarden-field` | _____ | `pg_port` |
| AUTHENTIK_SMTP_PASSWORD | `b452debb-b0c6-4ce7-9bef-b371018b451a` | `bitwarden-field` | _____ | `smtp_password` |
| AUTHENTIK_SECRET_KEY | `e7ff189f-551d-49b8-ad0e-b37200004a6d` | `bitwarden-field` | _____ | `secret_key` |
| AUTHENTIK_DOMAIN | `2cd54b6a-e723-4fe9-974b-b37200064146` | `bitwarden-field` | _____ | `domain` |

### 13. cert-manager (cluster)
- **File:** `kubernetes/cluster/cert-manager/issuers/external-secret.yaml`
- **ExternalSecret:** `cloudflare-token-secret`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| cloudflare-token | `6ebe9a29-7979-455c-81de-b37101754245` | `bitwarden-field` | _____ | `cloudflare_token` |

### 14. rook-ceph (cluster)
- **File:** `kubernetes/cluster/rook-ceph/app/external-secret.yaml`
- **ExternalSecret:** `rook-ceph-dashboard`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| rook-ceph-dashboard-password | `22b6c7e9-c70a-4f3d-91aa-b25f004fdc41` | `bitwarden-field` | _____ | `dashboard_password` |

### 15. prometheus (monitoring)
- **File:** `kubernetes/apps/monitoring/prometheus/app/external-secret.yaml`
- **ExternalSecret:** `prometheus-secrets`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| N8N_GOTIFY_ALERTM | `4536e57b-6834-4523-82b9-b372001a8309` | `bitwarden-field` | _____ | `n8n_gotify_alertm` |

### 16. gatus (monitoring) - 3 entries
- **File:** `kubernetes/apps/monitoring/gatus/app/external-secret.yaml`
- **ExternalSecret:** `gatus-secrets`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| GOTIFY_GATUS_TOKEN | `8ffa22f9-99f3-4245-bf48-b3720020121f` | `bitwarden-field` | _____ | `gotify_token` |
| GATUS_PG_PASS | `20b19d8a-45a5-4d9b-8993-b3720026bc7f` | `bitwarden-field` | _____ | `gatus_pg_pass` |
| GOTIFY_URL | `a1399917-2428-492f-a35d-b37200273d61` | `bitwarden-field` | _____ | `gotify_url` |

### 17. umami (monitoring) - 2 entries
- **File:** `kubernetes/apps/monitoring/umami/app/external-secret.yaml`
- **ExternalSecret:** `umami-secrets`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| APP_SECRET | `54efda55-1810-4d90-8794-b2d9004aed56` | `bitwarden-field` | _____ | `app_secret` |
| DATABASE_URL | `30bb5614-f396-408e-b58b-b3d400024db6` | `bitwarden-field` | _____ | `database_url` |

### 18. unpoller (monitoring)
- **File:** `kubernetes/apps/monitoring/unpoller/app/external-secret.yaml`
- **ExternalSecret:** `unpoller-secrets`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| UP_UNIFI_DEFAULT_PASS | `4ada17ee-d997-425d-97d6-b3720016072a` | `bitwarden-login` | _____ | `password` |

### 19. grafana (monitoring)
- **File:** `kubernetes/apps/monitoring/grafana/app/external-secret.yaml`
- **ExternalSecret:** `grafana-admin-secret`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| GF_SECURITY_ADMIN_PASSWORD | `c98a3540-e2ee-465d-9c48-b371015bc053` | `bitwarden-login` | _____ | `password` |

### 20. volsync component - shared with kopia
- **File:** `kubernetes/components/volsync/external-secrets.yaml`
- **ExternalSecret:** `${APP}-volsync` (templated)

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| KOPIA_PASSWORD | `7bdf35e6-c19c-4b65-aa6d-b38c0108a1ad` | `bitwarden-field` | _____ | `kopia_password` |

### 21. tofu-controller (flux-system) - 3 entries
- **File:** `kubernetes/cluster/tofu-controller/app/external-secrets.yaml`
- **ExternalSecret:** `terraform-s3-backend`

| secretKey | Old BWS UUID | New Store | New Item ID | Property |
|---|---|---|---|---|
| access_key | `713c22ac-210f-42bf-ab4e-b371017dd0dd` | `bitwarden-field` | _____ | `access_key` |
| secret_key | `444d8094-5d11-4b3b-92a7-b371017e2269` | `bitwarden-field` | _____ | `minio_secret_key` |
| BWS_ACCESS_TOKEN | `8fb79d82-8fca-4718-8409-b3720103295e` | `bitwarden-field` | _____ | `bws_access_token` |

## Notes on Shared Secrets

Some UUIDs are reused across multiple ExternalSecrets:
- `444d8094-...` (MinIO secret key) — used in #2, #3, #8, #21
- `7bdf35e6-...` (Kopia password) — used in #4 and #20
- `3ce5db00-...` (PG host) — used in #6 (netbox) and #12 (authentik)
- `2f426546-...` (PG name/user) — used twice within #12 (authentik)

When creating items in Vaultwarden, you can create a single item and reference it
from multiple ExternalSecrets.

## Template for Updated ExternalSecret

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: example
spec:
  refreshInterval: 3h
  secretStoreRef:
    name: bitwarden-login  # or bitwarden-field, bitwarden-note, bitwarden-ssh-key
    kind: ClusterSecretStore
  data:
    - secretKey: SOME_SECRET_KEY
      remoteRef:
        key: "<vaultwarden-item-id>"  # from Vaultwarden URL
        property: password  # e.g. username, password, or custom field name
```

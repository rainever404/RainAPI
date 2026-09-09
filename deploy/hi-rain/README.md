# RainAPI hi-rain deployment

This directory is the reproducible, non-secret definition for the customized
RainAPI deployment hosted by 1Panel on `hi-rain`.

## Preserved production state

Production continues to use the existing PostgreSQL `new-api` database and the
existing `./data` and `./logs` mounts. Replacing the application image must not
create a new database, volume, or container name. Users, API keys, channels,
balances, usage logs, monthly archives, and upstream credentials therefore stay
in their current managed storage.

## Repository-managed customization

- The public site name is `RainAPI`.
- User statistics exclude `poppy`, `mgfly`, and `anshuo` before totals,
  rankings, trends, legends, and Top-N selection are calculated.
- User statistics provide a multi-select user filter. The default includes all
  visible users; deselected users are omitted from every chart and total, and
  an empty selection shows no user data.
- User statistics support an inclusive custom date range in addition to the
  rolling presets. Custom dates run from the start of the first local day to
  the end of the last local day.
- Dashboard time granularity defaults to daily.
- Codex channel 1 accepts OpenAI-compatible `/v1/chat/completions` requests by
  converting them to Responses upstream. Codex is always called as a stream;
  non-streaming clients receive a buffered standard Chat Completions JSON
  response.
- Group ratios, model ratios, image ratios, user group assignments, and
  non-sensitive channel routing fields are reconciled by
  `apply-production-settings.sql`.

The SQL intentionally does not contain or modify passwords, API keys, upstream
URLs, quotas, balances, or usage logs. Those remain production data.

## Release contract

1. Build and test the image on Windows Docker Desktop.
2. Tag the image immutably and record its SHA-256 digest.
3. Transfer the image to `hi-rain` and load it with `docker load`; never build
   on the server.
4. Keep the 1Panel Compose project name, container name, database, ports, and
   mounts unchanged; replace only `RAINAPI_IMAGE`/the image reference.
5. Apply `apply-production-settings.sql`, then recreate with
   `docker compose up -d --no-build`.
6. Verify container health, `/api/status`, the public HTTPS endpoint, login,
   user statistics filtering, and database row counts.

Copy `.env.example` to an untracked `.env` only in the deployment environment.
Never commit the real `SQL_DSN` or channel credentials.

From the repository root, the standard local image build is:

```powershell
chcp 65001 > $null
& '.\deploy\hi-rain\build-image.ps1'
```

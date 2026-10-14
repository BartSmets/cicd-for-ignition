# Troubleshooting

Quick fixes for the things that bite people in Lab 02. Windows users: read
[`wsl-setup.md`](./wsl-setup.md) first, it prevents most permission problems.

## `scripts/setup.sh` fails: port 8088 is already in use

Something else on your machine (another gateway, another lab's stack) already
listens on 8088. Either stop it (`docker compose down` in that lab's folder), or
give this lab's gateway another host port in `.env`:

```bash
GATEWAY_PORT=8188
```

Re-run `scripts/setup.sh`. The gateway is then at `http://localhost:8188`, and
`scripts/setup.sh` and `scripts/scan.sh` follow the same variable. Replace `8088`
with your port in every URL the lab shows you. If you use the Flint extension,
also set `"port"` in `flint.config.json` (Flint does not read `.env`).
`scripts/scan.sh` still honours `IGNITION_URL` if you set it, which wins over
`GATEWAY_PORT`.

## `Conflict. The container name "/lab02-ignition" is already in use`

A container with the same name is left over, usually from the retired
per-lab `cicd-lab-02-*` repo or from an older clone of this lab. Remove it, then
re-run setup:

```bash
docker rm -f lab02-ignition
scripts/setup.sh
```

## The gateway never reaches RUNNING

- Give it time: a cold start takes one to three minutes. `setup.sh` polls for about four.
- Read the logs: `docker logs --tail 200 lab02-ignition`.
- Permission errors on Windows: the clone must live in your Linux home (`~/...`), never under `/mnt/c`. See [`wsl-setup.md`](./wsl-setup.md).
- Still stuck: `scripts/teardown.sh --volumes` and `scripts/setup.sh` give you a fresh gateway (your project files are in the repo, not in the volume).

## My silo-detail page disappeared

The gateway serves whatever branch is checked out: `projects/` is bind-mounted,
so `git switch fix/null-reading` (which branches off `main`, before the feature)
removes the silo-detail view from disk and from the gateway after the next scan
or restart. Switch back to `feature/v2-silo-detail` and it returns.

## `scripts/scan.sh` fails with HTTP 401 or 403

The API key is wrong or lacks permission. Check the one-time setup in
`.env.example`: the key's security level must be in **Gateway Write
Permissions**, the value in `.env` is the full `<name>:<secret>`, and
"Require secure connections for API Keys" is off. Or skip the key and run
`docker compose restart`.

## Flint reports "Endpoint not found (404)" when it scans

Flint calls the gateway's scan API and then `POST /data/project-scan-endpoint/scan`,
the endpoint of the **Project Scan Endpoint** module. A 404 means that module is not
running. The gateway installs it at boot from `third-party-modules/`, so check
*Platform → Modules* (it should say Running) or
`docker logs lab02-ignition 2>&1 | grep "project-scan-endpoint"`. A gateway you
created before the module was added gets it after `docker compose up -d`, which
recreates the container with the new settings. A 401 from Flint means it has no
valid key: put `ignition_token=<name>:<secret>` (the same key as in `.env`) in
`.flint/tokens/local-api.json`.

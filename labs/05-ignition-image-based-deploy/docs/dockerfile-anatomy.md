# Dockerfile anatomy: cheat sheet

Reference reading for part 1 of the lab. What the gateway image is made of, where each piece lands, and how to keep builds fast and traceable.

## What goes in the image

The [`Dockerfile`](../Dockerfile) puts the *deployable state* of a gateway into an image, on top of the official Ignition base image:

| Build input | Lands at | Why it's in the image |
|---|---|---|
| `third-party-modules/*.modl` | `/third-party-modules/` | The gateway loads them via `-Dignition.gateway.externalModulesFolder`. Putting them in the image = the module binaries ship with the artifact. |
| `services/modules.json` | `data/modules.json` | Which modules turn on at boot. The gateway reads it when it starts, and every image deploy starts a fresh gateway. The local gateway reads the same file through its bind mount, so local, test and production start the same modules. |
| `services/config/` | `data/config/` | Gateway-level config (DB connections, tag providers). Scanned at startup. The scan-API token is not in the image: a published image must never carry credentials, so deploys reinstall it into the container (`scripts/install-api-token.sh`). A `RUN sed` right after this `COPY` re-arms the OPC UA module's one-time flag, so each gateway creates its own `opcua-module` login (the user source every OPC tag reads through) at first boot. |
| `projects/` | `data/projects/` | Project content (Perspective views, scripts, tags). Scanned at startup. |

Everything else in the repo (docs, scripts, `.github/`, `.env`) is kept out by [`.dockerignore`](../.dockerignore). So is anything that belongs to **one** gateway rather than the artifact: the internal identity (`user-source/default/` holds an admin password hash; putting it in the image would ship one gateway's login to every gateway running the image), per-instance keystores/UUIDs (`config/local/`, `config/resources/local/`), and `security-properties` (it names the internal user source, which isn't in the image; commissioning creates a fresh `default` identity from the container's `GATEWAY_ADMIN_*` env vars instead).

## The base image

```dockerfile
ARG IGNITION_VERSION=8.3.8
FROM inductiveautomation/ignition:${IGNITION_VERSION}
```

- **Pin it.** Never a floating `:latest`: two builds a week apart could differ in ways you didn't choose. Bump the pin deliberately and let CI rebuild.
- The base image already defines the entrypoint (the gateway launcher), `EXPOSE 8088`, and a healthcheck. We inherit all of it.
- Runtime knobs (admin password, EULA acceptance, module license/cert acceptance, `GATEWAY_RESTORE_DISABLED`) stay as **environment variables** in `docker-compose.yaml`, and the deployment mode is a gateway argument there. Config that varies per environment stays out of the shared image.

## Layer order is a cache strategy

Each `COPY` is its own layer. Docker caches a layer keyed on the *content* of its inputs (not timestamps) and reuses it on rebuild if nothing changed. So order from **least- to most-frequently-changed**:

```dockerfile
COPY --chown=2003:0 third-party-modules/  ...   # big, rarely changes  → first (rebuilt least often)
RUN sha256sum /third-party-modules/*.modl ...  # 5 s stand-in for a module scan
COPY --chown=2003:0 services/modules.json ...
COPY --chown=2003:0 services/config/      ...
RUN sed -i ... one-time/config.json            # OPC UA module recreates its login
COPY --chown=2003:0 projects/             ...   # changes daily        → last (rebuilt most often)
```

Editing a Perspective view busts only the last layer. If you put `projects/` first, every view tweak would also re-copy the modules and pay the 5-second module check again.

> A changed layer rebuilds **all layers after it**, so what changes most goes last.

`--chown=2003:0` makes the copied files belong to the image's own `ignition` user. The gateway does not run as root; root-owned files make it FAULT at boot.

## Tagging strategy

One image, several names:

| Tag | Kind | Set by | Use |
|---|---|---|---|
| `:sha-<short>` | **Immutable** | build | The thing you actually deploy. A SHA tag always points at one specific build. |
| `:sha-<short>-dirty` | Local only | `build-image.sh` | Built with uncommitted changes: the image matches no commit. Commit (or undo) and rebuild before you deploy it. |
| `:test` | Moving | build | "Whatever's latest on test." Never deploy *by this name*: it moves under you. |
| `:vX.Y.Z` | **Immutable** | promote | A released version. Re-tag of the tested `:test` image (checked to be the tagged commit's build), no rebuild. |
| `:production` | Moving | promote | "Whatever's live in production." Same caveat as `:test`. |

Rule of thumb: **deploy immutable tags, navigate with moving tags.** That's why `lab05-deploy.yml`'s run summary hands you the `:sha-<short>` name to deploy, not `:test`. (Neither workflow deploys anything itself; you recreate the gateway by hand.)

## Provenance labels

```dockerfile
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="..."
```

`build-image.sh` and CI pass `--build-arg GIT_SHA=$(git rev-parse --short HEAD)`. Read it back from any image or running container:

```bash
docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.revision" }}' <image>
```

That's how you answer "what commit is production actually running?" months later.

## Startup behaviour

On first boot the container has the `data/projects` and `data/config` but no internal gateway database yet, so the IA entrypoint **commissions** the gateway: it applies the admin credentials from the env vars and scans the content in the image. With `GATEWAY_RESTORE_DISABLED=true` it won't try to restore a backup. A fresh container comes up already serving your project: no manual scan, no `docker cp`.

Test and production have **no persistent data volume** (see `docker-compose.yaml`), so every deploy re-commissions from the image. The container is disposable; durable data lives in TimescaleDB.

## Build context and `.dockerignore`

The **build context** is what Docker hands the builder before running the Dockerfile: the lab folder minus what `.dockerignore` lists. The image only gets what the `COPY` lines select from it.

- **Secrets:** `.env` is excluded, so credentials can't end up in a published image, even if a future `COPY` is careless.
- **Lab material:** `.git/`, `docs/`, `exercises/`, `scripts/` never reach the build.
- **One gateway's state:** the internal identity, keystores, `.resources/` blob stores and `*.idb` databases stay out.
- **Everything in a copied folder ships:** `COPY projects/` copies everything in `projects/`, unless `.dockerignore` excludes it.

`scripts/validate.sh` and `lab05-ci.yml` both assert the must-exclude patterns (`.env`, `.git/`, `scripts/`, `docs/`, `exercises/`) are present.

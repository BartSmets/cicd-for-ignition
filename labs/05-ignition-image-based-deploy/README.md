# Lab 05: Ignition image-based deploy

Day 3 of the [CI/CD for Ignition Masterclass](../../README.md).

> Build an Ignition gateway's project, config **and modules** into a versioned Docker image, deploy it by recreating the container from that image, and roll back by running the previous build's tag. You build and deploy on your own machine; the CI workflows build the same image on GitHub, publish it to your fork's registry and promote the tested image to production on a tag, without a rebuild.

This is the companion to [Lab 04 (file-based deploy)](../04-ignition-file-based-deploy/). There you copied files into a *running* gateway and triggered a hot scan. Here the same files become layers in an image, and a deploy replaces the whole container. Both achieve the same result: file-based keeps the gateway alive (no restarts, a fast inner loop) but you own the copy-and-delete logic; image-based gives you a frozen, versioned artifact with no copy scripts, but every deploy boots a fresh gateway.

> **How resource.json stays clean:** Ignition restamps these manifests constantly. [`docs/resource-json-hygiene.html`](https://share.mustrysolutions.com/37202f9a-4e70-4f81-bce4-79519f520bda) ([offline copy](./docs/resource-json-hygiene.html)) explains what the junk is, the two tools that deal with it, and why an empty `git diff` does not mean a clean file.

## What changes from Lab 04

| | Lab 04 (file-based) | Lab 05 (image-based) |
|---|---|---|
| Unit of deploy | Files on disk | A versioned image |
| Mechanism | `docker cp` + hot scan | Recreate the container from a new image |
| Modules | Ship `modules.json`, then restart the gateway | Built into the image |
| Rollback | Re-run the pipeline on an older tag | Run the previous tag |
| Promotion | Copy the same commit to each environment | Re-tag the tested image |
| Gateway | Long-lived: runtime state stays | Disposable: a fresh gateway on every deploy |

The local → test → production story is the same; only the test/production **delivery mechanism** changes.

## Slides

The decks open in your browser; click **Open document** on the first page.

| Deck | Online | Offline copy |
|---|---|---|
| Teaching | [open in your browser](https://share.mustrysolutions.com/f9880a04-5773-4290-be87-06d14c3b5f54) | [`slides/teaching.html`](./slides/teaching.html) |
| Assignment | [open in your browser](https://share.mustrysolutions.com/d5b9f34a-e127-42f3-ad2e-bc955cd867ff) | [`slides/assignment.html`](./slides/assignment.html) |

The offline copy is the same deck: open it from your clone if the link doesn't load.

## Prerequisites

- **≥ 8 GB free RAM for Docker**: three Ignition gateways (1 GB heap each, capped at 1.5 GB), plus TimescaleDB and Docker overhead.
- **Your course clone**, with `gh` pointed at your fork (the course setup does this). You build and deploy on your machine, but your changes reach `main` the GitHub flow way: a PR into your fork, merged on GitHub, then `git pull`. Each merge also fires `lab05-deploy.yml`, which publishes the image to **your own** GHCR namespace (`ghcr.io/<your-fork-owner>/cicd-lab-05-ignition`), never to Mustry's; only the stretch challenge pulls it. No PAT needed.
- _Background:_ [Lab 04](../04-ignition-file-based-deploy/) sets up the Ignition stack and the file-based pattern this lab contrasts with. It helps but isn't required: this lab stands alone.

> **WSL2 (Windows):** keep the clone in your Linux home (`~/…`), never `/mnt/c/…`, and never use `sudo` for the labs. See [`docs/wsl-setup.md`](./docs/wsl-setup.md).

## Quick start

One lab stack at a time: all Docker labs share the same ports and container names, so stop the previous lab first (`docker compose down` in that lab's folder).

```bash
cd ~/mustry-academy/cicd-for-ignition/labs/05-ignition-image-based-deploy
scripts/setup.sh    # creates .env, brings up the stack, waits for all three gateways, prints credentials
```

Once setup finishes you have three Ignition gateways:

| Gateway | URL | What runs there |
|---|---|---|
| `local` | http://localhost:8088 | Bind-mounted from `./projects/` + `./services/config/`: your **authoring** gateway (file-based, like Lab 04). |
| `test` | http://localhost:8089 | The **image** you deploy to it. Base image (empty) until the first deploy. |
| `production` | http://localhost:8090 | The **image** you promote to it (stretch: `lab05-release.yml` re-tags the tested image on a `lab05-v*` tag). Base image (empty) until the first release. |

> **A bare `docker compose up -d` resets test/production to the empty base image** unless `IGNITION_TEST_IMAGE` / `IGNITION_PRODUCTION_IMAGE` are set. Redeploy with the one-liner, or put the image in `.env` to make it stick. `scripts/setup.sh` keeps whatever they run.

Login with the credentials from `.env` (`GATEWAY_ADMIN_USERNAME_LOCAL/_TEST/_PRODUCTION`, default `admin / password`).

> **Trial mode:** each gateway runs in 2-hour trial mode. Reset via *Platform → Licensing → Reset Trial*. Test and production are recreated from a fresh image on each deploy, so their trial clock resets every deploy too.

> **Stuck?** See [`docs/TROUBLESHOOTING.md`](./docs/TROUBLESHOOTING.md). Before opening a PR, run `scripts/validate.sh` (the CI checks; linters you haven't installed are skipped) and `scripts/build-image.sh` (confirms the image builds).

> **Ports taken?** Set `GATEWAY_PORT`, `TEST_GATEWAY_PORT`, `PRODUCTION_GATEWAY_PORT` or `POSTGRES_PORT` in `.env` (see `.env.example`) and re-run `scripts/setup.sh`.

## Lab structure

The lab is one exercise in two ordered parts, see [`exercises/lab.md`](./exercises/lab.md):

1. **Build the gateway image:** put projects, config and modules into a self-contained image.
2. **Deploy the image:** recreate the test gateway from it, ship a change end-to-end, roll back.

Reference reading sits alongside: [`docs/dockerfile-anatomy.md`](./docs/dockerfile-anatomy.md) (part 1) and [`docs/image-based-deploy-pattern.md`](./docs/image-based-deploy-pattern.md) (part 2).

## Repo layout

```
labs/05-ignition-image-based-deploy/
├── README.md
├── Dockerfile                          ← puts projects + config + modules into the gateway image
├── .dockerignore                       ← what NOT to send to the build context (the image-based .deployignore)
├── docker-compose.yaml                 ← three gateways + TimescaleDB
├── .env.example                        ← setup.sh copies it to .env
├── .gitattributes                      ← JSON line-ending normalization + binary markers
├── exercises/
│   └── lab.md                          ← the lab, in two ordered parts: build the image, then deploy it
├── db-init/                            ← timescaledb init: create ignition_test + ignition_production databases
├── docs/                               ← reference reading
│   ├── dockerfile-anatomy.md
│   ├── image-based-deploy-pattern.md
│   ├── resource-json-hygiene.html
│   ├── wsl-setup.md
│   └── TROUBLESHOOTING.md
├── scripts/
│   ├── setup.sh                        ← bootstraps the whole stack
│   ├── teardown.sh                     ← stop the stack (with --volumes to wipe)
│   ├── generate-api-keys.sh            ← per-gateway scan-API keys into .env (never committed, never in the image; run by setup.sh)
│   ├── install-api-token.sh            ← put a gateway's token into its container after a deploy (run by deploy-image.sh)
│   ├── build-image.sh                  ← local mirror of the CI build (build + tag)
│   ├── deploy-image.sh                 ← the deploy one-liner plus a wait + API-token reinstall (recreate a gateway from an image)
│   ├── trigger-scan.sh                 ← scan the LOCAL gateway (the file-based inner loop)
│   ├── validate.sh                     ← the CI checks (JSON, .dockerignore, compose; linters when installed)
│   ├── lib.sh                          ← shared helpers
│   ├── clean-ignition-resource-churn.sh ← undo volatile-only resource.json rewrites (dry-run / --apply)
│   ├── git-diff/                       ← textconv normalizer that hides volatile metadata in diffs
│   └── git-hooks/                      ← this lab's hooks, run by the repo-root dispatchers (skip-worktree, churn cleanup)
├── projects/                           ← project content (built into the image; bind-mounted into `local`)
│   └── example-project/                ← a real Perspective project (views, templates)
├── services/
│   ├── config/                         ← gateway-level config (built into the image)
│   └── modules.json                    ← module enablement for all three gateways (bind-mounted into `local`, built into the image)
└── third-party-modules/                ← bundled .modl binaries (built into the image)
```

The workflows live at the course repo root (GitHub only runs workflows from there): [`.github/workflows/lab05-*.yml`](../../.github/workflows/).

## The Compose stack

Three Ignition 8.3 gateways + one TimescaleDB, simulating local → test → production:

- **`ignition-local`** bind-mounts `./projects/`, `./services/config/` and `./services/modules.json`, exactly like Lab 04. This is where you **author** content. The image you ship is *built from these same files*.
- **`ignition-test`** runs whatever image `IGNITION_TEST_IMAGE` points at (default: the base Ignition image, an empty gateway). It has **no bind mounts and no persistent data volume**: the container filesystem *is* the artifact. You deploy by setting `IGNITION_TEST_IMAGE` to a built tag and running `docker compose up -d ignition-test`, which recreates the container. Which modules run is decided by the `modules.json` in the image, the same `services/modules.json` the local gateway reads, so all three gateways start the same modules. Before your first deploy, the plain base image has no `modules.json`; `docker-compose.yaml` then hands the gateway the list `services/modules.json` enables (`LAB_MODULES_ENABLED`, which `scripts/setup.sh` writes into `.env`), so even the empty gateway doesn't start every module Ignition ships.
- **`ignition-production`** is the same shape, fed by `IGNITION_PRODUCTION_IMAGE` with the *promoted* image (the same one the test gateway tested).

The single TimescaleDB hosts `ignition_local_development`/`ignition_test`/`ignition_production`. **Historian data lives in TimescaleDB, not in the gateway image**, so recreating the test/production container on every deploy keeps it.

`name: cicd-lab05` at the top of the compose file pins the project name, so the stack always resolves to *these* containers, whichever directory you run compose from.

## Branching model (GitHub flow)

This lab uses **GitHub flow**: one long-lived branch, releases cut by tagging, the same flow as every previous lab.

```
feature/*  ──PR→  main ──push→  lab05-deploy.yml ──build+push→ :test image ──→ TEST gateway
                   │
                   └─tag lab05-vX.Y.Z→  lab05-release.yml ──promote :test→ :vX.Y.Z+:production ──→ PRODUCTION gateway
```

| Branch | Role | What CI does |
|---|---|---|
| `main` | The only long-lived branch: every merge should be deployable | `lab05-deploy.yml` builds and pushes the image you deploy to the **test** gateway |
| `feature/*` | Day-to-day work, branched off `main` | `lab05-ci.yml` validates the PR into `main` |
| tag `lab05-vX.Y.Z` | A release: stamp the `main` state you want in production | `lab05-release.yml` promotes the tested image for **production** |

**Releasing is promotion, not a rebuild.** `lab05-release.yml` promotes **the image test already tested** (the `:test` tag), re-tagging it to `:vX.Y.Z` + `:production`. The image keeps the bare semver; the `lab05-` prefix only namespaces the git tag in the shared course repo. Production runs the exact digest test validated. Tag when test is where you want production to be.

## The CI/CD workflows

Three workflows under [`.github/workflows/`](../../.github/workflows/) at the repo root, each scoped to changes under `labs/05-ignition-image-based-deploy/`:

| File | Trigger | Runner | Purpose |
|---|---|---|---|
| [`lab05-ci.yml`](../../.github/workflows/lab05-ci.yml) | PR to `main` | `ubuntu-latest` | Validate JSON + `.dockerignore`, lint the Dockerfile (hadolint) and workflows (actionlint), and **build the image** (no push) so a broken Dockerfile fails the PR. |
| [`lab05-deploy.yml`](../../.github/workflows/lab05-deploy.yml) | Push to `main` (build paths), manual | `ubuntu-latest` | Build + push the image to GHCR (`:sha-<short>`, `:test`) and print the tag in the run summary. |
| [`lab05-release.yml`](../../.github/workflows/lab05-release.yml) | Tag `lab05-v*` (on `main`), manual | `ubuntu-latest` | Check that the **`:test`** image was built from the tagged commit, re-tag it to `:vX.Y.Z` + `:production` (**no rebuild**) and print the tag. |

> The deploy and release jobs carry `if: github.repository != 'Mustry-Academy/cicd-for-ignition'`. They push to the fork owner's GHCR, so they only run in your fork and skip on the course repo itself. CI (`lab05-ci.yml`) runs in both.

**Every workflow runs on a free GitHub-hosted runner**: this lab has no self-hosted runner. CI builds and promotes images, but it does not deploy one, because deploying means touching the machine that runs the gateway container. In this lab **you deploy by hand**: take the image name the workflow printed, put it in `IGNITION_TEST_IMAGE`, and run `docker compose up -d ignition-test` yourself. Labs 06 and 07 add the runner that does this last mile.

### GHCR auth

- The build/promote jobs push to **your own fork's** namespace: the workflows derive `ghcr.io/<owner>/cicd-lab-05-ignition` from `github.repository_owner`. No image ever pushes to a registry you don't own.
- Auth is the workflow's built-in `GITHUB_TOKEN` (the workflows request `packages: write`). No registry password in `.env`, no extra account.
- The first push creates a GHCR package under your namespace, linked to your fork. From a public fork it is normally public and pulls need no login. If a pull says `denied` (a private fork, or an older private package with the same name), log Docker in once with a token that has `read:packages`, or flip the package to public in its settings:
  ```bash
  gh auth refresh -h github.com -s read:packages      # adds the scope (opens your browser once)
  gh auth token | docker login ghcr.io -u <your-user> --password-stdin
  ```
- `denied: permission_denied: write_package` on the first push means an older package with the same name (e.g. from the retired per-lab repo) isn't linked to this repo: see [`docs/TROUBLESHOOTING.md`](./docs/TROUBLESHOOTING.md).
- If your fork lives under a GitHub **organization**, the org may restrict this: *Settings → Actions → General → Workflow permissions* must allow **read and write**, and Packages must be enabled. See [`docs/TROUBLESHOOTING.md`](./docs/TROUBLESHOOTING.md).
- **No GHCR needed for the lab exercises:** the local `build-image.sh` flow runs entirely on your machine. Only the stretch pulls from GHCR.

No GitHub **environments** are needed here, since nothing deploys from CI.

Part 2 of [`exercises/lab.md`](./exercises/lab.md) walks through the deploy flow by hand.

## Licence

Apache 2.0, see [`LICENSE`](./LICENSE).

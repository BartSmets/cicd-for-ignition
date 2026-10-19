# Image-based deploy pattern: cheat sheet

Reference reading for part 2 of the lab. The pattern in five steps, build-once/promote-many, GHCR auth, rollback, and how image-based compares with file-based.

## The pattern in five steps

```
┌──────────┐    ┌────────┐    ┌─────────┐    ┌────────┐    ┌─────────────┐
│ 1. Build │ →  │ 2. Tag │ →  │ 3. Push │ →  │ 4. Pull│ →  │ 5. Run      │
│  image   │    │ :sha + │    │ to GHCR │    │ on the │    │ (recreate   │
│ from     │    │ moving │    │         │    │ target │    │  container) │
│ Dockerfile│   │ tag    │    │         │    │        │    │             │
└──────────┘    └────────┘    └─────────┘    └────────┘    └─────────────┘
```

1. **Build** the image from the `Dockerfile`, putting projects/config/modules into layers.
2. **Tag** it `:sha-<short>` (immutable) and a moving pointer (`:test` or `:production`).
3. **Push** to the registry (GHCR).
4. **Pull** the image on the machine that runs the target gateway.
5. **Run:** `docker compose up -d ignition-<env>` recreates the container from the new image.

Then verify health. No file copy, no scan API: the image already contains the state; you replace the whole container.

In this lab you do steps 1, 2 and 5 on your laptop, and your local image store plays the registry. On GitHub, `lab05-deploy.yml` does steps 1 to 3 on every merge to `main`; the stretch has you pull that image and run it (steps 4 and 5). A self-hosted runner next to the gateway does steps 4 and 5 in Labs 06 and 07.

## Build-once, promote-many

```
push to main ──▶ build ──▶ :sha-abc1234 + :test ──▶ deploy to test  (test it here)
                                       │
tag lab05-v0.1.0 (on main) ─▶ promote ─┘ re-tag :test ──▶ :v0.1.0 + :production ──▶ deploy to production
                        (no rebuild, same digest)
```

`lab05-release.yml` does **not** rebuild on a tag. It runs `docker buildx imagetools create` to copy the manifest of the already-tested **`:test`** image onto new tags (`:v0.1.0`, `:production`; the git tag's `lab05-` prefix is stripped). Server-side, no layers moved. A rebuild from the tagged commit could pull a newer base layer and ship bytes test never ran. Because `:test` moves with every merge, the release first reads its `org.opencontainers.image.revision` label and fails unless that build has the tagged commit's image inputs, so a tag pushed too early or on the wrong commit never promotes a different image. Prove the promotion:

```bash
docker inspect -f '{{.Image}}' lab05-ignition-test
docker inspect -f '{{.Image}}' lab05-ignition-production
# identical sha256 image IDs: production runs the bytes the test gateway tested
```

## Where each step runs

| Step | Where it runs |
|---|---|
| build, tag, push | `ubuntu-latest` (GitHub-hosted, free): it only needs Docker and registry credentials |
| pull, recreate | A machine that can reach the gateway's Docker daemon: **in this lab, your laptop, by hand** |

The build no longer has to run next to the gateway; only the last mile does. That's why this lab needs no runner at all: with the build on GitHub, what's left is two commands you run yourself.

## GHCR auth

- **Push** (build/promote jobs): the workflow requests `permissions: packages: write` and logs in with the built-in `GITHUB_TOKEN`. No PAT, no stored registry password.
- **Pull** (a deploy job, once you have one): log in with the same `GITHUB_TOKEN`. Pulling needs only `packages: read`, which `write` includes.
- **First push** creates the package in your fork's namespace, linked to the fork. From a public fork it is normally public; if it is private (a private fork, or an older package with the same name), pulling it by hand needs a one-off login with a token that has `read:packages` (`gh auth refresh -h github.com -s read:packages`, then `gh auth token | docker login ghcr.io -u <your-user> --password-stdin`); flip the package public if you'd rather pull anonymously.
- **Don't** hand a deploy runner a broad PAT. The job-scoped `GITHUB_TOKEN` is enough and expires with the run.

## File-based vs image-based

Both deliver the same files to the same paths and achieve the same result. Once the pipeline runs you barely notice which one you are on; you notice the failure modes.

| | File-based (Lab 04) | Image-based (Lab 05) |
|---|---|---|
| Deploy | Copy files into the running gateway, then scan | Recreate the container from a new image |
| Time to deploy | Seconds (copy + scan) | Minutes (the gateway boots) |
| Gateway restart | None for project and config changes | Every deploy is a fresh gateway |
| Module changes | Ship `modules.json`, then restart the gateway | Built into the image |
| Rollback | Re-run the pipeline on an older tag | Run the previous tag |
| Promotion | Copy the same commit to each environment | Re-tag the tested image |
| What you maintain | Copy, wipe and spare lists, `.deployignore` | The Dockerfile and `.dockerignore` |
| Runtime state (memory tag values, trial clock) | Stays in place | Lost unless it lives outside the container |
| Typical failure | Stale files when a delete is missed | Lost runtime state, boot downtime |

This lab keeps `local` file-based (authoring) and makes test/production image-based, so you live in both worlds at once.

## Rollback

1. **`git revert` + re-merge.** Triggers a fresh build of the reverted state. Works, but rebuilds.
2. **Run a previous tag.** Every build is an immutable tag; point the gateway at the old one and recreate the container. That's Part 2.3 of the lab.
3. **Re-promote a released version.** `lab05-release.yml`'s `workflow_dispatch` takes a `tag` input: it re-tags that version's *existing* image to `:production`, without a rebuild. You then recreate production from it.

Retention of old tags becomes the real question: a rollback works for every version you haven't deleted.

## What lives where

Image-based deploy recreates the container on every deploy, so be clear about what dies with it:

| In the image (dies on each deploy, comes back from the image) | Outside the image (persists) |
|---|---|
| Project content, config, module manifest + binaries | Historian data → TimescaleDB |
| The gateway's commissioned internal DB (re-created each boot) | Anything you deliberately put on an external volume or DB |

In this lab, test/production have **no persistent data volume**: the durable data (historian) is in TimescaleDB. In a real deployment you decide what (if anything) needs a volume: gateway audit logs, alarm journal, named user accounts. Each is a "does this belong in the image, a volume, or a database?" decision.

## When image-based is a poor fit

- **Sub-minute iteration on project content.** Rebuilding and rebooting for every view tweak is slow: use the file-based inner loop (`local` gateway) and build an image when you're ready to release.
- **Stateful gateway data you can't externalize.** If critical state lives in the gateway's local DB and can't move to a volume or DB, recreating the container loses it.
- **No registry reachable from the target.** Image-based assumes the gateway host can pull. Air-gapped sites need `docker save`/`load` or a local registry mirror.

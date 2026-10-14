# CI/CD for Ignition

> Hands-on training in version control, GitHub Actions, and multi-gateway deployments for Ignition 8.3, by [Mustry Academy](https://mustrysolutions.com/).

This is the course repo. Everything you work on during the four days lives here: the preflight check, every lab, its exercises, slides and docs. You fork it once, clone your fork once, and work lab by lab in its own folder.

**Who this is for:** senior Ignition integrators, and the IT/engineering colleagues who work with them, who want to ship Ignition the way real software is shipped: Git, pull requests, CI pipelines and reproducible deployments.

**Prerequisite:** current Inductive University 8.3 Credential, or equivalent professional experience.

## Before Day 1 (at least two days ahead)

The welcome package you received as a PDF covers the same steps with more background. It is also [online](https://share.mustrysolutions.com/040ca767-f8fc-43bb-9949-e0f8402a43f7): click **Open document** to read it in your browser.

Work in **WSL2 (Windows), Linux or macOS**. On Windows, keep the clone in your Linux home (`~/…`), never on `/mnt/c/…`: the Docker labs break there.

Have these ready before you start:

- The [GitHub CLI](https://cli.github.com/), logged in with the `workflow` scope: `gh auth login -s workflow`.
- A GitHub **classic Personal Access Token with the `repo` scope** ([github.com/settings/tokens](https://github.com/settings/tokens) → *Generate new token (classic)*). The course setup asks for it once; the self-hosted runners of Labs 04 and 06 use it to register on your fork.

1. **Fork and clone** the course repo:
   ```bash
   mkdir -p ~/mustry-academy && cd ~/mustry-academy
   gh repo fork Mustry-Academy/cicd-for-ignition --clone
   cd cicd-for-ignition
   ```
2. **Run the course setup:**
   ```bash
   ./course-setup.sh
   ```
   It runs the [preflight](./preflight/) checks (tools, Docker, course images), sets up this clone's git hooks, checks that `origin` is your fork, sets `gh`'s default repo to your fork, switches on Actions for it (forks start with workflows off), and prepares the `.env` files for Labs 04 and 06 (it asks once for the GitHub token their runner needs). Safe to re-run until everything is green.
3. **Paste `preflight/preflight-report.txt`** in the Discord `#preflight-help` channel so the TA can confirm you're ready.

## Labs

| Lab | Folder | Day | Slides |
|---|---|---|---|
| 01 | [Git fundamentals](./labs/01-git-fundamentals/) | 1 | [introduction](https://share.mustrysolutions.com/eb94880a-c904-4cca-95c0-8b8dbbae345a) · [story](https://share.mustrysolutions.com/f50d9d30-81b9-48ae-819d-1614674534f0) · [teaching](https://share.mustrysolutions.com/0a731a79-f381-402b-9b77-16415e2ff052) · [assignment](https://share.mustrysolutions.com/23db8ac9-058f-4276-93b9-cad40372b526) |
| 02 | [Branching and pull requests](./labs/02-branching-and-prs/) | 1 | [teaching](https://share.mustrysolutions.com/2ae84a78-da5f-42d6-8eeb-3b6415b63823) · [assignment](https://share.mustrysolutions.com/7a639346-4dc6-47d3-850b-fead0c4cb3ec) |
| 03 | [GitHub Actions](./labs/03-github-actions/) | 2 | [teaching](https://share.mustrysolutions.com/79b83f03-daca-4e27-bcc5-e1c8fbba2b3b) · [assignment](https://share.mustrysolutions.com/9cbacc0c-958d-4b10-88cd-af223211166e) |
| 04 | [Ignition file-based deploy](./labs/04-ignition-file-based-deploy/) | 2 (afternoon) | [teaching](https://share.mustrysolutions.com/741fe096-df6c-46f9-928e-9eeb16380ae2) · [assignment](https://share.mustrysolutions.com/ab83937e-517b-43a8-a7b1-cf7b53a6ee34) |
| 05 | [Ignition image-based deploy](./labs/05-ignition-image-based-deploy/) | 3 | [teaching](https://share.mustrysolutions.com/f9880a04-5773-4290-be87-06d14c3b5f54) · [assignment](https://share.mustrysolutions.com/d5b9f34a-e127-42f3-ad2e-bc955cd867ff) |
| 06 | [Secrets, database migrations, modules & JARs](./labs/06-secrets-db-and-modules/) | 4 (morning) | [teaching](https://share.mustrysolutions.com/9d789532-1459-4e18-b819-686fcc62a164) · [assignment](https://share.mustrysolutions.com/014ffcf0-71b9-4e7a-81ef-64d13ea0dbc4) |
| 07 | [Deployments in a multi-gateway architecture](./labs/07-multi-gateway-deploy/) | 4 (afternoon) | [teaching](https://share.mustrysolutions.com/8e1ea98f-1dc8-4972-8d59-65afb8afb879) · [assignment](https://share.mustrysolutions.com/a95c879a-d14b-4f76-8214-8f39784f09b1) |

Each day runs **09:00-18:00 Belgian time (CET/CEST)**. Start every lab from its README.

The slides open in your browser: click **Open document** on the first page. Every lab folder also keeps the same decks under `slides/` as an offline copy; open those from your clone if a link doesn't load.

**Lab 07 is the exception.** You don't work in your fork: the whole group contributes to the public [`Mustry-Solutions/demo-oatmakers`](https://github.com/Mustry-Solutions/demo-oatmakers) repo, which deploys to Mustry's live demo gateway. Your instructor adds you as a collaborator on Day 4; clone it next to this repo in `~/mustry-academy/`. The lab folder here holds the slides, the exercise and the docs; the code lives in demo-oatmakers.

## Working in this repo

- **Open the lab folder, not the repo root,** in VS Code (`cd labs/04-… && code .`). The Flint extension and the lab scripts expect the lab folder as the workspace.
- **One lab stack at a time.** The Docker labs share the same ports (8088–8090, 5432) and container names. Before you start a lab, stop the previous one: `docker compose down` in that lab's folder.
- **Port taken by something else on your machine?** Move it in that lab's `.env`: `GATEWAY_PORT` (local gateway, default 8088), `TEST_GATEWAY_PORT`, `PRODUCTION_GATEWAY_PORT` and `POSTGRES_PORT` (default 5432). See [preflight/troubleshooting.md](./preflight/troubleshooting.md#ports-already-in-use).
- **Workflows live at the root.** GitHub only runs workflows from `.github/workflows/` at the top of the repo, so each lab's workflows sit there as `labNN-*.yml`, filtered to their own folder. A change in Lab 04 never triggers Lab 06's pipeline.
- **Tags carry the lab number.** Release tags are `labNN-vX.Y.Z` (e.g. `lab04-v1.0.0`), so a tag releases only its own lab.

## Repo layout

```
cicd-for-ignition/
├── README.md              ← you are here
├── course-setup.sh        ← run once before Day 1
├── preflight/             ← environment checks (course-setup.sh runs these)
├── labs/                  ← one folder per lab: README, exercises, slides, docs, code
├── .github/workflows/     ← every lab's pipelines, prefixed labNN-
├── scripts/               ← shared git hooks and helpers
└── welcome-package/       ← source of the welcome PDF you received
```

## Licence

Code: [Apache 2.0](./labs/01-git-fundamentals/LICENSE), see each lab's `LICENSE`. © 2026 Mustry Solutions BV.

## Contact

- Lead instructor: Jasper Louage (jasper@mustrysolutions.com)
- General enquiries: info@mustrysolutions.com
- Discord: cohort link in your welcome email

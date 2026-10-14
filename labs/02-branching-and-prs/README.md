# Lab 02: Branching and Pull Requests

Day 1 of the [CI/CD for Ignition Masterclass](../../README.md).

> Run a release week in GitHub Flow, and learn to write a pull request a reviewer actually enjoys reading.

This is the second lab in the course. The subject of the exercises is a real (if
small) **Ignition project**: a Perspective HMI screen (the Oatmakers Site 04
oat-line overview, the client from Lab 01) and a couple of Python script libraries, running on a local gateway you
spin up yourself. You don't need prior Ignition experience: the gateway's
*administrative* complexity (config, modules, databases, deploys) is
**abstracted away**, and what you actually edit is approachable: a small Python
function, or a property on a view. The point of the lab is the **Git workflow**
around those project files: branching, pull requests, and review. The full Ignition
file-based deploy story arrives in [Lab 04](../04-ignition-file-based-deploy/).

## Slides

The decks open in your browser; click **Open document** on the first page.

| Deck | Online | Offline copy |
|---|---|---|
| Teaching | [open in your browser](https://share.mustrysolutions.com/2ae84a78-da5f-42d6-8eeb-3b6415b63823) | [`slides/teaching.html`](./slides/teaching.html) |
| Assignment | [open in your browser](https://share.mustrysolutions.com/7a639346-4dc6-47d3-850b-fead0c4cb3ec) | [`slides/assignment.html`](./slides/assignment.html) |

The offline copy is the same deck: open it from your clone if the link doesn't load.

## Prerequisites

- Work in **WSL2 (Windows), Linux, or macOS**: run all lab commands there, not in PowerShell or Git Bash (see the platform notes in your welcome package)
- Completed [Lab 01](../01-git-fundamentals/)
- Pass [`preflight`](../../preflight/)
- Docker (with the Compose V2 plugin) for the optional gateway: ~1.5 GB RAM is plenty for the single gateway

> **WSL2 (Windows): keep the clone in your Linux home (`~/…`), never `/mnt/c/…`.**
> `scripts/setup.sh` refuses to run from there. See [`docs/wsl-setup.md`](./docs/wsl-setup.md).

## Working model: PRs inside your fork

This lab has you open real PRs, review your peers', and merge your own when
approved. You work in your course fork (`origin`) and open every PR **inside it**.

1. Go to this lab's folder in your fork and check where `gh` opens PRs:
   ```bash
   cd ~/mustry-academy/cicd-for-ignition/labs/02-branching-and-prs
   gh repo set-default --view                                        # must print YOUR fork
   gh repo set-default <your-username>/cicd-for-ignition             # if not
   ```
2. Branch and push to **your** fork (`git push -u origin <branch>`).
3. Open PRs **inside your fork**: base repo = your fork, base branch = `main`,
   compare = your branch. GitHub's "Compare & pull request" banner defaults the base
   repo to the **upstream** course repo: switch it to your fork every time.
4. **Invite your reviewer**: add a peer or one of the tutors as a collaborator on
   your fork (Settings → Collaborators → Add people), then request their review on
   each PR.
5. You own your fork, so you can merge your own PRs once they're approved.

## Quick start

Spin up your gateway (optional, but it makes the project tangible). Only one lab
stack runs at a time: stop the previous lab's first (`docker compose down` in that
lab's folder).

```bash
cp .env.example .env
scripts/setup.sh        # boots one Ignition gateway, waits for RUNNING, prints the URL + login
# open http://localhost:8088  → log in with the .env credentials
```

Port 8088 already taken on your machine? Set `GATEWAY_PORT` in `.env` (see
`.env.example`); the setup script, the scan script and the printed URLs follow it.
Stuck? See [`docs/TROUBLESHOOTING.md`](./docs/TROUBLESHOOTING.md).

Before opening any PR, run the validator, the green/red signal this lab uses in
place of a test suite (gateway-free, runs in a second):

```bash
scripts/validate.sh     # every project file must be valid JSON / parse as Python
```

Stop the gateway when you're done:

```bash
scripts/teardown.sh             # stop (keeps the gateway's data volume)
scripts/teardown.sh --volumes   # stop and wipe gateway state for a fresh start
```

### Picking up your edits

A running gateway does **not** auto-detect changes to files under `projects/`. The
simplest way to load your edits is to restart the gateway, no API key needed:

```bash
docker compose restart      # reload the project from disk
```

Faster: set up a one-time Ignition API key (instructions in `.env.example`) and
trigger a project scan instead:

```bash
scripts/scan.sh                 # reload via the gateway's scan API
```

### Editing in VS Code with Flint

The Flint extension reads `flint.config.json` and can trigger the scan for you when
you save. On every scan it calls the gateway's own scan API and the endpoint of the
**Project Scan Endpoint** module (`POST /data/project-scan-endpoint/scan`), which
the gateway installs at boot from `third-party-modules/`. The module also tells an
open Designer to reload the project, so the Designer shows your VS Code edit.

Flint needs the same API key as `scripts/scan.sh`. Put it in
`.flint/tokens/local-api.json` (gitignored) as one line,
`ignition_token=<name>:<secret>` (the file's format is dotenv, despite the `.json`);
`.flint/tokens/local-api.json.example` shows it.

## Lab structure

The whole lab lives in one file, [`exercises/lab.md`](./exercises/lab.md): a single
**we-do / you-do** flow covering two linked topics:

- **GitHub Flow**: one `main`, short-lived branches, a tag per release
- **Pull requests**: scope, review, and merge hygiene

The you-do ties them together: you run the release-week scenario (a v2.0 feature plus
a P1 production fix) through **GitHub Flow**, with PRs your peers review, merged in
release order and tagged.

## Repo layout

```
labs/02-branching-and-prs/
├── README.md
├── docker-compose.yml            ← one Ignition gateway (named volume + bind-mounted projects/)
├── .env.example                  ← copy to .env before running
├── flint.config.json             ← Flint (VS Code) config: projects + local gateway
├── third-party-modules/          ← Project Scan Endpoint .modl the gateway installs at boot (for Flint)
├── exercises/
│   └── lab.md                    ← the lab (We-do, Parts 1-2)
├── docs/                         ← reference reading
│   ├── github-flow.md
│   ├── pr-review-style.md
│   ├── TROUBLESHOOTING.md        ← port in use, leftover container, scan errors
│   └── wsl-setup.md              ← Windows/WSL: read once before this lab
├── scripts/
│   ├── preflight.sh              ← WSL/permission checks setup.sh runs first
│   ├── setup.sh                  ← boot the gateway and wait for RUNNING
│   ├── scan.sh                   ← push project-file edits to the running gateway
│   ├── teardown.sh               ← stop the gateway (--volumes to wipe state)
│   └── validate.sh               ← the PR green/red check (valid JSON + parseable Python)
└── projects/                     ← the Ignition project (bind-mounted into the gateway)
    └── lab-project/
        ├── project.json
        ├── com.inductiveautomation.perspective/   ← the Perspective HMI dashboard + page config
        └── ignition/script-python/lab/            ← Python scripts (you edit display; util is a helper)
```

The PR template GitHub pre-fills on every PR lives at the repo root, in
[`.github/pull_request_template.md`](../../.github/pull_request_template.md): GitHub
only reads it from there. Open this lab folder in VS Code (`code .` from here), not
the repo root: `flint.config.json`'s paths are relative to the workspace folder.

## The Compose stack

A single Ignition 8.3 gateway. Two things to understand about how it's wired:

- **The gateway's own config and runtime state live in a named volume** (`ignition-data`) that the gateway generates itself on first boot. It never lands in the repo, so you never see or touch gateway config in this lab.
- **`./projects` is the one thing you edit that is bind-mounted** from the repo into the gateway. So the project files you edit on your laptop *are* the project files the gateway runs. (`./third-party-modules` is mounted too, read at boot: it holds the Project Scan Endpoint module that Flint calls, see [Editing in VS Code with Flint](#editing-in-vs-code-with-flint).)

```yaml
services:
  ignition:
    image: inductiveautomation/ignition:8.3.8
    ports: ["${GATEWAY_PORT:-8088}:8088"]                  # host port from .env, default 8088
    volumes:
      - ignition-data:/usr/local/bin/ignition/data        # gateway-owned, self-generated, not in git
      - ./projects:/usr/local/bin/ignition/data/projects   # the one thing you edit
      - ./third-party-modules:/third-party-modules         # add-on .modl files, installed at boot

volumes:
  ignition-data:
```

> The gateway regenerates a `.resources/` blob store and other operational files inside `projects/` as it runs. Those are gateway-owned churn and are gitignored: if you ever see them in `git status`, your ignore rules are off.

> **No CI in this lab.** `scripts/validate.sh` is something *you* run; Lab 03 turns it into a required status check no one can merge past.

## License

Apache 2.0, see [`LICENSE`](./LICENSE).

# Lab 01: Git Fundamentals

Day 1 of the *CI/CD for Ignition* masterclass.

> Build a working mental model of Git, and learn to operate confidently with branches, commits, merges, and rebases.

This is the first lab in the course. The subject of the Git exercises is a tiny Python app in [`sample-app/`](./sample-app/); Ignition projects arrive from Lab 02 on.

## Slides

The decks open in your browser; click **Open document** on the first page.

| Deck | Online | Offline copy |
|---|---|---|
| Introduction | [open in your browser](https://share.mustrysolutions.com/eb94880a-c904-4cca-95c0-8b8dbbae345a) | [`slides/introduction.html`](./slides/introduction.html) |
| The Oatmakers story | [open in your browser](https://share.mustrysolutions.com/f50d9d30-81b9-48ae-819d-1614674534f0) | [`slides/oatmakers-story.html`](./slides/oatmakers-story.html) |
| Teaching | [open in your browser](https://share.mustrysolutions.com/0a731a79-f381-402b-9b77-16415e2ff052) | [`slides/teaching.html`](./slides/teaching.html) |
| Assignment | [open in your browser](https://share.mustrysolutions.com/23db8ac9-058f-4276-93b9-cad40372b526) | [`slides/assignment.html`](./slides/assignment.html) |

The offline copy is the same deck: open it from your clone if the link doesn't load.

## Prerequisites

- Work in **WSL2 (Windows), Linux, or macOS**: run all lab commands there, not in PowerShell or Git Bash, and on Windows keep the clone in your Linux home, never under `/mnt/c/` (see the platform notes in your welcome package)
- Your fork of the course repo, cloned into `~/mustry-academy/` and set up with `./course-setup.sh` before Day 1 (steps 1 and 2 of the [course README](../../README.md)); this runs the [preflight](../../preflight/) too

## Quick start

```bash
cd ~/mustry-academy/cicd-for-ignition/labs/01-git-fundamentals    # every lab command runs from here
git remote -v                                                      # origin: YOUR fork
code .                                                             # open in VS Code (WSL: opens connected to WSL)
```

## Lab structure

One ~3-hour lab that interleaves Git's object model with everyday workflows. The full walk-through lives in [`exercises/lab.md`](./exercises/lab.md):

- **Introduction**: welcome to the series, your fork, how the labs work
- **The Oatmakers story**: a fictional client (eight Ignition sites, zero CI/CD) that the whole series follows
- **Teaching**: how Git stores your project (blobs, trees, commits, the staging area, branches, HEAD), merge, rebase, cherry-pick and conflicts, then remotes, tags, `git reset` and `.gitignore`
- **We-do**: the instructor live-codes `add`/`commit`, `switch`, merge (fast-forward vs `--no-ff`), rebase and wrong-branch recovery
- **You-do (breakout rooms)**: a guided warm-up, then two solo phases, plus optional stretch challenges
- **Wrap-up and questions**

## Repo layout

```
labs/01-git-fundamentals/
├── README.md
├── LICENSE
├── .gitignore                    ← what Git leaves alone (.venv, caches, NOTES.local.md)
├── exercises/
│   └── lab.md
├── docs/                         ← reference reading
│   ├── why-version-control.md
│   └── git-object-model.md
├── slides/                       ← the presented decks, in session order
│   ├── introduction.html
│   ├── oatmakers-story.html
│   ├── teaching.html
│   ├── assignment.html
│   ├── logos/
│   └── deck-assets/
├── scripts/
│   ├── seed-messy-state.sh       ← deterministic dirty working tree for the workflow phase
│   └── verify-lab.sh             ← sanity-check the solo focused-commit step
└── sample-app/                   ← the tiny Python app we'll version together
    ├── app.py
    ├── conftest.py               ← lets pytest import app.py from the lab folder or sample-app/
    ├── requirements.txt
    ├── tests/
    │   └── test_app.py
    └── README.md
```

## Licence

Apache 2.0: see [`LICENSE`](./LICENSE).

# Lab 07: Deployments in a multi-gateway architecture

**Day 4 · afternoon session.** For once, you do not work in your fork of the
course repo. Everyone works as a **contributor** on one real, public
repository: [`Mustry-Solutions/demo-oatmakers`](https://github.com/Mustry-Solutions/demo-oatmakers),
the repo behind Mustry's live Oatmakers demo at
<https://cloud.mustrysolutions.com>. Every merge to `main` lands on **your
own test gateway**, and every change to `release.yaml` deploys to **that
live production gateway** on the internet. You first stand up your test
gateway, then bring a project with your own name live, then land one of
five challenges on the shared oatmakers project, then build on each other's
work. Real reviews, real deploys, real merge conflicts.

The point of the afternoon: **use everything we learned and get some reps
in**: feature branch, commits, PR, review, tag, release pin, deploy, again
and again until the loop feels like muscle memory.

**Duration:** ~3 hours

* 60 min teaching ([`slides/teaching.html`](https://share.mustrysolutions.com/8e1ea98f-1dc8-4972-8d59-65afb8afb879), [offline copy](../slides/teaching.html))
* 30-45 min we-do (below, woven into the teaching)
* 60-75 min you-do ([`slides/assignment.html`](https://share.mustrysolutions.com/a95c879a-d14b-4f76-8214-8f39784f09b1) mirrors this file 1:1; [offline copy](../slides/assignment.html))
* Debrief: this is the last lab, so the debrief also closes the course

The full teaching content is written out in
[`docs/multi-gateway-deployments.md`](../docs/multi-gateway-deployments.md),
and the production gateway is described in
[`docs/capstone-gateway.md`](../docs/capstone-gateway.md).

## Goal

You should leave this lab able to:

- Work as a **contributor on a shared, protected repo**: no pushes to
  `main`, every change through a PR with a green `CI OK` check and one
  approval from someone else
- Explain the two deploy channels: a merge to `main` lands on **every
  student's test gateway**, while **only `release.yaml` decides what reaches
  production**, and why one is gated and the other is not
- Cut a **prefixed tag** (`<yourname>@v1.0.0`, the next free
  `oatmakers@vX.Y.Z`) and explain why the tag must exist, on a commit on
  `main`, **before** `release.yaml` may point at it
- Read `runs-on: [self-hosted, <yourname>-local]` and
  `runs-on: [self-hosted, demo-oatmakers]` and explain how a runner label
  routes a deploy to one machine's network
- Ship the lab 06 building blocks through a real pipeline: a **third-party
  module**, a **library JAR**, a **migration pair** and a **referenced
  secret**
- Share **one version stream** with the rest of the group: pull `main`
  often, take the next free tag number, keep PRs small, keep one release PR
  in flight, and solve the merge conflicts that happen anyway
- Say when you would split the infra part (release files, gateway config)
  into its own repo (the teaching's option B) and when one repo is enough

## What you're working with

**One public repo, the same one for every group, and you are a
contributor on it:**

```
git@github.com:Mustry-Solutions/demo-oatmakers.git
```

```
release.yaml                 what runs on production, right now (the ONLY production trigger)
projects/oatmakers/          the shared project (Part 2 lands here)
projects/<yourname>/         your own project (you create it in Part 1)
services/config/             gateway config export (devices, tags, connections, historians)
services/modules.json        module manifest (lab 06)
third-party-modules/         .modl files the pipeline installs (lab 06)
jar-files/jar/               library JARs, shipped to the gateway's JAR directory (lab 06)
db-migration/migrate/        golang-migrate up/down pairs (lab 06)
local-development/secrets/   local stand-ins for the referenced secrets
scripts/                     setup, teardown, validate, migrate, scan, reset-trial, ...
.github/workflows/           ci.yml (PR checks) · deploy.yml (release.yaml → production)
                             · test-example.yml.template (you copy it in Part 0)
```

**The rules of the repo:**

- **`main` is protected.** Nothing reaches it without a pull request, a
  green **`CI OK`** check and **one approval**. You cannot approve your own
  PR: the instructor or a fellow student approves it. The Mustry team can
  bypass these rules; you cannot, and you should not want to.
- **Two deploy channels, two triggers.** Every merge to `main` lands on
  **your own test gateway** automatically, through a workflow you add in
  Part 0 (and on everyone else's, through theirs). Only a change to
  `release.yaml` on `main` reaches the **production gateway**: workflow
  `Deploy`, on the runner labelled `[self-hosted, demo-oatmakers]`. Started
  by hand from any other branch, `Deploy` refuses to run.
- **The production deploy is wide.** It ships every pinned project from its
  own tag, plus the gateway payload (config, module manifest, third-party
  modules, JARs, migrations) from the `oatmakers` pin. Migrations run first.
  A module or JAR change restarts the gateway for a minute or two.
  Per-gateway identity, users and API keys are never shipped.
- **Production is real, public, and Mustry's live demo.** Customers see
  <https://cloud.mustrysolutions.com>. Mustry staff deploy it exactly the
  way you will today: a tag and a `release.yaml` PR. Be gentle with it.
- **You do not need the production admin login.** Everything you verify is
  a public Perspective page or a workflow log. If you need a gateway status
  page, ask: the instructor shares access in the chat when it is needed.

## The mental model, before you start

One repository, two jobs. The seam between them is a version string:

- **`projects/` and the gateway payload answer "what have we built?"**
  A git tag like `<yourname>@v1.0.0` marks a version of one project: a
  point in history you can deploy. Nothing gets compiled; the deploy ships
  the files as they were at that tag. A tag that was never pushed is a
  release that does not exist.
- **`release.yaml` answers "what runs on production, right now?"** One
  file, one production gateway (`oatmakers-site-7`). You change a version
  number by PR, a deploy happens. No workflow in the repo deploys any other
  way, and a pin may only point at a tag on a commit that is on `main`, so
  only reviewed code ships. (Write access to a repo with a self-hosted runner
  is still a lot of trust: a workflow file you push on a branch runs before
  anyone reviews it. Keep that in mind for the debrief.)

```yaml
# release.yaml
gateway: oatmakers-site-7
projects:
  oatmakers: v5.0.0       # ships projects/oatmakers + the gateway payload from oatmakers@v5.0.0
```

In the teaching you saw **option B**: split the infra part (release files,
gateway config) into its own repo, owned by another team. Both are valid.
One repo keeps this lab small.

## Rules for a shared live demo

Everyone in the group, and the Mustry team, ships through the same
`release.yaml` to the same gateway. These rules keep that civil:

1. **Small PRs.** One view, one migration pair, one module. Small PRs get
   reviewed first and conflict least.
2. **Stage only what you changed.** `git add <your paths>`, never
   `git commit -am`. The local gateway rewrites files on its own (module
   fingerprints, resource stamps); that churn never belongs in your PR.
3. **One release PR in flight at a time.** Before you open a PR that
   changes `release.yaml`, look at the open PRs. If another release PR is
   open, wait until it is merged and its `Deploy` run is green. Say in the
   chat when you start and when you are done.
4. **A conflict in `release.yaml` is normal: rebase and keep every pin.**
   Take every line `main` has, then put your change back on top:

   ```bash
   git fetch origin
   git rebase origin/main
   # fix release.yaml: keep every pin from main, re-apply only your own line
   git add release.yaml
   git rebase --continue
   git push --force-with-lease
   ```

5. **Never lower a pin.** If `release.yaml` already pins a higher
   `oatmakers@` version than the tag you cut, check whether your change is
   already inside it (Part 2 shows how) instead of pinning backwards.
6. **A pushed tag is permanent.** Never move or delete one. Made a mistake?
   Fix it on `main` and cut the next number.
7. **Announce restarts.** A release that adds a module or a JAR restarts the
   production gateway. Say so in the chat before you merge it.
8. **Leave the existing demo alone.** Add your screens, tags and tables
   under names that carry your name or `Course`; do not rework the demo's
   own screens. Rollback is `git revert` of the release PR, but nobody wants
   to need it.

## Before you start

- **Accept the invite.** The instructor adds you as a collaborator with
  write access at the start of the session. Accept it from your GitHub
  notifications or at
  <https://github.com/Mustry-Solutions/demo-oatmakers/invitations>. No fork.
- **Coming straight from lab 06? Shut its stack down first**
  (`docker compose down` in `labs/06-secrets-db-and-modules/` of your fork).
  It holds ports **8088, 8090 and 5432**, all three of which this lab needs.
- **Clone the repo next to the course repo** in `~/mustry-academy/`, not
  inside `cicd-for-ignition/`:

  ```bash
  cd ~/mustry-academy
  git clone git@github.com:Mustry-Solutions/demo-oatmakers.git
  cd demo-oatmakers
  ```

- **Windows:** keep the clone in your WSL home (`~/...`), never under
  `/mnt/c/...`. See [`docs/wsl-setup.md`](../docs/wsl-setup.md).

You start the stack in Part 0: it needs one value from the instructor that
is posted in the chat at the start of that part.

### Local development: where you actually build

Production is never your development machine. The repo brings its own local
stack, the same move as every previous lab:

| What | Where | Login |
|---|---|---|
| local gateway `oatmakers-gateway` | <http://localhost:8088> | `admin` / `password` |
| local database `oatmakers-postgres` | `localhost:5432` | see `local-development/secrets/` |
| your test gateway `oatmakers-test-gateway` (Part 0) | <http://localhost:8090> | fed by your workflow only |
| its own database `oatmakers-test-postgres` (Part 0) | no host port | migrated by your workflow only |
| production `oatmakers-site-7` | <https://cloud.mustrysolutions.com> | fed by `release.yaml` only |

- **The local gateway bind-mounts the repo.** A save in the Designer lands
  in your working tree immediately, so `git status` is your export step.
  Review the diff; stage only what you meant to change.
- **Your test gateway does not.** It gets its files the way production does:
  `docker cp` into the container plus an authenticated scan, run by your
  own workflow on your own runner. That is why a green test deploy is
  evidence about production and not just about your laptop.
- **Each gateway has its own database.** Your local gateway uses
  `oatmakers-postgres`; your test gateway uses `oatmakers-test-postgres`,
  which only your test workflow migrates. Both answer to the hostname
  `postgres`, like production's database, so one connection setting works in
  all three places.
- **Referenced secrets work locally too.** `local-development/secrets/`
  holds the local stand-ins at the path the gateway's file secret provider
  (named `environment`) reads, so a connection that references `POSTGRES_PASSWORD` resolves on
  your laptop and on production, each against its own database.
- **The 2-hour trial will lapse.** Perspective pages go blank and the
  Designer drops its connection; it looks like a bug in your work and it is
  not. Run `scripts/reset-trial.sh` (safe to re-run). Never wipe volumes for
  this.
- The loop is always: **build locally → see it in `git diff` → PR →
  review → merge (lands on test) → tag → `release.yaml` PR → live.**

---

## We-do (instructor demos)

### Demo 1: placing Oatmakers on the architecture map

1. The three reference architecture diagrams side by side (`architectures/`).
2. Oatmakers today: eight independent standalone gateways, no enterprise level.
3. Sketch the target live: frontend-backend per site, hub and spoke to central.

### Demo 2: one release PR on demo-oatmakers, end to end

1. `release.yaml` on screen: one file, one production gateway.
2. The tags behind it: `git tag -l 'oatmakers@*' --sort=-v:refname`.
3. Bump a pin on a branch, `git add release.yaml`, open the PR, read the diff
   as a release note, watch `CI OK` confirm the tag exists and sits on
   `main`.
4. Approve and merge, watch `Deploy` pick the job up on the
   `[self-hosted, demo-oatmakers]` runner, open the live demo. Then show
   what the **Revert** button on that merged PR would do.

### Demo 3: multi-site repo layouts on screen

1. Sketch option A (one repo for everything, what this lab uses) and
   option B (splits) live, against the constraints from the teaching: the
   vendor and the shared library.
2. Where the runners live: one per site, `runs-on: [self-hosted, site-4]`,
   inside the site network, no inbound access needed. Today: one per
   student laptop, plus one next to the production gateway.

## You do (breakout rooms): four parts

Follows [`slides/assignment.html`](https://share.mustrysolutions.com/a95c879a-d14b-4f76-8214-8f39784f09b1) ([offline copy](../slides/assignment.html)) 1:1.

### Part 0 (±15 min): stand up your test gateway and your runner

Everyone does this once, at the start, then leaves it running all afternoon.
It gives you a second local gateway that receives **every merge to
`main`**, so you see a change land somewhere safe before it is ever tagged
for production. It reuses building blocks you already own: a self-hosted
runner (labs 03-06) and a push-to-main deploy workflow that ships files by
`docker cp` and an authenticated scan (labs 04-06).

**1. Tell the stack who you are.** At the start of Part 0 the instructor
posts **one runner registration token** in the Zoom chat. Then:

```bash
cp .env.example .env
# edit .env: LAB_USER=<yourname>      lowercase, no spaces
#            RUNNER_TOKEN=<the token from the Zoom chat>
# leave IGNITION_API_KEY empty: setup.sh generates it
```

About that token:

- Everyone uses the same one. It can enroll any number of runners on this
  one repo while it lives, and nothing else: it is not a login and not a
  PAT, which is why sharing it in the chat is fine.
- Registering a runner is a repo-admin act, and contributors are not
  admins. That is why the token comes from the instructor instead of from a
  settings page, like it did in your fork.
- It expires **one hour** after it is generated. That only limits
  registration: your runner trades it for its own credentials on the first
  start and keeps them in a volume. Missed the window, or wiped your
  volumes? Say so; a fresh token takes five seconds.

**2. Start the stack.**

```bash
./scripts/setup.sh
```

`setup.sh` starts the local stack (gateway on `8088`, database on `5432`)
and, because `LAB_USER` is set, the `test` compose profile: your test
gateway `oatmakers-test-gateway` on `8090`, its own database
`oatmakers-test-postgres` and your runner
`oatmakers-test-runner-<yourname>`. It also generates your API key into
`.env` and seeds it into the test gateway **before** its first boot (the
scan API only accepts tokens the gateway has already loaded), so always use
`setup.sh` for the first start. At the end it checks that both gateways
accept your key. It is safe to re-run.

Need a new API key (it showed up on screen, say)? Empty `IGNITION_API_KEY`
in `.env` and run `./scripts/setup.sh` again: it generates a new key, puts
it on both gateways and your runner, and restarts each gateway that still
holds the old one.

**3. Check that your runner is online.** Contributors cannot open
*Settings → Actions → Runners*, so look at the runner itself:

```bash
docker logs oatmakers-test-runner-<yourname> 2>&1 | grep -E "Connected to GitHub|Listening for Jobs"
```

`Listening for Jobs` means your runner `oatmakers-test-<yourname>` is
registered with the labels `self-hosted,<yourname>-local` and waiting.

**4. Make the provided workflow yours.** The deploy workflow is already
written. Copy the template under your name:

```bash
git switch -c feature/<yourname>-test-workflow
cp .github/workflows/test-example.yml.template \
   .github/workflows/test-<yourname>.yml
```

In the new file, replace `CHANGEME` with your name in the one line marked
`CHANGEME`, the runner label:

```yaml
runs-on: [self-hosted, <yourname>-local]
```

Why a file per person, with the label written out? GitHub resolves
`runs-on` before any per-user context exists, and a repo variable has one
value for everyone: it would route every deploy to one laptop. One file per
person, each naming its own label, **is** the routing.

What the workflow does is what the production deploy does, minus the
`release.yaml` indirection: check out `main`, run the migrations against
your test gateway's own database, `docker cp` projects and config into your
test gateway, ship modules and JARs (restart only when they changed), then
ask the gateway for an authenticated scan.

**5. PR it in like anything else.**

```bash
git add .github/workflows/test-<yourname>.yml
git commit -m "ci: add test deploy workflow for <yourname>"
git push -u origin feature/<yourname>-test-workflow
```

Open the PR from the link `git push` prints. Wait for `CI OK`, ask for a
review in the room (the instructor or a fellow student approves), then
merge.

**6. Verify it works.** Your merge is itself a push to `main`, so it starts
your new workflow straight away:

- Actions tab → workflow `.github/workflows/test-<yourname>.yml` (a
  workflow without a `name:` is listed by its path) → the run for your
  merge commit is picked up by **your** runner and goes green.
- <http://localhost:8090/data/perspective/client/oatmakers/> serves the
  oatmakers project on your test gateway.
- From now on, every merge anyone makes runs your workflow too. Watch the
  runs pile up in the Actions tab during Part 1.

- **Observe:** the runner **label** is the whole routing story. Everyone
  has a push-to-main workflow, and each one deploys only to its owner's
  test gateway. Production uses the same mechanism:
  `runs-on: [self-hosted, demo-oatmakers]`.
- **Observe:** your test gateway gets its files the way production does,
  never through a bind mount of your working tree. Its database gets its
  migrations the way production's does: from the workflow, never from
  `scripts/migrate.sh` on your laptop.

- **From now on you can also deploy a branch** to your test gateway before
  you merge it: `gh workflow run test-<yourname>.yml --ref <your-branch>`
  (or **Run workflow** in the Actions tab, then pick the branch). The next
  push to `main` puts `main` back.

**Part 0 gate:** your `test-<yourname>.yml` merged through an approved PR,
`Listening for Jobs` in your runner's log, and a green `test-<yourname>.yml`
run that put `main` on `localhost:8090`.

### Part 1 (±20 min): create your own project and bring it live

Everyone does this part alone. It is the full loop every production deploy
in this lab uses: PR → review → merge → tag → `release.yaml` PR → live.

**1. Branch** from a fresh `main`:

```bash
git switch main && git pull
git switch -c feature/<yourname>-project
```

**2. Build your project on the local gateway.** In the Designer
(<http://localhost:8088>, `admin` / `password`) create a new project named
`<yourname>` (lowercase, the same as `LAB_USER`). Add one Perspective view
that shows your name, set it as the primary view of the `/` page in
*Page Configuration*, and save. `git status` now shows `projects/<yourname>/`.

```bash
git status                       # projects/<yourname>/ and nothing you did not make
git add projects/<yourname>/
git commit -m "feat: add <yourname> project with welcome view"
git push -u origin feature/<yourname>-project
```

**3. Open the PR and get it reviewed.** Wait for `CI OK`, then ask for an
approval. If you get review comments, fix them and push again: same PR.

**4. Merge.**

- **Observe:** your test gateway (and everyone else's) now serves
  `http://localhost:8090/data/perspective/client/<yourname>/`.
- **Observe:** production did **not** change. `Deploy` did not even run:
  `release.yaml` did not change. `main` means "reviewed and could ship",
  not "shipped".

**5. Tag your release.** This is what makes the release *exist*. Tag the
merged `main`, never your feature branch: a tag must point at a commit on
`main`, so that only reviewed code can ship.

```bash
git switch main && git pull
git tag <yourname>@v1.0.0
git push origin <yourname>@v1.0.0
```

The tag is the release: a named version of `projects/<yourname>/` that
`release.yaml` can point at. Nothing gets built; the deploy will check out
this tag and copy your project's files.

**6. Pin it in `release.yaml`.** Check the open PRs first: one release PR
in flight at a time. Then add one line:

```diff
 gateway: oatmakers-site-7
 projects:
   oatmakers: v5.0.0
+  <yourname>: v1.0.0
```

```bash
git switch -c pin/<yourname>-v1.0.0
# edit release.yaml
git add release.yaml
git commit -m "release: pin <yourname> v1.0.0"
git push -u origin pin/<yourname>-v1.0.0
```

PR, `CI OK`, approval, merge. If someone else's pin merged first and your
PR shows a conflict in `release.yaml`, rebase and keep both lines (rule 4
above).

- **Observe:** CI checks that `<yourname>@v1.0.0` exists, and that it
  points at a commit on `main`, before it lets the pin through. A pin to a
  tag nobody pushed, or to a tag on an unmerged branch, turns `CI OK` red.
  Pushed the missing tag afterwards? CI does not re-run by itself: open the
  PR's **Checks** tab → **Re-run failed jobs** (or
  `gh run rerun <run-id> --failed`).

**7. Watch it go live.** Actions tab → workflow `Deploy` → the run for
your merge, on the `demo-oatmakers` runner. When it is green, open
`https://cloud.mustrysolutions.com/data/perspective/client/<yourname>/`.

**Part 1 gate:** your project merged through an approved PR, the tag
`<yourname>@v1.0.0` pushed, your line in `release.yaml` merged through an
approved PR, and your view live on cloud.mustrysolutions.com.

### Part 2 (±35 min): five challenges on the shared oatmakers project

One project, the whole group, one version stream. Everything in these
challenges is a move you made in an earlier lab; the new part is doing it
together, on a live gateway.

**The rules:**

- **Claim a challenge in the breakout room.** Nothing is pre-assigned. More
  people than challenges: pair up on one. Challenge 5 builds on challenges
  3 and 4, so whoever takes it starts against their work as it lands.
- **All work lands in `projects/oatmakers/`** plus the lab 06 folders
  (`services/`, `third-party-modules/`, `jar-files/jar/`,
  `db-migration/migrate/`). Put your screens in a views folder of your own
  (for example `Course/<yourname>/`) with a page route like
  `/course/<yourname>`, your tags under a `Course/` folder, your tables
  with a `course_` prefix. Leave the demo's existing screens alone.
- **Check it on your test gateway first.** Before you merge, run
  `gh workflow run test-<yourname>.yml --ref <your-branch>` to put your
  branch on `localhost:8090`. After your PR merges, your
  `test-<yourname>.yml` run puts `main` there. If it does not work there, it
  will not work on production: fix it (with a follow-up PR if it already
  merged) before you tag.
- **Finished means live.** Merge your PR, cut the **next free**
  `oatmakers@` tag, pin it in `release.yaml` by PR. The gateway payload
  (config, modules, JARs, migrations) rides the `oatmakers` pin, which is
  why every challenge ends with a new `oatmakers@` tag.

**Finding the next free tag number.** The group starts at the
`oatmakers: v5.0.0` pin. A fix takes the next patch (`v5.0.1`), a new
screen or feature the next minor (`v5.1.0`). Someone may have tagged without
pinning yet, so look at the tags, not only at `release.yaml`:

```bash
git switch main && git pull
git fetch --tags
git tag -l 'oatmakers@*' --sort=-v:refname | head -3
git tag oatmakers@v5.1.0          # the next free number
git push origin oatmakers@v5.1.0
```

Push rejected? Someone took that number first. Your local tag still points
at your commit, and `git fetch --tags` will not overwrite it, so delete it,
fetch, and take the next number:

```bash
git tag -d oatmakers@v5.1.0 && git fetch --tags
git tag -l 'oatmakers@*' --sort=-v:refname | head -3
git tag oatmakers@v5.2.0 && git push origin oatmakers@v5.2.0
```

**Before you pin: is your change already live?** Your tag contains
everything merged before it, including other people's work. If
`release.yaml` already pins a higher `oatmakers@` version than yours, check
whether your tag is inside it:

```bash
git merge-base --is-ancestor oatmakers@v5.1.0 oatmakers@v5.2.0 && echo "already included"
```

`already included` means your change ships with the higher pin: you are
done, do not pin backwards. No output means it is not included: cut a new
tag from the current `main` and pin that one.

**Challenge 1: add the Embr Charts module and build a chart screen**

Embr Charts stays on production once a group installed it: the demo keeps
using it. If `services/modules.json` on `main` already has a
`com.mussonindustrial.embr.charts` entry, skip the download, the entry and
the recreate: check that your test gateway runs the module (installed from
the manifest alone: it shows in the gateway's module list on
`localhost:8090`), then build the chart screen.

- Download `Embr-Charts-Ignition83-6.0.1.modl` (Embr Charts 6.0.1 for
  Ignition 8.3, module id `com.mussonindustrial.embr.charts`) from
  <https://github.com/mussonindustrial/embr/releases/tag/releases%2F8.3%2F2026.6.17>
  and put it in `third-party-modules/`.
- Add a minimal entry to `services/modules.json` (the lab 06 move):

  ```json
  "com.mussonindustrial.embr.charts": {
    "filename": "/third-party-modules/Embr-Charts-Ignition83-6.0.1.modl",
    "onStartup": "enabled"
  },
  ```

- Recreate your local gateway (a recreate, not a restart: environment
  variables only reach a container when it is created):

  ```bash
  docker compose up -d --force-recreate gateway
  ```

  The repo's `docker-compose.yaml` already lists this module id in
  `ACCEPT_MODULE_LICENSES` and `ACCEPT_MODULE_CERTS` for your local gateway
  (the lab 06 env vars), so it installs headless and writes
  `certFingerprint` and `licenseAgreementHash` into your entry. Commit only
  your `modules.json` entry and the `.modl`.
- Your test gateway and production do not have that env var: they trust the
  module because of the two values in your entry. Your test gateway proves
  that before production does.
- Build a Perspective screen with a chart from the module on it.
- This release restarts production: announce it in the chat before you
  merge the pin.
- Verify on production: your chart renders on your page.

**Challenge 2: use the FastCSV JAR in a recipe-parsing function**

- Download `fastcsv-4.4.0.jar` from Maven Central
  (<https://repo1.maven.org/maven2/de/siegmar/fastcsv/4.4.0/fastcsv-4.4.0.jar>)
  into `jar-files/jar/` and add its row (source and sha256) to
  `jar-files/jar/README.md`, the lab 06 move. FastCSV on purpose: the
  gateway does not bundle it, so the import fails until the JAR is really
  there. (Importing commons-lang3 and friends proves nothing: the image
  already has them.)
- Make your local gateway load it. It bind-mounts `jar-files/jar/` into
  its JAR directory, and JARs load at boot, so a restart is all it takes:

  ```bash
  docker compose restart gateway
  ```

  Your test gateway and production keep the JARs their deploy ships in a
  volume, so the JAR survives a container recreate there too.

- Add a project script, for example `course/<yourname>/recipe`, with a
  function that parses a CSV line of ingredients:

  ```python
  from de.siegmar.fastcsv.reader import CsvReader

  def parseIngredients(line):
      records = list(CsvReader.builder().ofCsvRecord(line))
      return list(records[0].getFields())
  ```

- Build a Perspective screen that **calls your function**
  (`course.<yourname>.recipe.parseIngredients("oats,water,salt")`) and shows
  the parsed fields: **oats | water | salt**.
- A new JAR restarts production: announce it in the chat before you merge
  the pin.
- Verify on production: your page shows the three fields.

**Challenge 3: a database connection, a migration with a seed, a view on the data**

- Create a database connection named `Course_<yourname>` to
  `jdbc:postgresql://postgres:5432/ignition` (that hostname resolves locally
  and on production). Username: the plain string `ignition`. Password: the
  **referenced secret** `POSTGRES_PASSWORD` from the file secret provider
  named `environment` that is already in the gateway config. You reference
  it; you never see the value. Lab 06's secrets ladder, for real. (Ignition
  only references a secret for the password field; the username stays a
  plain setting.)
- The gateway creates a **store-and-forward engine** with the same name
  along with the connection, plus its status tags. Stage them with your
  connection, so nobody else's gateway shows them as stray files:
  `services/config/resources/core/ignition/database-connection/Course_<yourname>/`,
  `.../store-and-forward-engine/Course_<yourname>/`,
  `.../tag-definition/System/Gateway/Database/Course_<yourname>/` and
  `.../tag-definition/System/Gateway/StoreAndForward/course_<yourname>/`.
- Write a migration pair in `db-migration/migrate/` with the next free
  number: `.up.sql` creates your `course_` tables and seeds them,
  `.down.sql` undoes exactly that. **Always pairs.** Test it locally before
  the PR:

  ```bash
  scripts/migrate.sh up
  ```

  That is your local database. Your test gateway has its own, which only
  your test workflow migrates, so trying a migration locally never breaks
  your test runs. Your local database does remember it: run
  `scripts/migrate.sh down 1` before you switch branches or renumber, and
  `up` again after your PR merges. Pick a number higher than any on `main`
  at merge time, not just a free one: a lower number merged after a higher
  one already ran is silently skipped. If `main` already has your number
  when you rebase, renumber yours.
- Build a Perspective view that queries the seeded rows.
- Verify on production: your page shows the rows (so the connection is
  valid and the migration ran before the screen arrived).

**Challenge 4: a simulator device with tags and live values**

- Add a **Programmable Device Simulator** device to your local gateway
  (*Connections → Devices*) named `CourseSim`. Then open its program (the
  device's menu → **Edit Program**) and add two instructions, or load them
  as CSV:

  ```
  Time Interval, Browse Path, Value Source, Data Type
  0,"Ramp","ramp(0,100,60,1)","Double"
  0,"Sine","sine(-50,50,30,1)","Double"
  ```

  A ramp from 0 to 100 every 60 seconds and a sine between -50 and 50
  every 30 seconds.
- Create OPC tags on it in a `Course/` folder of the default tag provider
  (OPC server `Ignition OPC UA Server`, item paths `ns=1;s=[CourseSim]Ramp`
  and `ns=1;s=[CourseSim]Sine`, data type Float8) and use them on a
  Perspective screen.
- The device config and the tags live in `services/config/`: they travel
  with the pipeline like everything else. Stage your device
  (`.../com.inductiveautomation.opcua/device/CourseSim/`), your tag folder
  (`.../tag-definition/default/Course/`) and the status tags the gateway
  creates for the device (`.../tag-definition/System/Gateway/Devices/CourseSim/`).
- Verify on production: **values changing live**, on a gateway you never
  logged in to configure.

**Challenge 5: historize the live tags and build a dashboard**

- The **TimescaleDB-Historian** module (Mustry's own) already ships in
  `third-party-modules/` and is registered in `services/modules.json`: you
  build on it, you do not install it. It runs in trial mode unless a
  licence is installed; `scripts/reset-trial.sh` resets your local trial.
- Create a historian named `CourseHistorian` of the module's TimescaleDB
  type that stores into the same plant database challenge 3's connection
  reads (`jdbc:postgresql://postgres:5432/ignition`, username `ignition`).
  Password: the referenced `POSTGRES_PASSWORD`, like challenge 3.
- Like a connection, a historian comes with a store-and-forward engine of
  the same name. Stage `.../store-and-forward-engine/CourseHistorian/` and
  `.../tag-definition/System/Gateway/StoreAndForward/coursehistorian/` with
  it. Never give a historian the name of a connection: they would share
  one engine, and removing either one deletes it and stops the other.
- Enable **tag history** on challenge 4's tags, pointed at your historian.
- Build a dashboard view that charts that history.
- You will be merging into files the others just changed. **Merge
  conflicts are part of the challenge**, not an accident.
- Verify on production: the chart fills up with history from the live tags.

**Part 2 gate:** your challenge live on production through a reviewed PR,
an `oatmakers@` tag that contains it, and a `release.yaml` pin (yours, or a
higher one you proved contains your tag).

### Part 3 (extra): build on each other's work

Everything from Part 2 is now shared infrastructure. Agree as a group who
does what, then ship it the same way: small PR, quick review, next free
tag, one release PR at a time.

- **A showcase view.** One overview screen in the oatmakers project that
  pulls the group's work together: the chart, the live tags, the database
  rows. Agree on the layout, then land it section by section in small PRs.
- **A shared library at its own version tag.** Create an inheritable
  project `projects/course-lib/` with something others can reuse (a
  styled component, a script function). Tag `course-lib@v1.0.0` and pin it
  in `release.yaml`. Then make your own Part 1 project inherit from it, tag
  `<yourname>@v1.1.0` and pin that too. Inheritance is two fields in
  `project.json`: `"inheritable": true` in `course-lib`, and
  `"parent": "course-lib"` in yours (or set both in the gateway's project
  settings); `scripts/scan.sh` loads the change. The parent has to be on the gateway
  before (or together with) the child that inherits from it: the teaching's
  "parent pinned alongside", in one flat release file.
- **Cross the challenges.** Historize more tags, add a migration on top of
  someone else's tables, put an Embr chart on the seeded data, call the
  recipe function from your own view. Or rebuild something that looks like
  another challenge, purely to train the move you want more reps on.
- **Stay current.** Pull `main` often and rebase your branch. Most merge
  conflicts die before they are born; the ones that do happen are the
  pipeline making a collision visible *before* production.

---

## Troubleshooting

- **My `test-<yourname>.yml` run says "Waiting for a runner to pick up this
  job".** The label in `runs-on` does not match your runner. It must be
  exactly `<yourname>-local`, with the same `<yourname>` as `LAB_USER` in
  `.env`. Check `docker logs oatmakers-test-runner-<yourname>` for
  `Listening for Jobs`.
- **The runner log says the token is invalid or expired.** Ask for a fresh
  token in the chat, put it in `.env` as `RUNNER_TOKEN`, and re-run
  `./scripts/setup.sh`.
- **`setup.sh` says a port is already in use.** Something else holds
  8088, 8090 or 5432 (often the lab 06 stack). Stop it, or move this lab:
  set `GATEWAY_PORT`, `TEST_GATEWAY_PORT` or `POSTGRES_PORT` in `.env` and
  re-run `./scripts/setup.sh`. The URLs in this lab then use your ports.
- **Perspective pages are blank, the Designer disconnects, a deploy that
  worked an hour ago fails.** The trial lapsed: `scripts/reset-trial.sh`.
- **`git status` shows files you never touched** (`services/modules.json`
  fingerprints, `resource.json` stamps). That is gateway churn, not your
  change: do not stage it. See
  [`docs/resource-json-hygiene.html`](https://share.mustrysolutions.com/cd8236d4-d050-4d49-b8c7-bbe4bfc35a0f) ([offline copy](../docs/resource-json-hygiene.html)).
  The exception: folders the gateway creates for something **you** added
  belong in your PR: `store-and-forward-engine/<name>/` and
  `tag-definition/System/Gateway/{Devices,Database,StoreAndForward}/<name>/`
  for your device, connection or historian. The same folders for someone
  else's work, after a pull, are theirs: leave them.
- **Your `test-<yourname>.yml` run fails with
  `no migration found for version N`.** You deployed a branch with
  `gh workflow run` and its migration is still in your test database, but
  `main` does not have it. On that branch:
  `scripts/migrate.sh --test down 1`, then re-run the failed run.
- **`scripts/migrate.sh up` (or `setup.sh`) says
  `no migration found for version N`.** The same, in your local database:
  on that branch, `scripts/migrate.sh down 1`.
- **Your test run says `Still not authorized`.** Your test gateway and your
  runner hold different API keys (the key in `.env` changed without a
  `setup.sh` run). Run `./scripts/setup.sh`: it puts the key from `.env` on
  both and restarts the gateway. Then re-run the failed run.
- **`CI OK` is red on a release PR.** Open the failing job: most often the
  pin points at a tag that was never pushed (`git push origin <tag>`), a
  tag on a commit that is not on `main` (tag `main` after your PR merged),
  or the YAML lost a line in a rebase. After pushing a missing tag, CI does
  not re-run by itself: **Checks** tab → **Re-run failed jobs** (or
  `gh run rerun <run-id> --failed`).
- **`Deploy` is red, or production looks wrong after your release.** Say so
  in the chat straight away. The fix is a revert of the release PR (the
  **Revert** button on the merged PR, then review and merge as usual); the
  instructor handles anything a revert cannot undo, such as a migration
  that already ran.

## Definition of done

Everything on this list is visible on GitHub or on the production gateway;
nothing needs your laptop.

0. **Part 0:** your `test-<yourname>.yml` merged through an approved PR, and
   a green `test-<yourname>.yml` run on your own runner.
1. **Part 1:** `projects/<yourname>/` merged through an approved PR, the tag
   `<yourname>@v1.0.0`, your line in `release.yaml`, and your view **live on
   cloud.mustrysolutions.com**.
2. **Part 2:** your challenge merged and **live on production** via an
   `oatmakers@` tag that contains it and a reviewed `release.yaml` pin.
3. **Part 3:** at least one merged PR that **builds on someone else's
   work**, and at least one review (an approval or a comment) you gave
   someone else.

## Debrief

Bring answers:

- One repo carried the whole group to one production gateway today. When
  would you split it, like the teaching's option B, and which part would you
  split off first?
- Who may merge what at your plant, and who approves a production release?
- What does "only reviewed commits reach main" mean in your organisation,
  and what enforces it?
- Two people cut a tag at the same time today. How would your plant keep
  one version stream sane with ten engineers on it?
- Who is the master of tags at your plant today (teaching Part 4), and does
  anything enforce it?
- And the course-closing question: **what will you build first, back at
  your own plant?**

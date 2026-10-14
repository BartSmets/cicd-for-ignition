# Lab 02: Branching and Pull Requests

One **we-do / you-do** covering two linked topics: how the team *branches* (GitHub
Flow, the course's strategy), and how changes flow through *pull requests*. You
learn both, then live them: you run the release-week hotfix scenario through GitHub
Flow on a real Ignition project, end to end.

## What you're working on

The subject of this lab is a small but **real Ignition project**
(`projects/lab-project/`): a Perspective HMI screen (the Oatmakers Site 04
oat-line overview, the client from Lab 01) and two Python script libraries. You don't need prior Ignition experience: the
gateway's admin complexity is abstracted away, and what you edit is approachable (a
small Python function, or a new view). The lab is about the **Git workflow** around
those files: how you branch, how you open and review a PR, how you merge. Gateway
config, modules, and deploys are out of scope; they arrive in Lab 04.

## Setup

Go to this lab's folder in your fork and check where `gh` opens PRs:

```bash
cd ~/mustry-academy/cicd-for-ignition/labs/02-branching-and-prs
gh repo set-default --view        # must print YOUR fork
gh repo set-default <your-username>/cicd-for-ignition   # if not
code .
```

You can do every exercise from the files alone. But spinning up the gateway once
makes the project tangible, and lets you see your new v2.0 view go live (optional
but recommended):

```bash
cp .env.example .env
scripts/setup.sh          # boots one Ignition gateway, waits for RUNNING
# open http://localhost:8088  → log in with the .env credentials
```

Port 8088 already in use on your machine? Set `GATEWAY_PORT` in `.env` and use that
port in every `localhost:8088` URL below. See [`docs/TROUBLESHOOTING.md`](../docs/TROUBLESHOOTING.md).

A running gateway does not pick up file edits by itself: run `docker compose restart`,
or `scripts/scan.sh` once you've set up the API key described in `.env.example`.

Before opening any PR, run the validator. It's the green/red signal this lab uses
in place of a test suite:

```bash
scripts/validate.sh       # checks every project file is valid JSON / parses as Python
```

## Goal

By the end of this lab you should be able to:

- Run a **GitHub Flow release week** end to end: a feature and a P1 fix through PRs into `main`, released in the right order with version tags
- Open a PR a reviewer enjoys reading: small, scoped, with a clear what / why / how-to-test
- Review someone else's PR with feedback that helps, and choose between approve, request-changes, and comment
- Merge cleanly and in the right order when approved

Read-ahead: [`docs/github-flow.md`](../docs/github-flow.md) walks through the scenario in GitHub Flow. Optional deep-dive on review craft: [`docs/pr-review-style.md`](../docs/pr-review-style.md).

---

## We-do

Parts A and B are an **instructor demo**: the tutor walks through them on screen,
you watch and ask questions. Nothing to type yet; your hands-on work starts in the
You-do.

### Part A: what a good pull request looks like

Two PRs side by side on the projector:

| Bad PR | Good PR |
|---|---|
| Title: "update stuff" | Title: "fix(display): handle null readings without crashing" |
| 800-line diff across 12 files | 6-line diff in one file |
| No description | Clear What / Why / How to test |
| Mixes a rename, a bugfix, and a feature | One concern only |
| Leaves `validate.sh` red | `validate.sh` green |

The good column is the whole lesson. A PR is easy to review when it's **small**,
does **one thing**, is **self-describing** (What / Why / How to test), and shows
**how it was verified**. If you catch yourself writing "and" in the title, split
the PR.

### Part B: leaving review feedback

Prefix each comment with what kind it is, so the author knows how to react. Three
labels cover almost everything:

- `praise:` something genuinely good. "praise: nicely focused diff, easy to review."
- `suggestion:` a specific, optional improvement. "suggestion: collapse these two ifs into one."
- `issue:` something that should change before merge. "issue: this still throws on a null reading; `format_reading(None, '°C')` errors instead of showing a placeholder."

The fuller toolkit (more labels, tone, and handling disagreement) is in the optional
[`docs/pr-review-style.md`](../docs/pr-review-style.md).

---

## You do

You live the release-week scenario from the teaching deck, for real, on your own
fork. Ship a v2.0 feature, get ambushed by a P1 bug in production, and thread both
through **GitHub Flow**, exactly the way the teaching deck drew it. Then your peers
review your PRs and you merge in release order.

Do the whole thing in your breakout room, sharing your screen. Open PRs early, and
invite your reviewer early: add a peer from your room or one of the tutors as a
**collaborator on your fork** (Settings → Collaborators → Add people), then request
their review on each PR. The review step needs a peer's PR to exist, and merging
needs a peer to have reviewed yours.

> Careful when opening PRs on a fork: GitHub's "Compare & pull request" banner
> defaults the **base repo** to the upstream course repo. Switch it to **your
> fork** every time. `gh pr create` uses the repo `gh repo set-default --view`
> prints, which must be your fork (see Setup).

### Part 1: run the release-week scenario in GitHub Flow

`v1.2` is live in production. You start the v2.0 feature, and mid-work a P1 bug in
production ambushes you. You thread both through GitHub Flow.

**Step 1: tag what is live.** One long-lived branch, `main`, and a tag marking
what's in production: in GitHub Flow, tags carry the release history. Tag what's
live as `v1.2` on `main` and push the tag. Your fork hosts every lab of the course,
so this lab's tags carry a `lab02-` prefix: the release is v1.2, the tag is
`lab02-v1.2.0` (every lab tags `labNN-vX.Y.Z`). Use an **annotated** tag (`-a`), as
Lab 01 taught for releases: it records who tagged, when, and why.

First make your local `main` match your fork's. Lab 01's practice commits (the
participant line, the notes, the rebased feature) are still on your local `main`,
never pushed: branch off it now and every PR today carries them along, and the
"just the fix" hotfix ships Lab 01's edits in v1.2.1. Park them on a branch instead
of throwing them away, then reset `main` to your fork's:

```bash
git switch main
git branch lab01-practice         # park Lab 01's local commits (skip if you already have it)
git fetch origin
git reset --hard origin/main      # main = your fork's main; git status: "up to date"
git tag -a lab02-v1.2.0 -m "Release 1.2.0"
git push origin lab02-v1.2.0      # "production" is v1.2
```

`main` is the one shared line of development, `lab02-v1.2.0` is the exact commit
customers are running, and releasing means merging to `main` and tagging. Every
branch you cut next is short-lived: off `main`, back to `main` through a PR.

> Tags don't ride along with a normal push, so `git push origin lab02-v1.2.0` sends
> one explicitly. A *new* branch needs `git push -u origin <branch>` once, where
> `-u` links it to your fork so every later push is just `git push`.

**Step 2: ship the v2.0 feature (the silo detail view).** Oatmakers' v2.0 scope
starts with a **silo detail view**: that's your feature. Branch off `main`:
`feature/v2-silo-detail`. The easiest path to the view itself: copy the `overview`
resource folder to `silo-detail` under `views/pages/`, edit the `Subtitle` label's
`text` in its `view.json`, and register the `/silo-detail` page in
`page-config/config.json` so it's reachable (give the page its own `title` there):

```json
    "/silo-detail": {
      "title": "Silo detail",
      "viewPath": "pages/silo-detail"
    }
```

Run `scripts/validate.sh` (green), commit with a
[Conventional Commits](https://www.conventionalcommits.org/) message, push, and open
a PR with **base = `main`**. Request your reviewer on it, and **leave it
open**: the ambush comes before you merge. (A copied view makes a big diff, over
2,000 lines plus a binary `thumbnail.png`; that's fine. The review focuses on the
page registration and valid JSON, not the line count.)

```bash
git switch main
git switch -c feature/v2-silo-detail

# copy the overview view to silo-detail
P=projects/lab-project/com.inductiveautomation.perspective
cp -r "$P/views/pages/overview" "$P/views/pages/silo-detail"
# edit the Subtitle label's "text" in $P/views/pages/silo-detail/view.json
# register /silo-detail in $P/page-config/config.json

scripts/validate.sh                 # green
git add projects/                   # the new view folder is untracked: commit -a would miss it
git commit -m "feat(views): add v2.0 silo detail view"
git push -u origin feature/v2-silo-detail
gh pr create                        # or the "Compare & pull request" banner: base repo = YOUR fork, base = main
```

> Gateway up? `scripts/scan.sh` (or `docker compose restart`), then open
> `http://localhost:8088/data/perspective/client/lab-project/silo-detail` (your
> `GATEWAY_PORT` instead of 8088 if you changed it). Your new page is there.

**Step 3: the P1 ambush, fixed the GitHub Flow way.** Your feature is still open when
a customer hits the null-reading crash in v1.2, live. It can't wait for v2.0.

1. Branch the fix off `main`: `fix/null-reading`. Because your
   feature PR is still **open**, `main` *is* v1.2: the fix carries no v2.0 work.
   The gateway serves whatever branch is checked out (`projects/` is bind-mounted),
   so after the next scan or restart the silo-detail page is gone from it. It comes
   back when you switch to `feature/v2-silo-detail` again.
2. The bug: `lab.display.format_reading()` in
   [`projects/lab-project/ignition/script-python/lab/display/code.py`](../projects/lab-project/ignition/script-python/lab/display/code.py)
   does `"%.1f" % None` on a null reading (a tag not yet read, or a comms loss) and
   throws, so the label shows an error instead of a value. Fix it: return a clean
   placeholder like `"-- °C"` for `None` (and other bad input), while keeping the
   normal numeric formatting. Remember `0` is a valid reading and must still format as
   `"0.0 °C"`. Run `scripts/validate.sh` (green), then run the function itself (see
   "Test the function" below) and paste its output into the PR's **How to test**.
3. **One PR into `main`**, your reviewer requested. **Don't merge yet**: your peers
   review first, and the merging (plus the `lab02-v1.2.1` tag) happens in release
   order in Part 2.
4. That's **two PRs open** (feature → `main`, fix → `main`), your reviewer
   requested on each. **Merge order is the lesson now**: the fix must land (and
   `lab02-v1.2.1` be tagged) *before* the feature merges. In GitHub Flow, merging is
   releasing: whatever is on `main` when you tag `lab02-v1.2.1` ships in v1.2.1.

```bash
# the fix branches off main, which IS v1.2, because the feature hasn't merged yet
git switch main
git switch -c fix/null-reading
# fix format_reading(), then:
scripts/validate.sh
git commit -am "fix(display): placeholder for null readings"
git push -u origin fix/null-reading
gh pr create      # ONE PR: fix -> main (reviewed, merged first, then tagged v1.2.1 in Part 2)
```

**Test the function.** `validate.sh` only checks that the file parses, and the
overview's kiln temperature tile always passes `162.0`, so neither ever shows the
`None` case. Run `format_reading()` directly with your laptop's Python 3, from the
lab folder:

```bash
python3 -c "import runpy
p = 'projects/lab-project/ignition/script-python/lab/display/code.py'
f = runpy.run_path(p)['format_reading']
for v in (162.0, 0, None): print(f(v, '°C'))"
```

Before the fix it prints `162.0 °C` and `0.0 °C`, then fails with
`TypeError: must be real number, not NoneType`. After the fix the third line is
your placeholder (`-- °C`). One limit: code that calls another project library
(for example `lab.util.to_float`) only runs on the gateway, where `lab` exists. Here
it fails with `NameError: name 'lab' is not defined`.

### Part 2: review a peer's PR, then merge yours

You each have a fix PR and a feature PR open. Pair up in your room so each PR gets
one reviewer: the collaborator invites from Part 1 decide who reviews whom.

1. Open the PR you were asked to review (it's in your GitHub notifications). The
   **fix** is the richest to review.
2. **Read it slowly**, at least 5 minutes before writing anything. For the fix:
   - Do valid readings still format? `format_reading(162.0, "°C")` must return
     `"162.0 °C"`, and `format_reading(0, "°C")` must return `"0.0 °C"` (zero is a
     valid reading, not "missing"), and `None` must give the placeholder. Run it
     yourself: `gh pr checkout <number> --repo <author>/cicd-for-ignition --detach`
     puts their branch in your working tree without creating a local branch; run the
     `python3 -c ...` command from Part 1's "Test the function", then `git switch -`
     to return to your own branch (Git warns that you leave a commit behind: that's
     the author's commit, safe to ignore).
   - Is the fix **just the fix** (no v2.0 work riding along), and is it set to
     merge **before** the feature?
   - Did they run `validate.sh`? Is the "How to test" something you could follow?
   For the feature PR: is the JSON well-formed, the page registered, the change scoped?
3. Leave a few genuinely helpful comments: at minimum a `praise:` and a `suggestion:`,
   plus an `issue:` if something is actually wrong.
4. Submit the review. In the PR's **Files changed** tab, hover a line and click
   **+** to comment (choose **Start a review**, so your comments arrive together).
   Then click **Review changes** (top right), pick **Request changes** if you left at
   least one `issue:`, **Approve** otherwise, and **Submit review**.

> Watch your tone: if you wouldn't say it in person, don't write it in the PR.

Then respond and merge, in release order:

1. On your PRs, answer every comment (`+1` for praise, reply to questions, push a
   fix-up commit for what you accept, reply with reasoning for what you decline).
   Additive commits, no force-push during review. Re-request review when ready.
2. Merge the **fix PR first** (production is on fire). Use **Create a merge
   commit** (if the green button shows Squash or Rebase, switch it in the button's
   dropdown). Then tag `lab02-v1.2.1` on `main`: in GitHub Flow, the tag *is* the
   release:

   ```bash
   git switch main && git pull
   git tag -a lab02-v1.2.1 -m "Release 1.2.1: null-reading fix" && git push origin lab02-v1.2.1
   ```

   Delete the fix branch once it's merged (GitHub offers a button; take it).
3. Now finish the feature: pull the fix down into your feature branch
   (`git switch feature/v2-silo-detail` then `git merge main`), push, then merge the
   feature PR into `main` (again **Create a merge commit**) and delete the feature
   branch.

### Done when

- Tags `lab02-v1.2.0` and `lab02-v1.2.1` are on your fork.
- The fix PR merged **before** the feature PR, both with a merge commit, both branches deleted.
- `lab02-v1.2.1` holds the fix and no silo-detail view.
- Every review comment on your PRs is answered.
- You submitted one review on a peer's PR, with a verdict.

## Debrief

- Where does `v1.2` live in GitHub Flow, now that `main` is v2.0?
- One thing you saw in someone else's PR that you'll steal for your own work? One habit you want to drop?
- When does a `request-changes` review do more harm than good?
- For your Ignition projects specifically: what's the smallest change you could meaningfully PR? You just did one: a single script function, a single new view.

# Lab 01: Git Fundamentals

**Duration:** ~180 minutes

* 30 min: introduction (welcome to the series, logistics, the Oatmakers story)
* 45 min: Teaching: how Git works
* 30 min: We-do
* 60 min: You-do (breakout rooms)
* 15 min: wrap-up and questions

This is the **first lab in the CI/CD series**, so we open with a short introduction to the
course as a whole. After that it's one continuous lab that blends Git's *object model* with the
*everyday workflow*: you watch `add -p` build the index, watch a commit produce a fresh tree and
blob, and see `rebase` as "new commit objects, not moved ones."

## Goal

You should leave this lab able to:

- Use the basic Git commands: `git add`, `git commit`, `git status`, `git branch`, `git switch` (and the older `git checkout`), `git merge`, `git rebase`, `git cherry-pick`, `git blame`, `git reset`, `git tag`. `git init`, `git push` and `git pull` are named today; you use push and pull from Lab 02 on.
- Explain what `.gitignore` does
- Explain what Git does under the hood: how blobs, trees and commits link, and why every commit is a snapshot
- Choose between **merge** (fast-forward vs `--no-ff`) and **rebase** deliberately
- Recover from "I committed to the wrong branch"

## Introduction: welcome to the series (30 min)

Because this is the first class, the instructor opens with the bigger picture from
[`slides/introduction.html`](https://share.mustrysolutions.com/eb94880a-c904-4cca-95c0-8b8dbbae345a) ([offline copy](../slides/introduction.html)).

1. **Welcome and introductions.** Quick round-the-room: name, role, and one thing you want out of this course.
2. **What this course is about.** A **CI/CD course for Ignition**: we go deep into Git and CI/CD, always applied to Ignition and made practical. Not a pure Git course or a pure CI/CD course: practical tools for your day-to-day work.
3. **How the series fits together.** 7 labs over four days: 01 Git fundamentals and 02 Branching and pull requests (Day 1), 03 GitHub Actions and 04 Ignition file-based deploy (Day 2), 05 Ignition image-based deploy (Day 3), 06 Secrets, database migrations, modules & JARs and 07 Deployments in a multi-gateway architecture (Day 4). Each lab has its own folder, so you always get a fresh start, even if you could not finish the previous lab. In Lab 07 the whole group works on one shared repo and deploys to a real production gateway.
4. **Your fork.** A fork is your own copy of the course repo on GitHub (`<you>/cicd-for-ignition`); your clone of it lives in `~/mustry-academy/cicd-for-ignition`. You made both before Day 1 (step 1 of the [course README](../../../README.md)). In your fork you commit, branch and push freely.
5. **Where you run the commands.** In the terminal on macOS or Linux, or in a WSL2 terminal on Windows, with the clone in your Linux home. Not in PowerShell or Git Bash, and never under `/mnt/c/`.
6. **How the labs work.** Each lab follows the same rhythm: **Teaching**, **We-do** (instructor live-codes), **You-do** (breakout rooms), then a **debrief**, with optional stretch challenges if you finish early. Interrupt us anytime; company-specific questions at the end of the day. Notes you take in `NOTES.local.md` are gitignored and yours to keep.
7. **Breakout rooms.** Everyone shares their screen at the same time; Sam and Jasper move between the rooms and look over your shoulder.
8. **AI agents.** AI can probably one-shot these labs. Do them as much as possible without it: you get the fundamentals in your fingers, and then you steer AI much better when you build this out for yourself.
9. **The Oatmakers story.** We walk through [`slides/oatmakers-story.html`](https://share.mustrysolutions.com/f50d9d30-81b9-48ae-819d-1614674534f0) ([offline copy](../slides/oatmakers-story.html)): one fictional client (Oatmakers, eight Ignition sites, zero CI/CD) whose troubles set the stage for the whole series. Each day the map heals a little more.

## Teaching: how Git works (45 min)

The instructor teaches the foundations from [`slides/teaching.html`](https://share.mustrysolutions.com/0a731a79-f381-402b-9b77-16415e2ff052) ([offline copy](../slides/teaching.html)).
We *do* the moves in the We-do that follows. Keep [`docs/git-object-model.md`](../docs/git-object-model.md) open as a cheat sheet.

### What Git does for you

Git is a **version control system**: it records every change to your files. It tracks changes
across files, compares versions, takes you back to old versions, reverts, and lets you share and
combine changes with others. Reference reading: [`docs/why-version-control.md`](../docs/why-version-control.md).

### How Git stores your project in `.git/`

- **Blobs.** `.git/objects` is a key-value store: the key is a hash of a file's content, the value is the content. A blob has **no filename**; identical content is stored once.
- **Trees.** A directory listing that maps names to the hashes of blobs and sub-trees: this is where filenames live.
- **Commits.** A commit points to a *single* tree (a **full snapshot**) and to its parent; unchanged blobs and sub-trees are reused, never re-stored.
- **Make a commit.** `git add` copies a change from the **working tree** into the **staging area** (the index), the draft of your next commit. `git commit` turns what is staged into a commit. `git status` shows what is edited, staged and untracked; `git init` turns a folder into a repo.
- **Branches.** Commits are immutable; a branch is a readable name that moves forward as you commit.
- **HEAD.** The pointer to your current branch; `git switch` moves it, and the next commit attaches wherever it points.

### Bring branches together: merge, rebase, cherry-pick

- **Merge.** When `main` hasn't moved, merging is a **fast-forward**: the pointer slides up, no new commit. When history has **diverged**, Git does a **three-way merge** and records a **merge commit with two parents**.
- **Rebase.** Re-applies your commits onto the new tip as **brand-new commits** (new SHAs). No merge commit: linear history.
- **Cherry-pick.** Copies a *single* commit's change onto your branch as a new commit; the source branch keeps its original.
- **Conflicts.** When a merge or rebase cannot combine two edits to the same lines, Git stops and writes both versions into the file between markers: `<<<<<<<` (the branch you are on; during a rebase, the branch you rebase onto), `=======`, then `>>>>>>>` (the incoming commit). Edit the file to the result you want, delete the three marker lines, `git add` the file and run `git rebase --continue` (or `git merge --continue`). `git rebase --abort` (or `git merge --abort`) puts everything back.

### Remotes, tags, undo and `.gitignore`

- **Remotes.** Every clone is a full copy of the history. A remote is another copy on a server: here `origin` is your fork on GitHub, and `git remote -v` lists it. `clone` copies it down, `push` sends your commits up, `pull` brings theirs down. `origin/main` is where `origin`'s `main` was when you last synced.
- **Tags.** A name that stays on one commit. Lightweight: `git tag v1.2`. Annotated, for releases: `git tag -a v1.2 -m "Release 1.2"`. Push a tag by name: `git push origin v1.2`.
- **Undo with `git reset`.**

  | Command | The branch pointer | The changes you undo |
  |---|---|---|
  | `git reset --soft HEAD~1` | back one commit | kept, staged |
  | `git reset HEAD~1` | back one commit | kept in your files, unstaged |
  | `git reset --hard <commit>` | to `<commit>` | discarded, uncommitted edits too: no undo |

  Committed to the wrong branch? `git reset --soft HEAD~1`, then `git switch -c feature/x` and `git commit`.
- **`.gitignore`** lists the files Git leaves alone. This lab's [`.gitignore`](../.gitignore) ignores `.venv/`, the Python caches (`__pycache__/`, `.pytest_cache/`) and `NOTES.local.md`. `git status` lists **untracked** files; **ignored** files don't show up.

### The commands you use in the We-do and You-do

| Command | What it does |
|---|---|
| `git config --global core.editor "code --wait"` | Git opens a VS Code tab for messages (`rebase -i`, a merge without `-m`, `rebase --continue`): save, then close the tab |
| `git switch -c <name>` | create a branch and switch to it |
| `git branch -D <name>` | delete a branch, even one merged nowhere |
| `git commit -am "message"` | stage the files Git already tracks, then commit (new files are not included) |
| `git add -p` | stage hunk by hunk: `y` stage, `n` skip, `s` split, `e` edit, `q` quit |
| `git cat-file -p HEAD` | print an object: a commit, a tree or a blob |
| `git ls-tree HEAD sample-app/` | a tree's entries (mode, type, SHA, name); `-r` recurses |
| `git log --graph --decorate --oneline --all` | every branch's history as a graph |
| `git blame sample-app/app.py` | who last touched each line; `^` before a SHA: the line dates from the first commit |
| `git log -L :farewell:sample-app/app.py` | every commit that changed the lines of the `farewell` function |
| `git merge --no-ff <branch>` | always record a merge commit, even when a fast-forward was possible |
| `git diff HEAD~1 HEAD` | what changed between two commits |

## We-do (30 min)

The instructor live-codes, narrating the object graph at every step.

**1. A commit is a tree.** Walk the existing `sample-app/` history:

1. `git log --oneline`: note one commit's SHA, e.g. `a1b2c3d`. The repo holds the whole course, so this is the course's history; `git log --oneline -- .` narrows it to this folder.
2. `git cat-file -p a1b2c3d`: read the commit object out loud. Note the `tree` line and the `parent` line. *That SHA is the **key**; `cat-file` prints the **value**.*
3. `git cat-file -p <tree-SHA>`: read the tree object. It lists blobs and sub-trees by SHA: the **filename lives in the tree entry**.
4. `git cat-file -p <blob-SHA>`: see the raw file content. The blob has no filename of its own.

**2. What a commit actually does.**

1. Edit one line of `sample-app/README.md`.
2. `git add sample-app/README.md`: the **index** now holds a new blob, staged but not committed. `git status` shows the staged change.
3. `git commit -m "docs: tweak intro"`: a **new commit object** points at a **new tree**, whose `README.md` entry points at a **new blob**. `HEAD`'s branch advances to it.
4. `git cat-file -p HEAD`, then its tree, then down the sub-trees `labs` → `01-git-fundamentals` → `sample-app`, then the README blob: only the README blob SHA changed; `app.py`'s blob is the same SHA as before. *The commit is a **full snapshot**, but the unchanged blob is **reused, not re-stored**.*

**3. Branching and rewriting are pointer moves and new objects.**

1. `git switch -c demo/throwaway`: a branch is a cheap, movable pointer to a commit. Nothing is copied.
2. Make three small commits on `demo/throwaway` (three one-line edits to `sample-app/README.md`, each committed with `git commit -am "…"`), then `git rebase -i main`. The todo list in the editor holds exactly those three commits: reorder, squash or reword them, save and close. The commit SHAs **change**: rebase **creates new commit objects** and re-points the branch.
3. **Merge: fast-forward.** `git switch main && git merge demo/throwaway`: `main` has not moved, so the `main` pointer just slides forward. No merge commit.
4. **Merge: `--no-ff`.** `git switch demo/throwaway`, add one more commit, `git switch main`, then `git merge --no-ff demo/throwaway -m "Merge demo/throwaway"`: `--no-ff` forces a merge commit. `git cat-file -p HEAD` shows **two `parent` lines**. `git log --graph --decorate --oneline --all` shows the shape: the demo sits at the top; below it is the course repo's own history.
5. **Wrong-branch recovery.** On `main`, edit `sample-app/README.md` and `git commit -am "docs: meant for a branch"`. Then `git reset --soft HEAD~1`: the branch moves back one commit, the change stays **staged**. Then `git switch -c feature/recovered && git commit -m "docs: meant for a branch"`. `reset` moved a ref; your blobs didn't go anywhere.

## You-do (breakout rooms) (60 min)

Break into rooms. **Share your screen** so Sam and Jasper can look over your shoulder.
Write your answers in `NOTES.local.md` (gitignored).

We start with a short **guided warm-up together**, then you go solo through two phases on the same
clone. **Do Phase 1 first**: its gate (`scripts/verify-lab.sh`) checks that `HEAD` is your focused
commit, and Phase 2's merges and resets break that check.

> **Lab 01 stays on your machine: never push or Sync `main` in this lab.** Lab 02 starts by
> resetting `main` to your fork.

### Warm-up (together)

**Part 0: open your fork's Lab 01 folder in VS Code.**

```bash
cd ~/mustry-academy/cicd-for-ignition/labs/01-git-fundamentals   # no clone yet? course README, step 1
git remote -v                                    # origin shows YOUR username; upstream at Mustry-Academy is fine
git config --global core.editor "code --wait"   # Git opens VS Code when it needs a message
code .                                           # then work from its terminal (Ctrl+`)
```

Run every command in this lab from the lab folder, `labs/01-git-fundamentals/`.

**Part 1: trace a commit through the object graph.**

1. `git switch main`, then add a single sentence to `sample-app/README.md`.
2. `git add sample-app/README.md && git commit -m "docs: expand sample-app intro"`.
3. `git cat-file -p HEAD`: note the `tree` SHA and the `parent` SHA.
4. `git cat-file -p <tree-SHA>`: this is the **root** tree of the course repo, so its `README.md` is the course's README, not the one you edited. Follow the sub-trees down: `labs` → `01-git-fundamentals` → `sample-app`, running `git cat-file -p` on each SHA in turn.
5. `git cat-file -p <sample-app-tree-SHA>`: *this* tree lists your `README.md`. Note its blob SHA.
6. `git cat-file -p <blob-SHA>`: your new content, and no filename.
7. `git ls-tree HEAD sample-app/`: the same walk in one command. The `README.md` blob SHA matches the one you traced by hand.

**Part 2: split a messy working tree into three commits with `git add -p`.**

1. Reset `main` to your fork: `git reset --hard origin/main`. This drops the practice commit above (and anything else you committed on `main` during the We-do).
2. `git switch -c we-do-greeting-polish`.
3. `scripts/seed-messy-state.sh`: `git status` shows a known messy tree in `sample-app/`.
4. `git add -p`: stage **one** logical change, commit it. Three commits in total. After each commit, run `git ls-tree -r HEAD sample-app/` and note which blob SHA changed.
5. `git log --graph --decorate --oneline -5`: your three commits sit on top of `main`.

### Phase 1 (solo): whodunnit, then a focused commit

First return to a clean `main` and delete the warm-up branch:

```bash
git switch main
git branch -D we-do-greeting-polish
```

**Whodunnit? (1-4)**

1. Open `sample-app/app.py` and find the line inside `farewell()` promising it's *"definitely safe to ship."*
2. Run `git blame sample-app/app.py`. Every line shows its **commit, author and date**. A `^` before the SHA: the line dates from the first commit.
3. **Who wrote that line?** Read the author off the blame output. Anyone you recognise?
4. Read the full story of those lines: `git log -p -L :farewell:sample-app/app.py`.

**Focused commit and gate (5-7)**

5. Add a line to `sample-app/README.md` with the **literal words "lab participant"** and your name, e.g. `Lab participant: Ada Lovelace`: the gate greps for those words. Commit it with a clear message.
6. Compare `git ls-tree HEAD~1 sample-app/` with `git ls-tree HEAD sample-app/`: only the `README.md` blob SHA differs; the `app.py` blob and the `tests/` tree are identical.
7. **The gate.** Run `scripts/verify-lab.sh`: it must print a green check. Run it **now**, before Phase 2.

### Phase 2 (solo): branch, merge and rebase

**Part A: tag your starting point, then make three clean commits.**

1. On `main` (which now includes your Phase 1 commit), tag the current commit `BASE`: `git switch main && git tag BASE`. A tag stays put while `main` moves, so `git reset --hard BASE` brings you back here in Parts B and C.
2. `git switch -c feature/greeting-tweaks`, then run `scripts/seed-messy-state.sh`. `git status` shows three changed files.
3. Use `git add -p` to make **three separate commits**, each containing **one** of the three changes, with a sensible message. Lumped everything into one commit? `git reset HEAD~1` and redo: it also unstages, so `add -p` has hunks to offer.

**Part B: merge diverged branches.**

4. Put one **unrelated** commit directly on `main`: `git switch main`, append a line to `docs/why-version-control.md` (a file neither Phase 1 nor the seed touches) and `git commit -am "chore: unrelated note on main"`. The branches have **diverged**: no fast-forward possible.
5. `git merge feature/greeting-tweaks -m "Merge feature/greeting-tweaks"` records a **merge commit**.
6. `git cat-file -p HEAD` lists **two `parent` lines**. `git log --graph --decorate --oneline --all` shows the diamond where the branches rejoin (at the top; the course repo's own history continues below it).
7. **Sketch the graph in `NOTES.local.md`** and keep it for Part C.

**Part C: rebase instead.**

8. Still on `main`: `git reset --hard BASE` drops Part B's merge **and** its note commit. **Redo the note commit** (append another line to `docs/why-version-control.md`, `git commit -am "chore: unrelated note on main"`), or the rebase has nothing to do.
9. `git switch feature/greeting-tweaks && git rebase main`. The three feature commits now sit on top of the new `main` tip with **new SHAs**, and no merge commit.
10. `git switch main && git merge feature/greeting-tweaks`: this fast-forwards.
11. Compare `git log --graph --decorate --oneline --all` with your Part B sketch: the same three feature commits, in a straight line instead of a diamond.

### Done?

- `scripts/verify-lab.sh` printed a green check before Phase 2.
- Part B: `git cat-file -p HEAD` showed two parents, and the sketch is in `NOTES.local.md`.
- Part C: `git log --graph --decorate --oneline --all` shows the three feature commits in a straight line on `main`.
- Nothing pushed: `main` on your fork is unchanged.

## Stretch challenges `[OPTIONAL]`

Only if you finish the two phases early.

**1. Rebase through a conflict.** After Part C, `main` and `feature/greeting-tweaks` point at the
**same commit**. Diverge them again first, then make `main` collide with the feature's docstring commit:

```bash
# 1: pull main back behind the feature branch
git switch main
git reset --hard HEAD~3     # the 3 feature commits leave main but stay on feature/greeting-tweaks

# 2: edit the same spot the feature's docstring commit touches
#    (the python block below does it for you, or make the edit by hand)
python3 - <<'PY'
from pathlib import Path
p = Path("sample-app/app.py")
t = p.read_text()
t = t.replace(
    '    message = f"Hello, {name}!"',
    '    # CONFLICT BAIT: main and your feature branch both edit greet()\n'
    '    message = f"Hello, {name}!"',
)
p.write_text(t)
PY
git commit -am "main: add a comment inside greet()"
```

Then `git switch feature/greeting-tweaks && git rebase main`: the feature commit that added a docstring to `greet()` touches the same spot, so Git halts with a conflict. Open `sample-app/app.py`, keep both the comment and the docstring, delete the markers, `git add sample-app/app.py`, then `git rebase --continue` (an editor opens with the commit message: save and close it). Confirm linear history with `git log --graph --decorate --oneline --all`. To bail out: `git rebase --abort`.

**2. Be `git diff`, by hand.** Pick two adjacent commits you made yourself, e.g. `HEAD~1` and `HEAD`. Using only `git ls-tree -r` and `git cat-file -p`: which files exist in one but not the other? For files in both, which blob SHAs differ? For a changed file, print both blobs and spot the changed lines. Then run `git diff HEAD~1 HEAD`: it should match.

**3. Cherry-pick one commit.** Copy a **single** commit from a branch onto `main`. (Did Stretch 1? Pick the **README (Run me)** or **test** commit: Stretch 1's rebase rewrote the docstring commit so it now expects the conflict-bait comment, and picking it onto `BASE` would conflict again.)

```bash
git switch main && git reset --hard BASE    # main is behind your feature work again
git log --oneline feature/greeting-tweaks   # pick one commit's SHA

git cherry-pick <SHA>        # replays just that change onto main as a new commit
git log --oneline -2         # same change, NEW SHA
```

`feature/greeting-tweaks` keeps its original commit.

## Wrap-up and questions (15 min)

- Which of the things Git does for you would help your team most?
- One thing that surprised you about how Git stores files.
- Where would your team prefer **merge** over **rebase**, and why? Are there situations where the opposite is true?
- If a teammate committed straight to `main` and pushed it: what do they do *now*?
- Which commands do you want to alias? (e.g., `git lg` for `log --graph --decorate --oneline --all`)

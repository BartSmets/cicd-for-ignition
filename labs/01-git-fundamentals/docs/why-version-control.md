# What version control gives you

Reference reading for the start of the Lab 01 teaching deck ("What Git does for you").

## Four things Git gives you

**1. History.** Every change is recorded with author, timestamp and a message. You can answer "who changed this line, when, and why" in seconds.

**2. Blame.** `git blame` shows the commit that last touched each line. It's how you reconstruct the reasoning behind code you didn't write.

**3. Branching.** Several people work on different things at the same time, each on a branch, without stepping on each other's files. Merging brings the work back together when it's ready.

**4. Safe undo.** Every commit is a checkpoint, so you can always get back to a known good state.

## Distributed

Every clone is a full copy of the repository, including all history. You commit, branch and inspect history on your own machine, even offline. The server (GitHub, GitLab, Bitbucket) is one copy that everyone agrees to push to and pull from.

On GitHub you fork a repo (your own copy on the server), clone your fork, make changes, and propose them back through a pull request.

## Ignition projects are files

Ignition projects and configuration are files, so they go in Git like any other code. A gateway backup is one snapshot of everything: no per-change history, no blame, no parallel work, and no review before a change goes live. Git gives you all four. From Lab 02 on we version real Ignition projects; Lab 01 uses a tiny Python app so the Git mechanics stand on their own.

## Further reading

- [Pro Git book](https://git-scm.com/book/en/v2): free, comprehensive, the canonical reference
- *Git from the Bottom Up* by John Wiegley: a long-form walk through Git's object model

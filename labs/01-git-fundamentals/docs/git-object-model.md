# Git's object model: cheat sheet

Reference reading for the object-model part of the Lab 01 teaching deck. Keep this open while you work through the You-do.

## The four object types

Everything in `.git/objects/` is one of four object types:

| Type | What it is | Points to |
|---|---|---|
| **blob** | The raw contents of a file. No filename, no permissions. | nothing |
| **tree** | A directory listing: names, permissions, and the blob or tree SHA for each entry | blobs and other trees |
| **commit** | A snapshot: one tree, its parent commit(s), the author and a message | one tree + zero or more parent commits |
| **tag** | An annotated tag: a name, who tagged, when, and a message | one commit |

`.git/objects` is a **key-value store**: the **key** is a hash of the content, the **value** is the content itself. `git cat-file -p <key>` prints the value. Two identical files anywhere in the repo have the same blob SHA, so the content is stored once.

## The relationships

```
commit  ──tree──▶  tree  ──blob──▶  blob ("Hello, world!")
   │                  │
   │                  └──tree──▶  tree  ──blob──▶  blob (test code)
   │
   └──parent──▶  commit  ──tree──▶  ...
```

A commit is *one* snapshot. To see what changed between two commits, Git walks both trees and compares blob SHAs: that is what `git diff` does.

## The commands that show you the objects

| Command | What it does |
|---|---|
| `git cat-file -p <SHA>` | Print an object: a commit, a tree or a blob |
| `git ls-tree HEAD sample-app/` | A tree's entries: mode, type, SHA, name |
| `git ls-tree -r HEAD sample-app/` | The same, recursing into sub-trees |

## HEAD, branches and the index

- **HEAD** points to your current branch (`ref: refs/heads/main`). It decides where the next commit attaches.
- **Branches and tags are refs**: named pointers to a commit. `refs/heads/main` is a branch, `refs/tags/v1.2` a tag. A branch moves forward as you commit; a tag stays put.
- **The index** (the staging area) is the draft of your next commit. `git add` updates the index; `git commit` turns it into a new commit object.

All three are pointers or snapshots into the same object graph. `git reset` moves the current branch to another commit and, depending on `--soft`, `--mixed` (the default) or `--hard`, also resets the index and your files.

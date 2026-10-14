# The production gateway: a real, shared, public deploy target

Reference reading for Lab 07. Short on purpose: this page tells you what the
production gateway is and how your pipeline reaches it. How the server itself
is built and operated lives with Mustry.

## 1. What it is

Throughout the labs you deployed to gateways on your own laptop. Lab 07 ends
differently: your releases ship to **Mustry's live Oatmakers demo**, a real
Ignition 8.3 gateway on a real server with a public address. Customers see it.
Mustry staff deploy to it the same way you do today.

|  |  |
|---|---|
| Gateway | `oatmakers-site-7` |
| Web address | https://cloud.mustrysolutions.com |
| Repo | [`Mustry-Solutions/demo-oatmakers`](https://github.com/Mustry-Solutions/demo-oatmakers) (public) |
| Deploy trigger | a merged change to `release.yaml` on `main`, nothing else |
| Your access | the public Perspective pages, and the `Deploy` workflow logs in the Actions tab |

Your project is at `https://cloud.mustrysolutions.com/data/perspective/client/<yourname>/`
once it is pinned; the shared demo is at `/data/perspective/client/oatmakers/`.

## 2. How a release reaches it

The same way your lab gateways were reached, with one extra indirection:

- **`release.yaml` names what runs.** Each line pins a project to a tag
  `<project>@vX.Y.Z`. CI rejects a pin whose tag does not exist or is not on
  `main`, so the tag always comes first, on the merged `main`.
- **The `Deploy` workflow makes the file true.** It runs only when a merge
  changes `release.yaml`, on a self-hosted runner next to the gateway,
  `runs-on: [self-hosted, demo-oatmakers]`. Nothing needs inbound access to
  the server.
- **What ships:** every pinned project, from its own tag; and the gateway
  payload (gateway config, module manifest, third-party modules, JARs,
  migrations) from the `oatmakers` pin. Migrations run first, then the files
  are copied in and the gateway is asked for an authenticated scan (the
  lab 04 mechanism). A module or JAR change restarts the gateway for a minute
  or two.
- **What never ships:** the gateway's own identity, users and API keys. They
  belong to that one gateway and are never in the repo.
- **Secrets:** the database password reaches the gateway as a file the
  file secret provider reads (lab 06's ladder). Its value lives only on the
  server: not in git, and not in a GitHub secret either.
- **Rollback** is `git revert` of the release PR: the file goes back, the same
  workflow makes the old pins true again.

## 3. Ground rules

- **No credentials in Git.** Same iron rule as lab 06; on a public repo a
  leaked secret is everyone's problem the minute you push.
- **You do not need the admin login.** You verify through the public pages
  and the workflow logs. If something needs a gateway status page, ask: the
  instructor shares access in the chat when it is needed. If your deploy
  cannot do something without admin rights, that is a design signal:
  pipelines deploy with scoped tokens, not with someone's login.
- **It is a shared, live demo.** Name your project after yourself, put your
  screens, tags and tables under your name or `Course`, and do not touch
  other people's projects or the demo's own screens.
- **One release PR at a time**, and announce a release that restarts the
  gateway. The full etiquette is in
  [`exercises/lab.md`](../exercises/lab.md#rules-for-a-shared-live-demo).

## 4. Why you cannot just log in and click (and why that is the lesson)

The server accepts key-only SSH from Mustry, exposes only SSH, HTTP and HTTPS,
and the gateway sits behind a TLS reverse proxy; it never faces the internet
directly. The gateway's own server stack is deployed the same way you deploy
projects: from a Git repo, through a pipeline, with secrets kept out of
version control. The infrastructure under Lab 07 practices what the
course preaches. Curious how it is built? Ask us for a walkthrough after the
course.

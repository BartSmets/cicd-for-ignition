# Self-hosted runners: cheat sheet

Reference reading for Part 3 (self-hosted runners).

## How a runner works

A GitHub Actions runner is a lightweight agent. It registers with GitHub using a token,
then polls GitHub for assigned jobs. When a job is assigned, the runner downloads the
workflow definition, executes the steps on the host machine, and returns the logs. GitHub
never connects inbound to the runner: the runner only polls outbound. A runner is
registered to a repo, an organization or an enterprise.

## When you need one

GitHub-hosted runners are fine for almost everything. You need self-hosted when one of
these is true:

1. **Network isolation.** The thing you deploy to is behind a firewall: an on-prem
   Ignition gateway, a PLC network, a private database, an internal artifact registry.
   GitHub-hosted runners can't reach them.
2. **Compliance or data residency.** Builds must run on infrastructure your organization
   controls.
3. **Real hardware access.** Testing against a physical PLC, an OPC UA server or a specific
   device.
4. **Cost at very high volume.** Rarely relevant for small teams.

Otherwise, stay on GitHub-hosted: a runner host is a machine you own, patch and monitor.

## The security model

A self-hosted runner has full filesystem access on its host, whatever network access and
cached credentials the host has, and executes arbitrary code from any job assigned to it.

**The one rule:** never pair a self-hosted runner with a public repo that accepts PRs from
forks. A malicious PR can change a workflow to exfiltrate secrets, install a backdoor or
pivot to other systems on your network.

**Guardrails:**

- **Ephemeral runners:** destroyed after every job, no persistent state.
- **Private repos only**, and approval for PRs from first-time contributors.
- **Network-isolate the runner:** its own subnet, only the outbound access it needs.
- **No production credentials on the host:** short-lived tokens per job (OIDC).

## Lifecycle

1. **Register:** a registration token (from the GitHub UI or API) is exchanged for a
   runner credential, and the runner starts polling.
2. **Poll:** every few seconds, "any jobs for me?"
3. **Execute** the steps and **return the logs**.
4. **Wait or exit:** long-lived runners keep polling; ephemeral runners exit after one job.
5. **De-register:** remove it from GitHub *and* stop the host process. Clean up lingering
   "Offline" runners on the Runners settings page.

## Setup options

### Docker-based ephemeral (what the lab uses)

```bash
# a short-lived registration token, minted with your existing gh login
RUNNER_TOKEN=$(gh api -X POST "repos/<you>/<repo>/actions/runners/registration-token" --jq .token)

docker run -d --rm \
  --name my-runner \
  -e REPO_URL="https://github.com/<you>/<repo>" \
  -e RUNNER_TOKEN="$RUNNER_TOKEN" \
  -e LABELS="self-hosted,local-lab03" \
  -e EPHEMERAL=true \
  myoung34/github-runner:latest
```

One command, one container, gone after one job. Fine for development and labs.

### Installed on a host

*Settings → Actions → Runners → New self-hosted runner* gives the commands: download the
runner, run `config.sh` to register, `run.sh` to start polling, usually wrapped in a
systemd unit or a Windows service. This is what most production setups look like.

### Kubernetes or auto-scaling VMs

Actions Runner Controller runs runners as Kubernetes pods; other tooling starts a fresh
cloud VM per job. For high-volume teams.

## Common gotchas

- **Tools.** A self-hosted runner only has what you install. If a workflow assumes
  `shellcheck` is on the PATH, install it on the host or in the workflow.
- **Disk fills up** on long-lived runners (Docker images, caches). Add cleanup or use
  ephemeral runners.
- **Hangs.** Set `timeout-minutes:` on every job.
- **Re-registering** creates a new runner; the old one lingers as "Offline".

## Ignition-specific notes

- **Where the runner sits:** on a build host with network access to the target gateways,
  not on the gateway server itself.
- **Permissions:** use a dedicated service account, not your personal credentials.

You'll run a real Ignition deploy job on a self-hosted runner in Labs 04 and 06 (Lab 05
has no runner).

## Further reading

- [GitHub docs: self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Security hardening for self-hosted runners](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#hardening-for-self-hosted-runners)
- [`myoung34/docker-github-actions-runner`](https://github.com/myoung34/docker-github-actions-runner): the image the lab uses
- [Actions Runner Controller](https://github.com/actions/actions-runner-controller): Kubernetes-native runners

# axel

**axel is a way of building a project with two AI agents instead of one.** One
of them writes — code, documentation, whatever the project is made of — and a
second, from a different vendor, reviews every change and runs your tests to
check for itself instead of taking the first one's word. Everything they decide
is written into your repository as they go, so a fresh session picks up from the
repo rather than from an empty chat. At the end of the run you authorised, axel
stops and waits for your approval; the next run starts both agents with fresh
contexts, so nothing rides forward on a summary nobody checked. No change is
ever signed off by the agent that wrote it. This repository was built that way,
by itself.

## Why would I use it?

axel starts from a premise: an agent left alone is both the author and the judge
of its own work, and it grades generously. It also forgets: close the session
and the reasoning behind every decision goes with it, so the next one
re-litigates settled questions or quietly contradicts them.

axel answers both with structure rather than with a better prompt. **A different
vendor's model reviews every change**, and it reviews by executing: it works on
a copy of your repo pinned to the commit under review, where it can run your
tests instead of only reading the diff. The two agents **do not share a context
window**, so the reviewer never inherits the reasoning that produced the work —
it receives the argument and the evidence, and checks them against the repo.

At commit `b0bdf4d` the review log held **88 rounds** — a round is one pass of
the review — of which **59** sent the work back, and **not one of the 18
recorded cycles** was approved on its first round; the 29 approvals are
milestones, not features. Every figure, its cut, and the command that re-derives
it are in [docs/metrics.md](docs/metrics.md).

What that looks like in practice — a real request, the gate, a rejection that
caught a genuine bug, and the human OK, all reconstructed from this repo — is in
[what a session actually looks like](docs/session.md).

It has also been installed into an unrelated active repo that had its own
documentation. Honest scope: one repo, same author, and an adoption rather than
a full review loop. It answers "does this work somewhere that isn't axel" and
nothing more.

And the memory is the repo, not the chat. Every commit updates the documents —
if it was not recorded, it did not happen — so a new session rebuilds by reading
a handful of files. The reasoning stays recoverable without depending on a chat
window that closes; you still have to read it.

## How do I install it?

Requirements first, because finding them out afterwards is worse:

- **Claude Code and Codex CLI** — two subscriptions, from two different vendors.
  That is the cost of cross-vendor review and it is deliberate: a model
  reviewing itself is not a reviewer.
- **macOS** — `scripts/awake.sh` and the wrapper around each review call use
  `caffeinate`. Both degrade cleanly where it is absent, and every recorded run
  of axel has been on macOS — so treat anything else as untested rather than as
  unsupported.
- **git, `python3`, `curl`** — the destination must be a git repo with a clean
  tree.
- **Reviews are slow.** At `xhigh` effort a round can take more than 10 minutes.

This is expensive and unhurried on purpose. Better to know now than after
installing.

Standing inside the destination repo:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash
```

**If your `.gitignore` ignores `build/`** — GitHub's Python and Gradle templates
both do, out of the box — the install is refused, because the `/build` skill
lives in `.claude/skills/build/`. One line in your `.gitignore` fixes it, and
the trap is that `!.claude/` is *not* that line:
[known issues](docs/install.md#known-issues).

Everything else — explicit forms, forks, the `~/.axel` cache, exit codes, what
to do if you installed into the wrong repo, and the full procedure **for
agents** told to "install axel following this URL" — is in
[docs/install.md](docs/install.md).

## How do I use it?

Open Claude Code in the repo and use any of these. You do not have to learn
them: a request in plain language is routed by context, and it never starts work
without hitting a confirmation point first.

| Command | What it does |
|---|---|
| `/design` | Ping-pong ideas with you, then consolidate the design and close it with a review loop. |
| `/plan` | Write the prioritised feature plan, in an order agreed between generator and reviewer. |
| `/feature` | Take the next feature: start gate → detailed spec → implement, iterating with review → RECAP → your OK. |
| `/build` | Pipeline: chain the phases a request needs, behind one gate and one consolidated OK. |
| `/adopt` | Close an adoption in a repo that already had its own docs. |
| `/status` | Say where things stand. Pure read, changes nothing. |
| `/recap` | Checkpoint on demand: what happened since the last OK, and what comes next. |

The four phase commands — `/design`, `/plan`, `/feature` and `/build` — run the
same loop underneath. `/adopt` closes an adoption, `/recap` writes a checkpoint
into the repo, and `/status` is the only one that just reports. In that loop the
first agent writes and commits; the reviewer takes that range of commits, checks
it against the design and the plan, and either asks for changes or approves; the
first one fixes what it accepts and argues back where it disagrees. That repeats
until they agree.

It stops for you in two places. If five rounds pass without converging, it stops
and hands you both positions so you can break the tie. And at the end of the run
you authorised, it writes up what happened and does not continue until you
answer. The session is also the control panel: you can open it from wherever you
are and redirect it mid-run, and what you say outranks whatever it was doing.

The complete command reference and the diagram of how the phases chain are in
[docs/install.md](docs/install.md#the-commands-in-full); the contract the two
agents hold each other to is in
[docs/design/review-contract.md](docs/design/review-contract.md).

## The essentials

Materially, axel is markdown and two shell scripts. It adds no dependencies to
your project and there is nothing to import; deleting it is as easy as
installing it.

### What it is not

- **Not a framework.** No packages, no lock-in, readable in an afternoon — and
  that is the point rather than an apology.
- **Not cheap.** Two paid subscriptions, and review rounds measured in tens of
  minutes.
- **Not autonomous.** It stops and waits for you at every checkpoint, by design.
- **Not proven at scale.** One repo built itself with this, and one external
  install exists. That is the entire evidence base, and it is above.
- **Not English underneath.** The storefront is English; the method documents,
  the commit messages and the prose the installer writes into your repo are
  Spanish. The machinery is language-agnostic — that text just has not been
  translated yet: [declared, not hidden](docs/install.md#language).
- **Not a rubber stamp.** The reviewer runs the tests rather than only reading
  the diff, and the figures above are the argument. What it cannot promise is
  catching everything.

### Links

- [AGENTS.md](AGENTS.md) — the process and the rules, loaded by both agents
- [docs/STATUS.md](docs/STATUS.md) — where this repo stands right now
- [docs/DESIGN.md](docs/DESIGN.md) — the design ·
  [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) — the plan
- [docs/design/review-contract.md](docs/design/review-contract.md) — the
  generator↔reviewer contract
- [docs/session.md](docs/session.md) — what a session actually looks like,
  rendered from this repo
- [docs/install.md](docs/install.md) — the install manual
- [docs/metrics.md](docs/metrics.md) — the numbers on this page, with the
  command behind each
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to give feedback, and what this round
  is looking for
- [LICENSE](LICENSE) — MIT

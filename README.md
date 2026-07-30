# axel

**A two-agent development loop: Claude Code writes, Codex reviews, and neither gets to approve its own work.** This repo built itself with it.

At commit `b0bdf4d`: **88 logged review rounds · 59 rejections · zero first-round approvals.**

A *round* is one pass of the review contract — not one feature. The 29 approvals are **milestones**
(a detailed spec, an implementation step, a plan cycle), so there are more approvals than features;
counting them as features would be exactly the sloppiness that makes numbers like these worthless.
88 is what the round log covers since instrumentation began on day two; the full history is 123,
with the earlier 35 recovered from a separate source. *Coming in feature 14: the metrics document
that publishes the snapshot and the exact command behind every figure — not yet published, so for
now these numbers are only as good as this repo's git history, which you can read.*

## The problem

An agent left alone is both author and judge, and it grades generously. It also forgets: close the
session and the reasoning behind every decision goes with it, so the next session re-litigates
settled questions or silently contradicts them.

axel addresses both with structure rather than with a better prompt. **A different vendor's model
reviews every change** and can run your tests to check for itself. **The repo is the memory** — a
new session reconstructs everything by reading four files. And **you approve at checkpoints**, not
at every step.

## What a session actually looks like

In axel the chat is disposable and the repo is the memory, so **there is no session transcript to
capture** — publishing a chat log that looked reconstructed, in a project whose whole pitch is
auditability, would be the worst thing we could do. What follows is rendered from the repo instead.
Every line traces to a commit, a ledger entry or a review log. The originals are in Spanish; the
English is a translation, and the source is named so you can check.

### One run, end to end — [pipeline 2026-07-29 (2)](docs/implementation/pipeline-2026-07-29-2.md)

**1 · A request, with no command typed.** Recorded verbatim in the run's ledger:

> «Que la skill `/adopt` cierre reportándole al humano el **inventario completo de archivos que tocó**, no solo la narrativa de las decisiones que le parecieron importantes.»
>
> *"Make the `/adopt` skill close by reporting the complete inventory of files it touched, not just the story of the decisions it found interesting."*

**2 · A gate, then one authorisation.** axel proposed a route, asked one question, and waited. The
human's answer, quoted in the ledger:

> «a) ok con tu recomendacion · b) dejalo sin registrar» — *"a) ok, go with your recommendation · b) leave it unrecorded"*

**3 · The reviewer catches something real.** Round 1, from the feature's
[review log](docs/implementation/12-adopt-close-report.md):

> «El camino multicommit podía omitir archivos en silencio. Cierto y grave: `git diff <base>..HEAD` es el **efecto neto entre extremos**, no la unión de lo tocado — un archivo modificado y restaurado, o el path intermedio de un `A → B → C`, desaparecía sin dejar rastro, que es justo la falla del criterio (a).»
>
> *"The multi-commit path could silently omit files. True, and serious: `git diff <base>..HEAD` is the net effect between endpoints, not the union of what was touched — a file modified and then restored, or the middle step of an `A → B → C`, vanished without a trace, which is exactly the failure the criterion existed to prevent."*

That is a logic bug in the deliverable, caught by reading the diff.

**4 · Correction, then agreement.** Fixed in `f85a033`, the round-2 commit. Five more rounds of
narrowing followed — six in all after that first rejection — and the reviewer approved at `886fe4f`
in round 7.

**5 · A checkpoint, and a human OK.** STATUS moved to "waiting for OK" in `eabd92f`, the turn ended,
and nothing else happened until the human answered. The OK is quoted in the ledger's closing section
and recorded in `39b377e`:

> «OK»

### Does it work outside axel? — one data point

axel was installed into an unrelated active repo with 185 commits and its own documentation. Commit
`846308f` installed 20 files there; because the repo already had docs this ran as an **adoption**,
and `4908bfb` closed it with `/adopt`, mapping 8 files onto the convention. Commit `98c70c0` is that
repo applying the `build/` workaround described below.

Honest scope: **one repo, same author, and an adoption rather than a full review loop.** It answers
"does this work somewhere that isn't axel" and nothing more.

## Requirements, honestly

- **Claude Code and Codex CLI** — two subscriptions, from two different vendors. That is the cost of
  cross-vendor review and it is deliberate: a model reviewing itself is not a reviewer.
- **macOS** — `scripts/awake.sh` and the wrapper around each review call use `caffeinate`. Both
  degrade cleanly where it is absent: `awake.sh` reports it and returns without error, and reviews
  run uncaffeinated. That is what has been verified, and every recorded run of axel has been on
  macOS — so treat anything else as untested rather than as unsupported.
- **git, `python3`, `curl`** — the destination must be a git repo with a clean tree.
- **Reviews are slow.** At `xhigh` effort a round can take more than 10 minutes.

This is expensive and unhurried on purpose. Better to know now than after installing.

## Install

Standing inside the destination repo:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash
```

**If your `.gitignore` ignores `build/`** — GitHub's Python and Gradle templates both do, out of
the box — the install is refused, because the `/build` skill lives in `.claude/skills/build/`. One
line in your `.gitignore` fixes it, and the trap is that `!.claude/` is *not* that line:
[known issues](docs/install.md#known-issues).

Everything else — explicit forms, forks, the `~/.axel` cache, exit codes, what to do if you installed
into the wrong repo, and the full procedure **for agents** told to "install axel following this URL"
— is in [docs/install.md](docs/install.md).

## The commands

Open Claude Code in the repo and use any of these:

| Command | What it does |
|---|---|
| `/design` | Ping-pong ideas with you, then consolidate the design and close it with a review loop. |
| `/plan` | Write the prioritised feature plan, in an order agreed between generator and reviewer. |
| `/feature` | Take the next feature: start gate → detailed spec → implement, iterating with review → RECAP → your OK. |
| `/build` | Pipeline: chain the phases a request needs, behind one gate and one consolidated OK. |
| `/adopt` | Close an adoption in a repo that already had its own docs. |
| `/status` | Say where things stand. Pure read, changes nothing. |
| `/recap` | Checkpoint on demand: what happened since the last OK, and what comes next. |

You do not have to learn them: a request in plain language is routed by context, and it never starts
work without hitting a confirmation point first. Full reference:
[docs/install.md](docs/install.md#the-commands-in-full).

## How it works

```
/design ─► DESIGN.md ─review─► RECAP ─► OK ─► /plan ─► IMPLEMENTATION.md ─review─► RECAP ─► OK
                                                              │
                 ┌────────────────────────────────────────────┘
                 ▼
        /feature (fresh session)
        start gate: summary ─► human confirmation
        detailed spec ─review─► implement ─commit─► review ─► … ─► APPROVED
                 │
                 ▼
              RECAP ─► human OK ─► next /feature (fresh session)
```

Inside a feature: change → commit → review → fix or argue back → commit → review, until
`VERDICT: APPROVED`. Five rounds without convergence stops the loop and hands you both positions to
break the tie. The reviewer works in a **worktree snapshot pinned to the commit under review**, where
it can run tests and builds to verify on its own. Contract:
[docs/design/review-contract.md](docs/design/review-contract.md).

Five principles hold it together:

1. **State lives in the repo, not the chat.** Any session rebuilds from `AGENTS.md` → `docs/STATUS.md` → design and plan.
2. **The Claude Code session is the process and the control panel** — you can open it remotely and redirect at any point.
3. **Generator and reviewer are separate, each with its own context**, renewed between features.
4. **The human OK is the context boundary.** RECAP → OK → fresh sessions.
5. **Docs are updated in every commit.** If it was not recorded, it did not happen.

## What this is not

- **Not a framework.** It is a pile of markdown and two shell scripts. It adds no packages to your
  project and there is nothing to import — the requirements above are the two agent CLIs and stock
  Unix tools. No lock-in, readable in an afternoon, and that is the point rather than an apology:
  deleting it is as easy as installing it.
- **Not cheap.** Two paid subscriptions, and review rounds measured in tens of minutes.
- **Not autonomous.** It stops and waits for you at every checkpoint, by design.
- **Not proven at scale.** One repo built itself with this, and one external install exists. That is
  the entire evidence base, and it is above.
- **Not English underneath.** The storefront is English; the method documents and commit messages are
  Spanish, and so is the prose the installer writes into your repo. The machinery is
  language-agnostic — that text just has not been translated yet. Declared, not hidden:
  [docs/install.md](docs/install.md#language).
- **Not a rubber stamp, and the numbers are the argument.** Zero of 23 cycles were approved on their
  first round. The reviewer runs the tests; it does not only read the diff.

## Links

- [AGENTS.md](AGENTS.md) — the process and the rules, loaded by both agents
- [docs/STATUS.md](docs/STATUS.md) — where this repo stands right now
- [docs/DESIGN.md](docs/DESIGN.md) — the design · [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) — the plan
- [docs/design/review-contract.md](docs/design/review-contract.md) — the generator↔reviewer contract
- [docs/install.md](docs/install.md) — the install manual
- [LICENSE](LICENSE) — MIT

> **Coming in feature 14, and deliberately not linked yet:** the **reviewer metrics document** — the
> versioned round-log snapshot, the cut commit, and the exact command behind every figure on this
> page — and **how to give feedback**, a `CONTRIBUTING.md` plus issue templates. Both are named here
> in prose on purpose: this page ships with zero broken links, and these two become links when the
> artefacts exist.

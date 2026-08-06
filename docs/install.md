# Installing axel

The install manual: the supported paths, the main failure modes, and the known issues. If you are still deciding whether axel is for you, read the [README](../README.md) first —
this page assumes you already decided.

This document is in English because its audience is the same person the README speaks to, one step
further along. The method documents (`AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`,
`docs/STATUS.md`) are in Spanish, and so is the prose axel installs into your repo. See
[Language](#language) below.

## Requirements

| What | Why | If missing |
|---|---|---|
| **Claude Code** | the generator: writes, commits, runs the loop | no loop |
| **Codex CLI** | the reviewer: `scripts/review.sh` invokes it as a subprocess | no reviews — the loop's whole point |
| **git** | the destination must be a git repo with a **clean tree** | install refused |
| **python3** | validates the permissions policy before writing anything | install refused (fail-closed: an unprovable policy is not installed) |
| **macOS** | `caffeinate`, used by `scripts/awake.sh` and around each Codex call | see below |
| **`curl`** | only for the remote one-liner | use a local clone instead |

Two subscriptions from two different vendors. That is the cost of cross-vendor review, and it is
deliberate: a model reviewing itself is not a reviewer.

**Outside macOS**, two things are known to degrade cleanly: `scripts/awake.sh` prints
`caffeinate no disponible (no es macOS): nada que hacer` and returns without error, and `review.sh`
calls Codex directly instead of wrapping it in `caffeinate`. What you lose is the guarantee that the
machine stays awake through a long unattended run.

That is the extent of what has been verified, and every recorded run of axel has been on macOS. The
rest — the installer, the loop, the review contract — is untested elsewhere rather than known to
work.

**Review rounds are slow.** At `xhigh` effort a round can take more than 10 minutes, which is why
the generator launches them in the background. This is a declared property of the setup, not a bug
to wait out.

**On a laptop, `caffeinate` has a physical limit**: closing the lid still sleeps the machine, unless
it is on power *and* driving an external display. For a long unattended run — and these runs are
long — leave the lid open or dock it.

## Install

### Quick install

Standing inside the destination repo, with no prior clone of axel:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash
```

If your destination's `.gitignore` ignores `build/` — as GitHub's Python and Gradle templates do —
this will refuse to install. That is [known issue 1](#1-the-build-collision); it takes one line to
fix.

### What the defaults assume

With no arguments the installer **assumes two things and announces both before touching anything**:
the source is the canonical axel repo, and the destination is the toplevel of the git repo you are
standing in. Check where you are first (`git rev-parse --show-toplevel`): that repo, with a clean
tree, is what gets modified. Outside a git repo the run is refused without writing anything. A real
run announces them like this:

```
── axel bootstrap · fuente: https://github.com/alexweil/axel (por defecto) · destino: /path/to/your/repo (por defecto: toplevel del cwd) ──
── axel bootstrap · remoto: https://github.com/alexweil/axel · cache: /Users/you/.axel (main @ 88020af) ──
── axel installer · modo: initial · destino: /path/to/your/repo · axel 88020af ──
```

### Explicit form

When the destination is somewhere else, or the source is a fork:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash -s -- --from https://github.com/alexweil/axel <destination>
```

### From a local clone

With a clone of axel on disk, the classic mode does the same thing without touching the network.
Here the destination stays **mandatory**: the source is the clone in front of you, so assuming the
destination would add nothing.

```bash
scripts/install.sh /path/to/target-repo
```

### The `~/.axel` cache

The piped script only parses arguments, clones (or fast-forwards) a **cache of axel** in `~/.axel`
(override with the `AXEL_HOME` environment variable) and delegates the install to that clone's
`install.sh`. What gets installed is always versioned code from the cache, verified against the
remote commit. The cache is handled fail-closed: dirty, carrying local commits, diverged, on another
branch or another origin ⇒ refusal with instructions. Nothing is ever overwritten.

### Forks

A script downloaded from a fork and executed over stdin cannot know it came from a fork — there is
no `$0` and no provenance — so without `--from` it installs canonical axel. To install from a fork
use the explicit form `bash -s -- --from <fork-url> <destination>`, or export `AXEL_DEFAULT_REMOTE`.
The startup announcement always states which source it ended up using.

## Did it actually run?

**Every run ends with a line `── axel · fin: rc=N · …`.** If you do not see it, the only thing you
can conclude is that there is **no confirmed completion**. The most common cause is that `curl`
failed and `bash` received empty input, which returns 0 without executing anything — the pipe does
not propagate `curl`'s failure. But it can also be a run interrupted **after** it started writing,
so check the destination's `git status` before retrying.

For scripted use, this variant does propagate the transport failure:

```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash'
```

## If you installed into the wrong repo

The installer requires a clean tree and never commits, so everything it wrote **is exactly the
diff**. `git status --short` shows it, `git restore .` reverts what was modified, and `git clean -fd`
removes what is new — safe precisely because the tree was clean beforehand.

As an extra net: if the assumed destination turns out to be a clone of the source itself — running
the one-liner while standing inside axel — the run is refused and you are asked for an explicit
destination.

## What gets installed

**Machinery** (overwritten on every re-run, axel is the source of truth):

- `.claude/skills/` — the seven skills: `adopt`, `build`, `design`, `feature`, `plan`, `recap`, `status`
- `scripts/review.sh` — the reviewer wrapper
- `scripts/awake.sh` — keeps the machine awake through a run
- `docs/design/review-contract.md` — the generator↔reviewer contract
- `.claude/axel-policy.json` — the permissions policy
- `.claude/axel-install` — the install marker

**Seeds** (written only if absent, never overwritten):

- `AGENTS.md` and the `CLAUDE.md → AGENTS.md` symlink — the root context both agents load
- `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`
- `.claude/settings.json` — pre-approved permissions so the loop does not stall on confirmations

**Touched, not created**: `.gitignore` gains a `.claude/state/` entry if it lacks one. That is the
only edit to a file you already had.

A clean initial install writes 18 entries plus that `.gitignore` line.

## The three modes

No flags — the installer picks the mode from what it finds:

1. **Initial install** — the repo has no docs of its own. Machinery plus seeds, exit 0.
2. **Adoption** — the repo already has its own docs. Pre-existing docs and seeds are left
   **untouched**, the findings go to `docs/ADOPTION.md`, and you close it with `/adopt` in the
   destination. Exit 1. See [After an adoption](#after-an-adoption).
3. **Update** — re-running it. Machinery files are overwritten **even if you edited them**; your
   project's docs and settings are never touched.

The installer never commits: the diff is yours, to commit with your project's process.

## After an adoption

Adoption is the mode most likely to surprise you, so here is what you will actually see.

**The announced mode may say `initial` when what ran was an adoption.** This is
[known issue 3](#3-the-announced-mode-can-be-wrong). Trust the exit code and the presence of
`docs/ADOPTION.md`, not the announcement.

**Your repo will end up with four documents under two names.** If you already had `DESIGN.md` and
`IMPLEMENTATION.md` at the root, after the install you also have `docs/DESIGN.md` and
`docs/IMPLEMENTATION.md` — the seeds. Four files, two names, and nothing on screen tells you which
one is authoritative.

This is by design: seeds never overwrite anything, so the installer cannot merge your documents into
the convention on its own — that takes judgement about your project. **The answer is that neither is
authoritative yet**, and `/adopt` is what resolves it: it reads `docs/ADOPTION.md`, maps your
existing docs onto the convention with you, derives a real `STATUS.md` from the actual state of the
project, and deletes the handoff.

Run `/adopt` in the destination before doing anything else. It closes by reporting the **complete
inventory of files it touched**, derived from the commit rather than from what it remembers doing,
split into what was mechanical and what you should ratify.

## Exit codes

| Code | Meaning | What to do |
|---|---|---|
| `0` | installed, nothing pending | review the diff (`git status`), commit it, run `/status` — or `/design` if the project starts from scratch |
| `1` | installed, pending items | review and commit the diff, then close the adoption with `/adopt` (findings in `docs/ADOPTION.md`) |
| `2` | refusal — **nothing was written** to the destination (the `~/.axel` cache may still have been created or updated) | fix the cause and retry |

One caveat on `2`: if the report says the installer was **interrupted** or **did not complete**, that
is not a clean refusal — check the destination's `git status` first, there may be a partial diff.

## The commands in full

Seven commands, installed as Claude Code skills. The README carries a one-line summary of each; this
is the complete reference. They also dispatch by context — you can describe what you want in plain
language and the right one is chosen — but a pending state always wins over a new request.

| Command | What it does | When to use it | Precondition |
|---|---|---|---|
| `/design` | idea ping-pong with you, consolidates `docs/DESIGN.md` and its deep-dives, closes with a review loop | the request needs **only** direction: rethinking or extending the design | stable state, or an open design cycle it re-enters |
| `/plan` | writes `docs/IMPLEMENTATION.md`: prioritised features whose order generator and reviewer agree on | the request needs **only** deciding what to do and in what order | a design worth planning from |
| `/feature` | the next feature: start gate, detailed spec, implementation iterating with review, RECAP, human OK | the request needs **only** implementing what the plan already contains | the feature exists in the plan |
| `/feature all` · `/feature NN..MM` | batch mode: several pending features in one run, a fresh subagent per feature, one consolidated RECAP | you want several features done back to back | the features are all `Pendiente` |
| `/build` | pipeline: chains the phases a request needs (design → plan → features) behind a single gate | the request crosses **two or more phases** | authorised by its gate; does not bypass a pending state |
| `/adopt` | closes an adoption: consumes `docs/ADOPTION.md`, maps pre-existing docs, derives the real STATUS | right after installing into a repo that had its own docs | `docs/ADOPTION.md` exists |
| `/status` | reads STATUS, the plan and the git log, and tells you where things stand | any question about state or progress | none — pure read, changes nothing |
| `/recap` | checkpoint on demand: what was done since the last OK, decisions, loop state, what comes next | you want a checkpoint now | **not** a query: it sets "waiting for OK" and commits |

### How the commands chain

The phases in one picture — where each command hands off, and where the run stops for you:

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

`/build` collapses that chain behind a single gate when a request needs more than one phase, and
`/feature all` runs several planned features back to back. Both still end at one human OK.

## For agents (Claude Code)

If you were told "install axel following this URL", this is the complete procedure.

1. **Preconditions**: the destination is a git repo with a **clean tree** (commit or stash first);
   `git`, `curl` and `python3` available. The destination is the repo **toplevel**:
   `git rev-parse --show-toplevel`.
2. **Run the one-liner** above. If you are certain you are standing in the destination repo, the
   short form with no arguments is enough (it assumes that toplevel and announces it). **If you are
   not sure, pass the destination explicitly** with
   `bash -s -- --from https://github.com/alexweil/axel <toplevel>` — the assumed destination is the
   only part of the command that depends on where you are standing. You do not need to clone axel:
   the command downloads and caches everything in `~/.axel`.
3. **Check the final line first**: a real run's output ends in `── axel · fin: rc=N · …`. If that
   line is absent there is **no confirmed completion** and the exit code tells you nothing about the
   install: most likely the download failed and `bash` got empty input (returns 0 without executing
   anything), but a run interrupted after writing leaves a partial diff — **check the destination's
   `git status` before retrying**, and use `bash -o pipefail -c '…'` if you want the transport
   failure to propagate.
4. **React to the exit code** — see [Exit codes](#exit-codes).
5. **From inside a Claude Code session**: the installed skills (`/status`, `/design`, `/adopt`, …)
   load hot and you can use them right away; the permissions in the seeded `.claude/settings.json`
   take full effect only in the **next** session — until then you may get confirmation prompts. The
   installer never commits: the commit is yours, with the destination's process.

## Audit before you run

The two-step path does exactly the same thing with the installer in plain sight. Clone axel
**outside** the destination (cloning inside would dirty the tree the installer requires clean) and
pass it the toplevel:

```bash
AXEL_SRC="$(mktemp -d)/axel" && git clone https://github.com/alexweil/axel "$AXEL_SRC" && "$AXEL_SRC/scripts/install.sh" "$(git rev-parse --show-toplevel)"
```

## Known issues

Three rough edges, all reproduced, none fixed yet. They are documented rather than worked around in
code because the fixes are out of scope for the current work — that is a decision, not an oversight.

### 1. The `build/` collision

**Symptom.** The install is refused before writing anything:

```
── preflight: 1 problema(s); no se escribió nada ──
rechazo: .claude/skills/build/SKILL.md: nacería ignorado por las reglas del destino; nada del instalador puede quedar fuera del diff
── axel · fin: rc=2 · rechazo del preflight (1 problema(s), nada escrito) ──
```

**Cause.** The `/build` skill lives in `.claude/skills/build/`, and `build/` is a common
`.gitignore` pattern. The preflight is behaving **correctly**: nothing the installer writes may fall
outside the diff. What is wrong is a directory name. No other skill collides.

*Two successively looser versions of this claim did not survive review, so here is the check pinned
to a commit you can re-run.* Templates from
[github/gitignore@`57286c3`](https://github.com/github/gitignore/tree/57286c3887203259752b747db94e6c3ad10ec53d),
each installed as the `.gitignore` of an empty repo containing `.claude/skills/build/SKILL.md`, then
asked directly instead of pattern-matched by eye:

```bash
#!/usr/bin/env bash
set -euo pipefail                        # a failed download must stop the run, not skew it
SHA=57286c3887203259752b747db94e6c3ad10ec53d
probe="$(mktemp -d)"; trap 'rm -rf "$probe"' EXIT
git init -q "$probe"; mkdir -p "$probe/.claude/skills/build"
touch "$probe/.claude/skills/build/SKILL.md"; cd "$probe"
for t in Python Gradle Node Java C Maven Go Rust; do
  rm -f .gitignore                       # no leftover from the previous template can survive
  curl -fsSL "https://raw.githubusercontent.com/github/gitignore/$SHA/$t.gitignore" -o tmpl \
    || { echo "FAIL: could not fetch $t" >&2; exit 1; }
  mv -f tmpl .gitignore                  # .gitignore exists only if the download completed
  printf '%-8s %s\n' "$t" "$(git check-ignore -v .claude/skills/build/SKILL.md || echo 'not ignored')"
done
```

The three guards are the point, not decoration. A first version of this script wrote each template
straight to `.gitignore` with no check, so a failed download left the **previous** template in place
and the loop happily attributed that result to the next one — reproduced with a bad SHA: `curl`
returned 56 and the script reported Node as ignoring `build/`, which is Python's rule, exiting 0.
Evidence that can fail open is not evidence. With `set -euo pipefail`, the `rm -f` and the
download-then-`mv`, a transport failure or a missing template aborts with a non-zero exit instead of
producing a plausible-looking matrix.


| Template | Ignores the skill? |
|---|---|
| **Python** | yes — `build/` |
| **Gradle** | yes — `**/build/` |
| Node | no — its `build/Release` does not match |
| Java · C · Maven · Go · Rust | no — no matching rule |

So the accurate statement is conditional: this bites you when your `.gitignore` ignores `build/`,
whether that came from a template or from your own hand. The table is a snapshot of that one commit,
not a claim about every ecosystem forever.

**Fix.** Add this to the destination's `.gitignore`, **after** the pattern that excludes it:

```
!.claude/skills/build/
```

**The trap, which is counterintuitive enough to state outright: `!.claude/` does not work.** Git will
not re-include a file if an intermediate parent directory was excluded, so the negation has to name
the directory itself. You can confirm which rule is responsible with
`git check-ignore -v .claude/skills/build/SKILL.md` — with `!.claude/` in place it still answers
`.gitignore:3:build/`. A broader `!.claude/**` also works, but it re-includes more than you need.

**Not fixed in this pipeline**, and deliberately not filed as a backlog item either — that was an
explicit decision, not an oversight. It is documented here because without this section the refusal
message is cryptic.

### 2. The dirty-tree refusal does not list the files

The installer refuses with `el árbol del destino no está limpio; commiteá o stasheá`, but it does not
tell you **which** files are dirty. Combined with the fact that `git stash` without `-u` leaves
untracked files alone — the most common case in an active repo — you can stash, still be refused, and
not understand why. Run `git status --short` yourself, and use `git stash -u` if the dirt is
untracked.

### 3. The announced mode can be wrong

The installer can announce `modo: initial` when what it actually performed was an **adoption**: it
detected pre-existing docs, wrote `docs/ADOPTION.md` and exited with code 1. Since axel documents
three modes, the announced one then contradicts the executed one. The visible consequence is covered
in [After an adoption](#after-an-adoption). Trust the exit code and `docs/ADOPTION.md`.

## License notice

axel is [MIT licensed](../LICENSE), and so is everything it installs into your repo.

**A pending non-compliance, stated plainly.** MIT requires that the copyright and permission notice
be included in all copies or substantial portions of the software. The installer copies skills,
scripts and the review contract into destination repos, and none of those files currently carries
that notice. This paragraph tells you the licence, which is useful — but a pointer that does not
travel with the payload is not the notice that has to travel with the payload. So: **not partial
compliance, an open gap.** Fixing it means changing the installer, which is out of scope for now.

We are not lawyers and this does not block anyone from using axel. It is recorded here so that "not
done" is a decision on the record rather than something nobody noticed.

## Language

Three planes, decided by audience rather than by location in the tree:

| Plane | Audience | Language |
|---|---|---|
| **Storefront** — `README.md`, `CONTRIBUTING.md`, `.github/`, this manual | someone discovering axel | **English** |
| **Method** — `AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`, commit messages | the two agents and the human operating *this* repo | **Spanish** |
| **Prose installed into your repo** — the skills, the review contract, the messages the scripts print, the four document templates | your project | **Spanish today — a declared limitation** |

The machinery itself is language-agnostic: it does not care what language your project works in. But
the text it installs has not been translated yet, and you should know that before installing. The
executable logic, the policy, `settings.json` and the symlink have no language at all.

## Tests

```bash
tests/install.sh   # the installer, end to end
tests/loop.sh      # the review loop
tests/lint.sh      # shellcheck over scripts/ and tests/
```

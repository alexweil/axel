# The numbers on the front page, and how to re-derive them

Every figure axel publishes about itself comes from here. This document says what
each one counts, where it comes from, and the exact command that produces it — so
you can check them instead of trusting them.

## What this is, and what it is not

It is a **dated photograph**, not a live counter. Every figure drawn from this
repository is cut at commit **`b0bdf4d`**, and the raw data at that cut is
versioned here as
[`metrics/rounds-log-b0bdf4d.tsv`](metrics/rounds-log-b0bdf4d.tsv).

Three rows are the exception and say so in the table: the **external-install**
figures are anchored to commits of a **different** repository, so they carry their
own SHAs and are not covered by this cut.

**The snapshot does not include the rounds of features 13 and 14** — the two
features that produced this page. That is a property of any photograph, not a
defect, and it is stated rather than hidden: those rounds happened after the cut.

The live log the snapshot was cut from lives in `.claude/state/`, which is **not**
versioned: the loop writes to it on every round, and committing it would put its
noise in every commit. The snapshot is how the evidence becomes auditable without
that cost.

## Three units, never mixed

| Unit | What it is | At cut `b0bdf4d` |
|---|---|---|
| **round** | one pass of the review contract | **88** logged |
| **milestone** | a stretch ending in `APPROVED` — a detailed spec, an implementation step, a plan cycle | **29** |
| **cycle** | one Codex session, from `new` to its close — roughly one feature or one pipeline unit | **18** complete |

The approvals are **milestones, not features**. That is why there are more
approvals than features, and saying it the other way round is exactly the kind of
sloppiness that makes numbers like these worthless.

A round is the unit of the **contract**, not a row of the log: `review.sh` retries
once on process failure — logging `PROC_FAIL` before the verdict — and an invalid
verdict is logged as `NO_VERDICT`. Counting rows would inflate both. The
normalizer below deduplicates by `(cycle, round)`.

## The figures

Each row names its source, its cut, and the command. Where a figure is
**composite** it has no single command: its parts are listed instead, because
presenting a sum as a derivation would be the same sloppiness in another form.

| Figure | Value | Source | Cut | Command | Auditable from a clone of axel? |
|---|---|---|---|---|---|
| logged rounds | **88** | snapshot | `b0bdf4d` | `wc -l < rounds.tsv` | yes |
| rejections | **59** | snapshot | `b0bdf4d` | `awk -F'\t' '$3=="CHANGES_REQUESTED"{n++} END{print n}' rounds.tsv` | yes |
| approvals (milestones) | **29** | snapshot | `b0bdf4d` | `awk -F'\t' '$3=="APPROVED"{n++} END{print n}' rounds.tsv` | yes |
| complete cycles | **18** | snapshot | `b0bdf4d` | `awk -F'\t' '$1>=1{c[$1]=1} END{print length(c)}' rounds.tsv` | yes |
| …and all of them closed | **18** | snapshot | `b0bdf4d` | `awk -F'\t' '$1>=1{l[$1]=$3} END{n=0; for(k in l) if(l[k]=="APPROVED") n++; print n}' rounds.tsv` | yes |
| verdict of each cycle's round 1 | **18 of 18 rejected** | snapshot | `b0bdf4d` | `awk -F'\t' '$1>=1 && $2==1{print $3}' rounds.tsv \| sort \| uniq -c` | yes |
| median rounds per cycle | **4** | snapshot | `b0bdf4d` | `awk -F'\t' '$1>=1{n[$1]++} END{for(k in n) print n[k]}' rounds.tsv \| sort -n \| awk '{a[NR]=$1} END{if(NR%2) print a[(NR+1)/2]; else print (a[NR/2]+a[NR/2+1])/2}'` | yes |
| median rounds per milestone | **3** | snapshot | `b0bdf4d` | `awk -F'\t' '{n++} $3=="APPROVED"{print n; n=0}' rounds.tsv \| tail -n +2 \| sort -n \| awk '{a[NR]=$1} END{if(NR%2) print a[(NR+1)/2]; else print (a[NR/2]+a[NR/2+1])/2}'` | yes |
| worst case per cycle | **11** | snapshot | `b0bdf4d` | `awk -F'\t' '$1>=1{n[$1]++} END{for(k in n) print n[k]}' rounds.tsv \| sort -n \| tail -1` | yes |
| worst case per milestone | **5** | snapshot | `b0bdf4d` | `awk -F'\t' '{n++} $3=="APPROVED"{print n; n=0}' rounds.tsv \| tail -n +2 \| sort -n \| tail -1` | yes |
| milestones approved with no rejection | **1** (`2dbbdfc`) | snapshot | `b0bdf4d` | `awk -F'\t' '{n++} $3=="APPROVED"{if(n==1) print $4; n=0}' rounds.tsv` | yes |
| rounds of features 00, 01, 02 | **25** | the plan, via each feature's closing round | `b0bdf4d` | `git show b0bdf4d:docs/IMPLEMENTATION.md \| grep -E '^\| 0[0-2] \|' \| sed -E 's/.*\(r([0-9]+).*/\1/' \| awk '{s+=$1} END{print s}'` | yes |
| rounds of feature 03 before the log | **5** | `implementation/03-loop-hardening.md`; cross-checked against the snapshot | `b0bdf4d` | `awk -F'\t' 'NR==1{print $3-1}' docs/metrics/rounds-log-b0bdf4d.tsv` | yes |
| rounds of the initial plan cycle | **5** | commits and historical STATUS — **second source** | **`3ab6794`**, the cycle's close | `echo $(( $(git log --oneline 6afb57d..3ab6794 \| grep -cE ' plan r[0-9]+:') + 1 ))` | yes |
| rounds before instrumentation | **35** — *composite* | the three rows above | their own cuts | 25 + 5 + 5 | yes |
| full history | **123** — *composite* | logged rounds + the row above | `b0bdf4d` and `3ab6794` | 88 + 35 | yes |
| cycles with no first-round approval | **23** — *composite* | 18 logged + 5 predating the log | `b0bdf4d`, plus each earlier cycle's own document | 18 + 5; the five earlier ones are checked one by one, below | yes |
| commits at the cut | **212** | this repository's git history | `b0bdf4d` | `git rev-list --count b0bdf4d` | yes |
| days | **3** | same | `b0bdf4d` | `git log b0bdf4d --format='%ad' --date=short \| sort -u \| wc -l` | yes |
| closed features | **13** | the plan **at the cut** | `b0bdf4d` | `git show b0bdf4d:docs/IMPLEMENTATION.md \| grep -cE '^\| [0-9]+ \|.*\*\*Cerrado\*\*'` | yes |
| external install: commits | **185** | **`alexweil/inquirylab`** | **`4908bfb`** | `git rev-list --count 4908bfb`, run **in that repository** | **no** |
| external install: files installed | **20** | same repository | **`846308f`** | `git show --stat 846308f`, run **in that repository** | **no** |
| external install: files mapped by `/adopt` | **8** | same repository | **`4908bfb`** | `git show --stat 4908bfb`, run **in that repository** | **no** |

Closed features is counted against the plan **as it was at the cut**, not against
the working tree: the live file moves, and would return a different number the
moment the next feature closes. The published phrasing is *13 closed features
(00–12, including bootstrap)* — naming the range keeps the count from reading as
inflated.

## How to re-derive them

Two small awk programs are versioned next to the snapshot, so the commands below
run as written rather than describing something you have to reconstruct:

```sh
awk -v cut=b0bdf4d -f docs/metrics/cut.awk .claude/state/rounds-log > snapshot.tsv
diff snapshot.tsv docs/metrics/rounds-log-b0bdf4d.tsv    # must be empty
awk -f docs/metrics/normalize.awk docs/metrics/rounds-log-b0bdf4d.tsv > rounds.tsv
```

All three must exit `0`; that is a postcondition, not a courtesy.
[`cut.awk`](metrics/cut.awk) fails if the cut SHA is missing or duplicated — a cut
that fails open is worse than none — and
[`normalize.awk`](metrics/normalize.awk) rejects a log whose round sequence is
inconsistent rather than silently merging cycles.

The snapshot is a **literal prefix** of the live log, not a projection. A
projection would ask you to trust the projection, which is the one step you should
be able to audit.

**Schema**, seven tab-separated fields: timestamp, mode (`new`/`round`), round,
attempt, verdict, short SHA, streak. It is an internal format and may change; the
snapshot is a photograph of what the file was, not a promised interface.

## What this evidence does not prove

Two limits, both worth stating plainly.

**Every row names a SHA, and you can check those commits exist in `main`, that
their dates line up, and that the history is linear.** What that does *not* prove
is that nobody rewrote the history before publishing it: a force-push predating
publication is undetectable from a clone. The first claim is made; the second is
not.

**The external-installation figures are not re-derivable from a clone of axel.**
`4908bfb`, `846308f` and `98c70c0` are objects of a different repository
(`alexweil/inquirylab`). Their commands are published and anchored to those SHAs,
but they are verifiable only against that repository — not from here.

## The 35 rounds before instrumentation

The log starts on day two: its first row is already round 6 of a cycle in
progress. What came before is not lost, but it comes from **two different sources
and they are cited separately**.

| Stretch | Rounds | Source |
|---|---|---|
| features 00, 01, 02 | 4 + 11 + 10 = **25** | their versioned review logs, via the closing round recorded in the plan |
| feature 03, rounds 1–5 | **5** | [`implementation/03-loop-hardening.md`](implementation/03-loop-hardening.md), which records them one by one |
| the initial plan cycle | **5** | **second source**: it has no document under `implementation/`; its memory is the commits and the historical STATUS |

25 + 5 = **30** in versioned review logs, plus **5** from commits and STATUS, for
**35** — and **88 + 35 = 123** historically. The two numbers are always published
labelled: *88 logged rounds since instrumentation* and *123 across the full
history*. Never one of them alone.

One caveat about the first row, published because it is the kind of thing that
would otherwise look like a lucky regularity: those 25 come from the **closing
round** each feature records in the plan, not from counting review-log entries.
They are not the same — feature 01's review log lists ten entries and its closing
round is the eleventh. Counting entries would quietly give 10.

**The five cycles predating the log, checked individually** — each command prints
the first round's verdict for its cycle:

```sh
grep -m1 -E '^- \*\*Ronda 1:' docs/implementation/00-bootstrap.md
grep -m1 -E '^- \*\*Ronda 1:' docs/implementation/01-installer.md
grep -m1 -E '^- \*\*Ronda 1:' docs/implementation/02-remote-install.md
grep -m1 -E '^- \*\*Ronda 1:' docs/implementation/03-loop-hardening.md
git show 2f7c814:docs/STATUS.md | grep -m1 -o 'la ronda 1 [^:]*'
```

All five report a rejection. The fifth reads `la ronda 1 pidió cambios` — *round 1
asked for changes* — which is the historical STATUS of the plan cycle, the only one
of the five without a document under `implementation/`.

*"Zero first-round approvals" spans all 23 cycles, and is shown by the verdict of
each cycle's first round — not by its closing round, which proves nothing about
how it started. For the five cycles predating the log, that verdict is
`CHANGES_REQUESTED` in every one.*

## A review that caught something real

Feature 11, round 5. Four defects in text that had already been committed, fixed
in `74d3f5c` and approved in round 6. The most illustrative is the second:

> A blank line had been left between the last row of a Markdown table and a new
> one — which **ends the table**. The row rendered as a stray paragraph, and a
> closure criterion silently went unmet.

Invisible when reading the diff as text. Visible to a reviewer that looks at the
result. That is the difference between a reviewer that reads and one that checks.

## A note on the median

The median is **4 rounds per cycle** at this cut, and that number deserves a
caution rather than a footnote: an earlier draft published 4 for the wrong reason
— it counted the partial cycle the log begins with as if it were complete. At this
cut there are 18 complete cycles and the median of their lengths is genuinely 4.
Same number, different criterion, different cut. It is not published on the front
page for exactly that reason: the criterion needs the room to be explained.

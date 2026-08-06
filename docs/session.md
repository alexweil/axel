# What a session actually looks like

> A companion to the [README](../README.md), for the reader who wants to see a run before installing anything.

In axel the chat is disposable and the repo is the memory, so **there is no session transcript to
capture** — publishing a chat log that looked reconstructed, in a project whose whole pitch is
auditability, would be the worst thing we could do. What follows is rendered from the repo instead.
Every line traces to a commit, a ledger entry or a review log. The originals are in Spanish; the
English is a translation, and the source is named so you can check.

## One run, end to end — [pipeline 2026-07-29 (2)](implementation/pipeline-2026-07-29-2.md)

**1 · A request, with no command typed.** Recorded verbatim in the run's ledger:

> «Que la skill `/adopt` cierre reportándole al humano el **inventario completo de archivos que tocó**, no solo la narrativa de las decisiones que le parecieron importantes.»
>
> *"Make the `/adopt` skill close by reporting the complete inventory of files it touched, not just the story of the decisions it found interesting."*

**2 · A gate, then one authorisation.** axel proposed a route, asked one question, and waited. The
human's answer, quoted in the ledger:

> «a) ok con tu recomendacion · b) dejalo sin registrar» — *"a) ok, go with your recommendation · b) leave it unrecorded"*

**3 · The reviewer catches something real.** Round 1, from the feature's
[review log](implementation/12-adopt-close-report.md):

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

## Does it work outside axel? — one data point

axel was installed into an unrelated active repo with its own documentation — 185 commits as of
`4908bfb`, the commit that closed the adoption. Commit `846308f` installed 20 files there; because the repo already had docs this ran as an **adoption**,
and `4908bfb` closed it with `/adopt`, mapping 8 files onto the convention. Commit `98c70c0` is that
repo applying the `build/` workaround described in the [known issues](install.md#known-issues).

Honest scope: **one repo, same author, and an adoption rather than a full review loop.** It answers
"does this work somewhere that isn't axel" and nothing more.

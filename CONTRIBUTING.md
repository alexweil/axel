# How to give feedback

axel is being shared with a handful of people before anything wider. What is
useful right now is narrow and specific, so this page says exactly what it is —
and what it is not.

## What this round is looking for

**People installing it and telling us what broke.** That is the whole ask.

The installer has been tested against this repository and one other, which is not
the same as being tested. The first colleague with a Python project and a
`.gitignore` that ignores `build/` will hit a refusal that is correct and cryptic
at the same time. That report is worth more than any patch.

Three things are especially useful:

- **The installer refused, errored, or wrote something you did not expect.**
- **Something was harder than it should have been** — a step that needed a second
  reading, a message that did not say what to do next.
- **A question.** If the answer was not obvious from the README or the
  [install manual](docs/install.md), that is a documentation bug and worth
  reporting as one.

Use the [issue templates](.github/ISSUE_TEMPLATE); they ask for the fields that
make a report actionable on the first pass instead of the third.

## What this round is *not* looking for: code

**Please do not send pull requests yet.** Not because they would be unwelcome in
principle, but because there is currently no honest path for one.

Every change to this repository goes through the loop the README describes: a
detailed spec, review by a different vendor's model until it approves, and a human
checkpoint before and after. An external patch has nowhere to enter that loop
today — it would either bypass the process this project exists to demonstrate, or
sit unmerged while someone re-derived it through the process anyway. Saying so is
more honest than leaving the door ajar.

If you want to change something, describe the problem. The design conversation is
the contribution.

## Reporting an install failure

The [install-failed template](.github/ISSUE_TEMPLATE/install-failed.yml) asks for
five things. Here is why each one matters, so you can judge what to include if you
report some other way:

- **The final line.** Every controlled exit prints `── axel · fin: rc=N · … ──`.
  Its absence means the run was interrupted rather than refused, which is a
  different problem with a different fix.
- **The full output.** The installer announces its source, destination and mode
  *before* touching anything; those lines usually contain the answer.
- **The lines in your `.gitignore` that mention `build/`.** The `/build` skill
  lives in `.claude/skills/build/`, and that pattern is in most language
  templates. This is the single most likely cause of a first-time refusal.
- **The mode it announced** — `initial`, `adoption` or `update`. A repository that
  already has documentation is an adoption, and adoption behaves differently.
- **Whether the destination tree was clean.** The installer refuses a dirty tree,
  and `git stash` without `-u` does not touch untracked files — which is the
  common case in an active repository.

## What is out of scope today

These are known and deliberately not fixed yet. Reporting them again is not
useful; hitting something *adjacent* to them is.

- **The three installer friction points** — the `build/` collision, the dirty-tree
  refusal that does not list the offending files, and the mode announced as
  `initial` during an adoption. All three are documented, with workarounds, under
  [known issues](docs/install.md#known-issues).
- **The MIT notice does not travel with the installed files.** The licence asks
  that the copyright and permission notice be included in copies, and the
  installer copies skills, scripts and the review contract into your repository
  without carrying it. This is recorded as an **open gap, not partial compliance**
  — saying so in the manual informs you, it does not satisfy the requirement.
- **The prose the installer writes into your repository is in Spanish.** The
  machinery is language-agnostic; that text simply has not been translated. See
  [language](docs/install.md#language).

## What makes a report good

Three lines, and none of them is about being thorough:

1. **What you ran and what happened**, copied rather than summarised.
2. **Where you looked first** — that tells us whether the problem is the product
   or the manual.
3. **What you expected instead.** It is the part people leave out, and the part
   that usually contains the actual bug.

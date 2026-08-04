---
name: referenta-release-notes
description: Use when asked to write or update release notes for a Referenta Release Candidate, e.g. "Update Release Candidate: v3.2.0#1048 description", or any request to turn an RC pull request's commits into user-facing release notes in the Referenta/referenta repo. Triggers on "Release Candidate", "release notes", an RC PR number or title, or a vX.Y.Z#NNNN reference.
---

# Referenta release notes

Turn a Release Candidate pull request into **user-facing release notes** and write
them into the PR description. The audience is end users, not developers, so the
notes describe what changed *for them*, never how it was built.

**Trigger:** the user says something like *"Update Release Candidate: vX.Y.Z#NNNN
description"*. `NNNN` is the PR number; the PR title is `Release Candidate: vX.Y.Z`.
Repo is always `Referenta/referenta`.

## Tooling

There is no GitHub MCP connected in this setup, so use the **`gh` CLI** (already
authenticated). If a GitHub MCP server is connected in a future session, its PR
read/edit tools are equivalent; prefer whichever is available.

## Workflow

### 1. Resolve the PR

```bash
gh pr view <NNNN> --repo Referenta/referenta \
  --json number,title,state,url,body,commits
```

If given only a title (no number), find it first:

```bash
gh pr list --repo Referenta/referenta --search "Release Candidate: vX.Y.Z" --state all
```

### 2. Read the commits

The commits are the source material for the notes:

```bash
gh pr view <NNNN> --repo Referenta/referenta \
  --json commits --jq '.commits[] | .messageHeadline + "\n" + .messageBody'
```

Group related commits by feature/theme. Ignore noise (merge commits, version
bumps, reverts that net to nothing). When a commit's user impact is unclear, read
the diff (`gh pr diff <NNNN> --repo Referenta/referenta`) rather than guessing.

### 3. Classify every change

Decide, per change, whether a user would notice it.

- **User-facing** → describe it concretely: new features, UX/visible behavior
  changes, bug fixes a user would feel, new capabilities.
- **Internal** → do **not** itemize. Collapse all of it into one vague line (see
  below): security, refactors, developer experience, tooling/CI, dependency
  bumps, tests, infra, and any performance work with no visible effect.

The internal catch-all line, verbatim:

- **EN:** `Internal architecture and developer-experience improvements.`
- **DE:** `Interne Architektur- und Developer-Experience-Verbesserungen.`

### 4. Write the notes

Follow the structure of the reference PR **#1048**, with the two style rules
below applied. Tone: user-facing, concise, professional. No commit hashes, ticket
IDs (REF-N), branch names, or internal jargon.

**Bilingual, German first, then English**, separated by a `---`. The English
section mirrors the German one section-for-section.

**Never use em or en dashes (`—`, `–`)** anywhere in the notes, including inside
prose. Use a colon to lead into a heading tagline or a bullet's explanation, and
commas, semicolons, or parentheses mid-sentence. #1048 predates this rule and is
full of them, so copy its structure, not its punctuation.

**Don't open with a formulaic framing line.** Never write `Das Highlight von
vX.Y.Z: …` or `The headline of vX.Y.Z: …`. State what the feature does in a plain
sentence and let it stand on its own; the version number is already in the PR
title.

Within each language:

1. `### <Headline feature>: <short tagline>` for the release's main feature,
   followed by one plain framing sentence, then bold-lead sub-bullets:
   `- **<capability>:** <what it does for the user>`.
2. Additional `### <themed section>` headings for other notable features.
3. A final small-stuff section (`### Feinschliff & Fehlerbehebungen` /
   `### Polish & fixes`) listing visible fixes, with the **internal catch-all
   line as its last bullet**.

Skeleton:

```markdown
### <Headline>: <tagline>

<One plain sentence saying what the feature does.>

- **<capability>:** <user benefit>.
- **<capability>:** <user benefit>.

### <Themed feature>

- <user-facing point>.

### Feinschliff & Fehlerbehebungen

- <visible fix>.
- Interne Architektur- und Developer-Experience-Verbesserungen.

---

### <Headline>: <tagline>

<One plain sentence saying what the feature does.>

- **<capability>:** <user benefit>.
- **<capability>:** <user benefit>.

### <Themed feature>

- <user-facing point>.

### Polish & fixes

- <visible fix>.
- Internal architecture and developer-experience improvements.
```

### 5. Update the PR description

Write the notes to a file, then set the body:

```bash
gh pr edit <NNNN> --repo Referenta/referenta --body-file <path>
```

Editing the PR body is outward-facing, but trivially reversible. Always paste the
final notes back in your reply so they can be reviewed. If the user-facing vs
internal split was genuinely ambiguous for a release, show the draft for a quick
confirm before writing it.

## Reference

PR #1048 (`Release Candidate: v3.2.0`) is the reference for section structure and
tone; read its description before drafting if unsure. Its punctuation is out of
date: it uses em dashes throughout and opens with the `Das Highlight von …` /
`The headline of …` formula, both of which are now forbidden. Take the shape from
it, not the wording.

## Related

This is the release side of the workflow, the counterpart to the
`referenta-contribution` skill, which covers the author side (ticket → branch →
commit → PR, tagging REF-N throughout). Release notes do the inverse: strip REF-N
and ticket IDs and write for end users.

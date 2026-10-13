---
name: release-notes
description: Use when asked to write or update release notes for a Release Candidate pull request, e.g. "Update Release Candidate: v1.4.0#512 description", or any request to turn an RC pull request's commits into user-facing release notes. Triggers on "Release Candidate", "release notes", an RC PR number or title, or a vX.Y.Z#NNNN reference.
---

# Release notes

Turn a Release Candidate pull request into **user-facing release notes** and write
them into the PR description. The audience is end users, not developers, so the
notes describe what changed *for them*, never how it was built.

**Trigger:** the user says something like *"Update Release Candidate: vX.Y.Z#NNNN
description"*. `NNNN` is the PR number; the PR title is `Release Candidate: vX.Y.Z`.
The repo is the current checkout's GitHub remote unless the user names another —
resolve it once with `gh repo view --json nameWithOwner -q .nameWithOwner` and
pass it as `--repo <owner/repo>` below.

## Tooling

Use the **`gh` CLI** (authenticated). If a GitHub MCP server is connected, its PR
read/edit tools are equivalent; prefer whichever is available.

## Workflow

### 1. Resolve the PR

```bash
gh pr view <NNNN> --repo <owner/repo> \
  --json number,title,state,url,body,commits
```

If given only a title (no number), find it first:

```bash
gh pr list --repo <owner/repo> --search "Release Candidate: vX.Y.Z" --state all
```

### 2. Find the reference

The previous release's notes set the structure, tone, and language(s). Find the
most recent merged Release Candidate before this one and read its description:

```bash
gh pr list --repo <owner/repo> --search "Release Candidate in:title" \
  --state merged --limit 5 --json number,title,mergedAt
```

If there is no earlier RC, use the skeleton below in English only.

### 3. Read the commits

The commits are the source material for the notes:

```bash
gh pr view <NNNN> --repo <owner/repo> \
  --json commits --jq '.commits[] | .messageHeadline + "\n" + .messageBody'
```

Group related commits by feature/theme. Ignore noise (merge commits, version
bumps, reverts that net to nothing). When a commit's user impact is unclear, read
the diff (`gh pr diff <NNNN> --repo <owner/repo>`) rather than guessing.

### 4. Classify every change

Decide, per change, whether a user would notice it.

- **User-facing** → describe it concretely: new features, UX/visible behavior
  changes, bug fixes a user would feel, new capabilities.
- **Internal** → do **not** itemize. Collapse all of it into one vague line:
  security, refactors, developer experience, tooling/CI, dependency bumps, tests,
  infra, and any performance work with no visible effect.
- **Staff-only tools are internal**, however visible they are to staff: an admin
  console customers never reach (in Referenta, everything under `apps/admin`)
  goes into the catch-all. In a change that touches both, describe only the
  product part.
- **A flag-gated feature is user-facing**, with an availability note. Work that
  is complete and reachable in the product but gated by a rollout flag gets its
  normal section, plus the availability line below, in italics, once per
  section, directly under the section's framing sentence. Do not drop it into
  the catch-all, and do not name the flag or guess at the rollout percentage.
- **Never mention a feature that does not exist for users.** A feature whose
  entry point is not shipped, or that is only partially merged in this range, is
  internal. No withdrawal notices, no "coming soon". A flag alone does not make
  something incomplete; check whether the entry point is in the tree. If you
  cannot tell whether the feature is finished, treat it as internal.

The internal catch-all line, verbatim (translate it if the notes use another
language, and keep that translation consistent across releases):

- `Internal architecture and developer-experience improvements.`

The availability line for a flag-gated section, same translation rule:

- `*This feature is being rolled out gradually and may not be available in your organization yet.*`

### 5. Write the notes

Follow the reference's structure, with the style rules below applied. Tone:
user-facing, concise, professional. No commit hashes, ticket IDs, branch names,
or internal jargon.

**Match the reference's languages.** If it is multilingual, keep the same
language order, one section per language separated by a `---`, each mirroring
the first section-for-section.

**Never use em or en dashes (`—`, `–`)** anywhere in the notes, including inside
prose. Use a colon to lead into a heading tagline or a bullet's explanation, and
commas, semicolons, or parentheses mid-sentence. If the reference uses them, copy
its structure, not its punctuation.

**Don't open with a formulaic framing line** such as `The headline of vX.Y.Z: …`.
State what the feature does in a plain sentence and let it stand on its own; the
version number is already in the PR title.

Within each language:

1. `### <Headline feature>: <short tagline>` for the release's main feature,
   followed by one plain framing sentence, then bold-lead sub-bullets:
   `- **<capability>:** <what it does for the user>`.
2. Additional `### <themed section>` headings for other notable features.
3. A final small-stuff section (`### Polish & fixes`) listing visible fixes, with
   the **internal catch-all line as its last bullet**.

Skeleton:

```markdown
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

### 6. Update the PR description

Write the notes to a file, then set the body:

```bash
gh pr edit <NNNN> --repo <owner/repo> --body-file <path>
```

Editing the PR body is outward-facing, but trivially reversible. Always paste the
final notes back in your reply so they can be reviewed. If the user-facing vs
internal split was genuinely ambiguous for a release, show the draft for a quick
confirm before writing it.

## Related

This is the release side of the workflow, the counterpart to the
`linear-ticket-workflow` skill, which covers the author side (ticket → branch →
commit → PR, tagging ticket keys throughout). Release notes do the inverse: strip
ticket keys and write for end users.

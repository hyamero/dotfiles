# dotfiles

Version-controlled macOS configs with a one-command bootstrap for a fresh Mac,
kept in a private repo and managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Stow uses a symlink-farm layout: each top-level dir is a *package* that mirrors
`$HOME`, and `stow <package>` symlinks its contents into place. So `~/.zshrc`
becomes a symlink to `zsh/.zshrc` in this repo — edit either path, it's the same
file.

Where a target dir already exists and holds other apps' data (`~/.config`,
`~/.claude`), stow only symlinks the individual tracked *leaves* inside it (e.g.
`~/.claude/settings.json`), leaving everything else — caches, sessions, history
— untouched and untracked.

> **Note:** the repo lives at `~/documents/projects/personal/dotfiles`, not
> directly under `$HOME`, so every `stow` command must pass `-t "$HOME"`.
> `install.sh` and the snippets below already do.

## Layout

| Package  | Contents                                      |
| -------- | --------------------------------------------- |
| `zsh`    | `.zshrc`, `.zprofile`                         |
| `git`    | `.gitconfig`, `.config/git/ignore`            |
| `claude` | `.claude/settings.json`, `.claude/CLAUDE.md`  |
| `agents` | `.agents/skills/`, `.agents/.skill-lock.json` |

```
dotfiles/
├── README.md
├── CLAUDE.md             # repo gotchas + workflow (for Claude Code)
├── .gitignore
├── Brewfile              # generated via `brew bundle dump`
├── claude-plugins.list   # generated; plugins install.sh reinstalls
├── install.sh            # bootstrap: homebrew → brew bundle → stow → glue → plugins
├── zsh/
│   ├── .zshrc
│   └── .zprofile
├── git/
│   ├── .gitconfig
│   └── .config/git/ignore
├── claude/
│   └── .claude/
│       ├── settings.json
│       └── CLAUDE.md     # global Claude Code defaults
└── agents/
    └── .agents/
        ├── .skill-lock.json
        └── skills/        # 23 skills — the real content
```

## Setup

### Fresh machine

```sh
git clone git@github.com:hyamero/dotfiles.git ~/documents/projects/personal/dotfiles
cd ~/documents/projects/personal/dotfiles
./install.sh
```

`install.sh` is idempotent — safe to re-run anytime. It:

1. Installs **Homebrew** if missing.
2. Runs `brew bundle` to install everything in the `Brewfile` (including `stow`).
3. Backs up any conflicting real file at a target path to `*.pre-stow`, then
   **stows** every package (with `-t "$HOME"`).
4. Creates the `~/.claude/skills` glue links on first run (see
   [What's tracked vs. not](#whats-tracked-vs-not)).
5. Reinstalls the Claude plugins listed in `claude-plugins.list` — if the
   `claude` CLI is present. Re-run after installing Claude Code if it wasn't.

### Verify

- `ls -la ~/.zshrc ~/.gitconfig ~/.claude/settings.json` — symlinks pointing into the repo
- A new `zsh` shell loads without errors; `git config --global user.name` resolves
- `claude` sees its settings + skills (paths resolve through the symlinks)

## Daily use

`~/.zshrc` etc. are symlinks into this repo — edit them as usual, then:

```sh
cd ~/documents/projects/personal/dotfiles
git add -A && git commit -m "..." && git push
```

### Add a config

Place the file in a package dir mirroring its `$HOME` path, then re-stow:

```sh
cd ~/documents/projects/personal/dotfiles
stow -t "$HOME" --restow <package>
```

### Refresh the Brewfile

```sh
brew bundle dump --file=Brewfile --force --no-vscode
```

VS Code extensions are intentionally excluded (synced via VS Code Settings
Sync) — `--no-vscode` keeps them out.

### Refresh the plugin list

After adding or removing Claude plugins, regenerate `claude-plugins.list` from
the authoritative installed set (same idea as `brew bundle dump`):

```sh
{ echo "# Claude plugins to reinstall on a fresh machine."
  echo "# Generated from ~/.claude/plugins/installed_plugins.json — see README (Refresh the plugin list)."
  python3 -c 'import json; print("\n".join(sorted(json.load(open(__import__("os").path.expanduser("~/.claude/plugins/installed_plugins.json")))["plugins"])))'
} > claude-plugins.list
```

## What's tracked vs. not

**The skills glue.** `~/.claude/skills` is *not* tracked — it's a directory of
relative symlinks (`../../.agents/skills/<name>`) created by a skills CLI that
only resolve from `$HOME`. The real skill content lives in `~/.agents/skills`
and is tracked via the `agents` package; `install.sh` regenerates the glue links
on a fresh machine.

**Plugins.** The plugin *code* isn't tracked — only `claude-plugins.list`, a
generated manifest of which plugins to reinstall (from the built-in
`claude-plugins-official` marketplace). We don't rely on `settings.json`'s
`enabledPlugins` for this: Claude Code auto-manages that field and prunes it, so
it's an unreliable restore source. Regenerate the list with the command above
after changing your plugins.

**Deliberately excluded:**

- `~/.config/gh` — contains auth tokens
- `~/.config/raycast`, `~/.config/opencode` — machine state
- `~/.config/fish` — unused
- `~/.claude` machine state — cache, sessions, history, plugins, projects

**Secrets.** No credentials are committed, even though the repo is private. Keep
machine-specific secrets in an untracked `~/.zshrc.local` (ignored via `*.local`)
and source it from `.zshrc`.

**`.gitignore`:**

```
.DS_Store
docs/superpowers/    # design notes, local-only
*.pre-stow           # install.sh backups
*.local              # machine-local overrides
```

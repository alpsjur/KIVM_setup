# KIVM setup

Minimal KIVM setup script. 

## Installs

- **NVM** (`v0.40.1`) and latest **Node.js**
- **GitHub Copilot CLI** (`@github/copilot`, global npm package)
- **OpenCode CLI** (`@opencode/cli`, global npm package)
  - Configures `~/.config/opencode/cli.json` with `session.thinking: "show"` and `mini.thinking: "show"` for visible reasoning by default
- **Kitty terminal** (user-space install in `~/.local/kitty.app`, with `kitty`/`kitten` symlinks in `~/.local/bin`)
  - `icat` and `icat-compat` wrappers in `~/.local/bin` for displaying images over SSH via the kitty graphics protocol
- **Miniforge/Mamba** (installed to `~/conda`, conda-forge channel only; initialized with `mamba shell init`)
- **mdcat** (conda-forge, symlinked to `~/.local/bin/mdcat`)
  - Adds `MDCAT_IMAGE_PROTOCOL=kitty` and an `md` pager helper to `~/.bashrc` (inline images over SSH)
- **yazi** (conda-forge, symlinked to `~/.local/bin/yazi` and `ya`)
  - Also installs the helpers yazi calls: `fzf`, `fd`, `ripgrep`, `zoxide`, `jq`
  - Adds a `y` function to `~/.bashrc`: run `y` instead of `yazi`, and quitting with `q` leaves the shell in the folder you were browsing (`Q` quits without changing directory)

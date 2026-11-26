echo "Dummy setup start..."
echo ""

# show basic stats
echo "date:"
date
echo ""

echo "pwd:"
pwd
echo ""

echo "install nvm, node, copilot cli"
echo "--- nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# sourcing is the usual way to do it, but does not work within the script (probably because of bashrc interactive session check)
# source ~/.bashrc
# load nvm explicitly!
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
echo "--- node"
nvm install node
echo "--- copilot cli"
npm install -g @github/copilot
echo "--- opencode"
# postinstall must run: it fetches the platform binary
npm install -g --allow-scripts=@opencode/cli @opencode/cli

# Show model reasoning by default. These are CLI settings, so they belong in
# cli.json, not opencode.json. node (installed above) merges the setting into
# any existing cli.json instead of replacing other preferences.
mkdir -p "$HOME/.config/opencode"
node <<'NODE'
const fs = require("node:fs")
const path = require("node:path")

const file = path.join(process.env.HOME, ".config", "opencode", "cli.json")
let config = {}

try {
  const text = fs.readFileSync(file, "utf8").trim()
  if (text) {
    const parsed = JSON.parse(text)
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      config = parsed
    } else {
      fs.copyFileSync(file, file + ".bak")
    }
  }
} catch (err) {
  if (err.code === "ENOENT") {
    // New VM; create cli.json below.
  } else if (err instanceof SyntaxError) {
    // cli.json may be JSONC or malformed; preserve it before writing JSON.
    fs.copyFileSync(file, file + ".bak")
  } else {
    throw err
  }
}

config.$schema = "https://opencode.ai/v2/cli.json"
config.session = { ...config.session, thinking: "show" }
config.mini = { ...config.mini, thinking: "show" }

fs.writeFileSync(file, JSON.stringify(config, null, 2) + "\n")
NODE
echo ""

echo "install kitty terminal (user-space, no sudo)"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/"

# Wrapper for displaying images over SSH. Plain image paths use a 4096-byte
# chunk sender: newer kitten versions send 128 KiB chunks, which older kitty
# terminals print as text instead of rendering. Options such as
# --detect-support still go to kitten directly.
cat > "$HOME/.local/bin/icat-compat" <<'PYEOF'
#!/usr/bin/env python3
import base64
import subprocess
import sys

CHUNK_SIZE = 4096
START = b"\x1b_G"
END = b"\x1b\\"


def png_bytes(path):
    with open(path, "rb") as f:
        data = f.read()
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return data
    for cmd in (["magick", path, "png:-"], ["convert", path, "png:-"]):
        try:
            return subprocess.run(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=True
            ).stdout
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass
    raise SystemExit(f"icat-compat: cannot decode {path!r} as PNG")


def display(data):
    payload = base64.standard_b64encode(data)
    out = sys.stdout.buffer
    for offset in range(0, len(payload), CHUNK_SIZE):
        chunk = payload[offset : offset + CHUNK_SIZE]
        last = offset + CHUNK_SIZE >= len(payload)
        params = []
        if offset == 0:
            params.extend(["a=T", "f=100", "q=2"])
        params.append("m=0" if last else "m=1")
        out.write(START + ",".join(params).encode("ascii") + b";" + chunk + END)
    out.write(b"\n")
    out.flush()


if not sys.argv[1:]:
    print("usage: icat-compat IMAGE [IMAGE ...]", file=sys.stderr)
    raise SystemExit(2)
for path in sys.argv[1:]:
    display(png_bytes(path))
PYEOF

cat > "$HOME/.local/bin/icat" <<'EOF'
#!/bin/sh
if [ "$#" -ge 1 ] && [ "${1#-}" = "$1" ] && [ -f "$1" ]; then
    exec "$HOME/.local/bin/icat-compat" "$@"
fi
exec kitten icat --transfer-mode=stream "$@"
EOF
chmod +x "$HOME/.local/bin/icat" "$HOME/.local/bin/icat-compat"
echo ""


echo "install mamba"
# mamba from conda-forge: only use the conda-forge channel, do NOT use the paid Anaconda Inc channels
wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3.sh -b -p "${HOME}/conda"
rm -f Miniforge3.sh
source "${HOME}/conda/etc/profile.d/mamba.sh"
mamba shell init
echo ""

echo "install mdcat (markdown viewer with inline kitty images)"
"${HOME}/conda/bin/mamba" install -y -c conda-forge mdcat
ln -sf "$HOME/conda/bin/mdcat" "$HOME/.local/bin/mdcat"
# TERM is xterm-256color over SSH, so force the kitty image protocol
if ! grep -q MDCAT_IMAGE_PROTOCOL "$HOME/.bashrc"; then
cat >> "$HOME/.bashrc" <<'EOF'

# mdcat: force kitty image protocol (TERM is not xterm-kitty over SSH)
export MDCAT_IMAGE_PROTOCOL=kitty
md() { mdcat --full-width "$@" | less -R; }
EOF
fi
echo ""

echo "install yazi (terminal file manager) and the helpers it calls (fzf, fd, rg, zoxide)"
"${HOME}/conda/bin/mamba" install -y -c conda-forge yazi fzf fd-find ripgrep zoxide jq
ln -sf "$HOME/conda/bin/yazi" "$HOME/conda/bin/ya" "$HOME/.local/bin/"
ln -sf "$HOME/conda/bin/fzf" "$HOME/conda/bin/fd" "$HOME/conda/bin/rg" "$HOME/conda/bin/zoxide" "$HOME/.local/bin/"
# y: start yazi and cd the shell into the last directory when quitting with q (Q quits without cd)
if ! grep -q 'function y()' "$HOME/.bashrc"; then
cat >> "$HOME/.bashrc" <<'EOF'

# yazi: cd into the last directory when quitting
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
EOF
fi
echo ""

# if I wanted to create a folder, add a file, write to it, I would for example:
#   mkdir -p $HOME/some_location
#   touch $HOME/some_location/myfile
#   echo "writing" >> $HOME/some_location/myfile

echo "... dummy setup end"

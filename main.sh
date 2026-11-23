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
echo ""

echo "install kitty terminal (user-space, no sudo)"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/"
echo ""


echo "install mamba"
# mamba from conda-forge: only use the conda-forge channel, do NOT use the paid Anaconda Inc channels
wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3.sh -b -p "${HOME}/conda"
rm -f Miniforge3.sh
source "${HOME}/conda/etc/profile.d/mamba.sh"
mamba shell init
echo ""

# if I wanted to create a folder, add a file, write to it, I would for example:
#   mkdir -p $HOME/some_location
#   touch $HOME/some_location/myfile
#   echo "writing" >> $HOME/some_location/myfile

echo "... dummy setup end"

# Homebrew. Prefix differs per platform: /opt/homebrew on Apple Silicon,
# /home/linuxbrew/.linuxbrew on Linux/WSL.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# python.org framework build (macOS only).
# The original version is saved in .zprofile.pysave
if [[ -d /Library/Frameworks/Python.framework/Versions/3.13/bin ]]; then
  export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:$PATH"
fi

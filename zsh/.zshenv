# Non-login shells (ssh/mosh) skip .zprofile; mosh needs mosh-server on PATH.
for _prefix in /opt/homebrew /home/linuxbrew/.linuxbrew; do
  if [[ -x $_prefix/bin/brew && ":$PATH:" != *":$_prefix/bin:"* ]]; then
    export PATH="$_prefix/bin:$PATH"
  fi
done
unset _prefix

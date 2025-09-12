# Shells and Git (Quick Primer)

This repo assumes basic comfort with a Unix shell and Git. If you’re new or need a refresher, start here.

## Shell (zsh on macOS)
- Check your shell: `echo $SHELL` (default on macOS is `/bin/zsh`).
- Run a command from the current folder: `./script.sh` (make it executable with `chmod +x script.sh`).
- Add a folder to PATH (so `tutor` is callable anywhere):
  - One‑time in the current terminal: `export PATH="$HOME/.local/bin:$PATH"`
  - Persist for future terminals (zsh):
    - `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc`
    - `source ~/.zshrc`
- Verify: `which tutor` and `tutor --help`.

References
- zsh manual: https://zsh.sourceforge.io/Doc/Release/index.html
- macOS Terminal basics: https://support.apple.com/guide/terminal/welcome/mac

## Git (version control)
- Check version: `git --version` (install from https://git-scm.com if needed).
- First‑time setup (identifies your commits):
  - `git config --global user.name "Your Name"`
  - `git config --global user.email "you@example.com"`
- Clone a repo: `git clone https://github.com/<org>/<repo>.git`
- Common commands: `git status`, `git add -p`, `git commit -m "..."`, `git pull --rebase`, `git push`.
- SSH keys (optional): https://docs.github.com/en/authentication/connecting-to-github-with-ssh

References
- Git Book (free): https://git-scm.com/book/en/v2
- GitHub Docs (basics): https://docs.github.com/en/get-started

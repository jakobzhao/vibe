# Contributing

Thanks for helping improve Vibe.

1. Fork the repository and create a focused branch.
2. Keep shell code compatible with POSIX `sh` unless a script explicitly uses Bash.
3. Avoid user-specific paths, credentials, and assumptions about an existing tmux server.
4. Run `./tests/check.sh` on macOS or Linux.
5. Explain user-visible behavior changes in the pull request.

Bug reports should include the operating system, tmux/Yazi/Neovim versions, the
command that was run, and the relevant terminal output.

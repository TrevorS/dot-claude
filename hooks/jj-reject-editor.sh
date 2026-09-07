#!/bin/bash
# $JJ_EDITOR target — invoked by jj whenever a command needs an interactive
# message editor (describe/commit/squash without -m, etc.). In Claude Code an
# editor blocks on a tty; the harness then auto-backgrounds the command and the
# agent can't tell whether it landed. Fail fast and loud so the agent retries
# non-interactively instead of hanging.
#
# Wired from settings.json as: sh -c 'exec "$HOME/.claude/hooks/jj-reject-editor.sh"'
# The wrapper is deliberate: settings env values are literal (no $HOME or ~
# expansion) and jj does not expand ~ in JJ_EDITOR, but this file lives under a
# different home dir on each machine. jj appends the message file as a trailing
# argument; this script ignores it.
cat >&2 <<'MSG'
jj tried to open an interactive editor — blocked in Claude Code (no tty).

Retry non-interactively with an inline message:
  jj describe -m "msg"      jj commit -m "msg"      jj new -m "msg"
  jj squash   -m "msg"      (or -u to reuse the destination commit's message)

Never use jj split / diffedit / squash -i / resolve — no non-interactive mode.
File-forget in this jj is `jj file untrack <path>`, not `jj forget`.
MSG
exit 1

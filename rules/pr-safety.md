# PR Safety: Don't Rewrite Reviewed History Without Asking

If a branch already has an open PR **and any review comments, review threads, or inline comments**, do NOT rebase, squash, amend, force-push, `jj squash --into`, or otherwise rewrite its commits without explicit permission. Rewriting history detaches existing review comments from their line anchors and makes the discussion hard or impossible to follow.

Before any history-rewriting operation on a PR branch:

1. Check whether a PR exists (`gh pr view <branch>` or check the bookmark).
2. If yes, check for review comments (`gh pr view <branch> --json reviews,comments` — non-empty `reviews` or `comments`).
3. If there are comments, **stop and ask Teej** before rewriting. Default to adding new commits on top (`jj new` + `jj git push`, or `git commit` + `git push`) so review threads stay anchored.
4. Force-pushing is allowed only when (a) Teej confirms, or (b) the PR has zero review activity.

This applies equally to jj (`jj squash`, `jj rebase`, `jj abandon` of pushed changes, `--ignore-immutable`) and git (`rebase`, `commit --amend`, `push -f`, `push --force-with-lease`). The `immutable_heads()` revset already protects pushed jj commits — treat a "do you want to override?" moment as the same checkpoint: ask first.

On the git side this is enforced, not just documented: `hooks/git_dangerous_flags.sh`
(PreToolUse) blocks `push --force`/`-f`/`--force-with-lease`, `commit --amend`,
`--no-verify`, `reset --hard`, and `gh pr merge --admin` before they run. It walks
tokens rather than matching a prefix, so flag position and `git -C <path>` don't
evade it. The block is on the agent only — run the command yourself with the `!`
prefix once you've decided it's the right move.

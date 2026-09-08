# PR Safety: Don't Rewrite Reviewed History Without Asking

If a branch has an open PR **with any review comments, review threads, or inline comments**, do not rebase, squash, amend, force-push, `jj squash --into`, `--ignore-immutable`, or otherwise rewrite its commits without asking Teej. Rewriting detaches review comments from their line anchors.

Before any history-rewriting operation on a PR branch:

1. `gh pr view <branch>` to see whether a PR exists.
2. `gh pr view <branch> --json reviews,comments` to check for review activity.
3. If there is any, stop and ask. Default to new commits on top (`jj new` + `jj git push`) so threads stay anchored.

Force-pushing is fine only when Teej confirms or the PR has zero review activity. `hooks/git_dangerous_flags.sh` blocks the git forms (`push --force`, `commit --amend`, `reset --hard`, `--no-verify`, `gh pr merge --admin`) for the agent; when you and Teej agree it is the right move, hand him the command to run with the `!` prefix.

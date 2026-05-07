---
name: using-1password
description: Create, retrieve, and share 1Password items using the op CLI. Use when creating secure notes, storing credentials, generating shareable links, or looking up vault contents.
---

# 1Password CLI (op)

Create and share 1Password items without leaving the terminal.

## Quick Examples

```bash
# List vaults
op vault list

# Create a secure note
op item create \
  --category "Secure Note" \
  --title "My Note" \
  --vault "Engineering" \
  'notesPlain=line one\nline two'

# Get a shareable link (expires in 7 days by default)
op item share "My Note" --vault "Engineering"

# Get a shareable link with explicit expiry
op item share "My Note" --vault "Engineering" --expires-in 7d

# One-time link — expires after first view (mutually exclusive with --expires-in)
op item share "My Note" --vault "Engineering" --view-once

# Look up an existing item
op item get "My Note" --vault "Engineering"

# List items in a vault
op item list --vault "Engineering"
```

## Shareable Links

`op item share` generates a `https://share.1password.com/...` URL anyone can open in a browser — no 1Password account needed. Default expiry is 7 days; use `--expires-in` to adjust (e.g. `1d`, `7d`, `14d`, `30d`). Use `--view-once` to expire the link after a single view.

## Creating Notes with Multiline Content

Use a heredoc to avoid shell escaping issues:

```bash
op item create \
  --category "Secure Note" \
  --title "My Note" \
  --vault "Engineering" \
  "notesPlain=$(cat <<'EOF'
Line one
Line two
Line three
EOF
)"
```

## Authentication

```bash
op signin          # Sign in (opens browser)
op whoami          # Check current session
op signout         # End session
```

## More Info

See REFERENCE.md for field types, tagging, and advanced patterns.

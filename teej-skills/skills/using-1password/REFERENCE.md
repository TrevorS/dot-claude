# 1Password CLI Reference

## Common Workflows

### Create a secure note and share it

```bash
op item create \
  --category "Secure Note" \
  --title "Acme - API Keys" \
  --vault "Engineering" \
  "notesPlain=$(cat <<'EOF'
Service: Acme Corp
Key: abc123xyz
Created: 2026-01-01
EOF
)"

op item get "Acme - API Keys" --vault "Engineering" --share-link --expiry 7d
```

### Store credentials with named fields

```bash
op item create \
  --category "API Credential" \
  --title "Service Name" \
  --vault "Engineering" \
  'username=myuser' \
  'credential=supersecretkey'
```

### Look up an item by title

```bash
op item get "Acme - API Keys" --vault "Engineering" --fields notesPlain
```

### Delete an item

```bash
op item delete "Acme - API Keys" --vault "Engineering"
```

## Expiry Options for Share Links

| Flag            | Duration  |
|-----------------|-----------|
| `--expiry 1d`   | 1 day     |
| `--expiry 7d`   | 7 days    |
| `--expiry 14d`  | 14 days   |
| `--expiry 30d`  | 30 days   |

## Vault IDs vs Names

Both work interchangeably:

```bash
--vault "Engineering"
--vault "js4hbjnzh3ly27nyz44cbo3v6a"
```

## Categories

Common categories for `--category`:
- `"Secure Note"`
- `"Login"`
- `"API Credential"`
- `"Password"`

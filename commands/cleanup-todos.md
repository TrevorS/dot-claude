# Cleanup Todo Files

<!-- ABOUTME: Removes empty todo files containing only [] arrays to prevent directory bloat -->
<!-- ABOUTME: Maintains system performance by cleaning up unused todo file remnants -->

Remove empty todo files that contain only `[]` arrays to prevent directory bloat and maintain system performance.

## Task

I will:

1. Scan the todos directory for files containing only empty arrays
2. Safely identify and count empty vs. meaningful todo files
3. Remove only files that contain exactly `[]` (empty arrays)
4. Report cleanup results with before/after file counts
5. Preserve all files with actual todo content

## Safety Protocol

- **Never remove files with actual content** - only empty `[]` arrays
- **Verify before deletion** - double-check file contents match exactly `[]`
- **Report actions taken** - show exactly what was removed
- **Preserve important todos** - keep all files with meaningful data

## Commands Used

```bash
# Count total files before cleanup
find ~/.claude/todos -name "*.json" | wc -l

# Count empty array files to be removed
find ~/.claude/todos -name "*.json" -exec sh -c 'if [ "$(cat "$1")" = "[]" ]; then echo "$1"; fi' _ {} \; | wc -l

# Remove empty array files safely
find ~/.claude/todos -name "*.json" -exec sh -c 'if [ "$(cat "$1")" = "[]" ]; then echo "Removing: $1"; rm "$1"; fi' _ {} \;

# Verify cleanup success
find ~/.claude/todos -name "*.json" | wc -l
```

## Output Format

The command provides:

- **Before count**: Total files before cleanup
- **Empty files identified**: Number of `[]` files to remove
- **Removal log**: Each file being deleted
- **After count**: Remaining files with actual content
- **Verification**: Confirm no empty arrays remain

## Use Cases

- **Regular maintenance**: Run weekly/monthly to prevent bloat
- **Performance issues**: When todos directory becomes sluggish
- **Storage cleanup**: Reclaim disk space from empty files
- **System optimization**: Keep only meaningful todo data

## Background

The todo system can accumulate hundreds of empty `[]` files from completed sessions, creating directory bloat and mental overhead. This command safely removes only the empty files while preserving all actual todo content.

Example cleanup result:

- Removed: 351 empty files
- Preserved: 297 files with content
- Disk space saved: ~35KB+ depending on filesystem

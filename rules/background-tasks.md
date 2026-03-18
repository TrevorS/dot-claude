# Background Tasks

When a background task completes and sends a `<task-notification>` with an `<output-file>` path, read the file directly with the Read tool. Do NOT call `TaskOutput` — the task ID may already be cleaned up, causing a "No task found" error.

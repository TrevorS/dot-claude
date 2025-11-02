---
name: Wait-For
description: Guide intelligent waiting for services and processes instead of arbitrary sleeps and timeouts. Use when waiting for services to start, databases to be ready, processes to finish, or files to be created.
---

# Wait-For: Proper Service & Process Waiting

Eliminate arbitrary `sleep 30` commands and brittle timeout guessing. This skill guides you through properly waiting for services and processes to actually become ready.

## Key Insight

**Port availability ≠ service readiness.** A listening port doesn't mean the service is initialized. Always validate actual functionality.

## Most Common Patterns

### Wait for HTTP Service

```bash
timeout 30 bash -c 'until curl -f -s http://localhost:3000 > /dev/null; do sleep 1; done'
```

Use for Node.js, Python Flask/Django, any HTTP API you can healthcheck.

### Wait for Background Process

```bash
npm run build &
PID=$!
if wait $PID; then
  echo "Success"
else
  echo "Failed with code $?"
fi
```

Always use `wait $PID` to capture exit codes, never just `wait`.

### Wait for Database

```bash
# PostgreSQL (not TCP check!)
timeout 30 bash -c 'until pg_isready -h localhost -U postgres; do sleep 1; done'

# MySQL
until mysqladmin ping -h localhost -u root --silent; do sleep 1; done

# Redis
until redis-cli -h localhost ping > /dev/null 2>&1; do sleep 1; done
```

Critical: Always use database-specific commands, never just TCP checks.

## When to Use This Skill

- Setting up test environments or CI/CD pipelines
- Starting multi-service applications
- Waiting for infrastructure to come online
- Debugging service startup issues
- Replacing fixed `sleep` durations with intelligent polling

## More Info

See REFERENCE.md for:

- File existence and event-based watching
- TCP port checks and fallback strategies
- Debugging common timeout issues
- Advanced patterns (exponential backoff, wait4x, tool detection)
- Docker Compose healthcheck patterns
- Antipatterns to avoid

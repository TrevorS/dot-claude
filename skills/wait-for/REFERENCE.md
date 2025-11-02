# Wait-For: Proper Service & Process Waiting

This skill guides you through properly waiting for services and processes to become ready, eliminating the need for arbitrary `sleep` commands and brittle `timeout`-only approaches.

**Key insight**: Port availability doesn't equal service readiness. Always validate actual functionality instead of guessing with fixed sleep times.

---

## Most Common Scenarios (Start Here)

### 1. Wait for HTTP Service to Be Ready

This is the most common pattern—a service is ready when it responds to HTTP requests:

```bash
# Simple and reliable (using curl)
timeout 30 bash -c 'until curl -f -s http://localhost:3000 > /dev/null; do sleep 1; done'
```

**That's it.** Use this for:

- Node.js servers
- Python Flask/Django apps
- Any HTTP API you can healthcheck
- Web services after startup

**Why this works**: `curl -f` fails if HTTP status isn't 2xx-3xx, and `until` loops until the command succeeds.

### 2. Wait for a Background Process to Finish

```bash
# Start your process in background
npm run build &
PID=$!

# Wait for it to complete
if wait $PID; then
  echo "Build succeeded"
else
  echo "Build failed"
fi
```

**Why this is important**: `wait $PID` gives you the exit code. Never just `wait` without a PID.

### 3. Wait for a Database to Be Ready

Databases are special—the port might be open but the database might not be initialized:

```bash
# PostgreSQL
timeout 30 bash -c 'until pg_isready -h localhost -U postgres; do sleep 1; done'

# MySQL
until mysqladmin ping -h localhost -u root --silent; do sleep 1; done

# Redis
until redis-cli -h localhost ping > /dev/null 2>&1; do sleep 1; done
```

**Critical point**: Never use TCP port checks for databases. Always use the database-specific command.

---

## Progressive Disclosure: More Details Below

Once you've used the common patterns above, here are additional details for specific situations.

### File Existence Checks

**Simple polling** (good enough for most cases):

```bash
timeout 30 bash -c 'until [ -e /path/to/file ]; do sleep 0.5; done'
```

**Event-based** (more efficient, optional):

- macOS: `fswatch -1 -e Created /path/to/directory` (install: `brew install fswatch`)
- Linux: `inotifywait -e create /path/to/directory` (install: `apt-get install inotify-tools`)

### TCP Port Checks (When HTTP Isn't an Option)

For checking if a port is listening (less reliable than HTTP):

```bash
# Using netcat
timeout 30 bash -c 'until nc -z localhost 5432; do sleep 1; done'

# Fallback for systems without nc
timeout 30 bash -c 'until echo > /dev/tcp/localhost/5432; do sleep 1; done'
```

**Note**: Port availability doesn't mean the service is ready. Prefer database-specific checks or HTTP health endpoints.

### MongoDB

```bash
until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do sleep 1; done
```

---

## When Things Go Wrong: Debugging

### Service Keeps Timing Out

**What to check**:

1. Is the service actually starting? Run it manually and verify it works
2. Is it listening on the right port/URL?
3. Does the service take longer than your timeout? Increase it: `timeout 60` instead of `timeout 30`

### Exit Code Lost

```bash
# WRONG: Can't tell if process succeeded
long_command &
wait

# RIGHT: Can check the exit code
long_command &
PID=$!
wait $PID && echo "Success" || echo "Failed"
```

### Infinite Loop in CI/CD

**Always add a timeout**. Never do this:

```bash
# DANGER: Can hang forever
while ! curl http://localhost:3000; do sleep 1; done
```

**Do this instead**:

```bash
# Safe: Max 30 second wait
timeout 30 bash -c 'until curl -f -s http://localhost:3000 > /dev/null; do sleep 1; done'
```

---

## Advanced: Detection & Tool Selection

If you need to handle multiple environments, check what tools are available:

```bash
# Detect available tools
has_curl=$(command -v curl &> /dev/null && echo true || echo false)
has_nc=$(command -v nc &> /dev/null && echo true || echo false)

# Use the best available
if $has_curl; then
  timeout 30 bash -c 'until curl -f -s http://localhost:3000 > /dev/null; do sleep 1; done'
elif $has_nc; then
  timeout 30 bash -c 'until nc -z localhost 3000; do sleep 1; done'
else
  echo "ERROR: Need curl or nc installed"
  exit 1
fi
```

---

## Advanced: Multiple Services with Exponential Backoff

If you're waiting for several services and want smarter retry logic:

```bash
wait_with_backoff() {
  local check_command=$1
  local max_attempts=${2:-10}
  local initial_wait=${3:-1}

  local attempt=0
  local wait_time=$initial_wait

  until eval "$check_command"; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      echo "Max attempts reached"
      return 1
    fi
    echo "Retry $attempt, waiting ${wait_time}s..."
    sleep "$wait_time"
    wait_time=$((wait_time * 2))  # Double each time
  done
}

# Usage: waits 1s, then 2s, then 4s, etc.
wait_with_backoff 'curl -f -s http://localhost:3000' 10 1
```

---

## Advanced: Using wait4x (Modern Tool)

If you frequently work with multiple services, consider installing `wait4x`:

```bash
brew install wait4x
```

**Benefits**:

- Single tool for HTTP, TCP, DNS, databases
- Better error messages
- Parallel service checking

**Examples**:

```bash
# HTTP
wait4x http http://localhost:3000 --timeout 30s

# TCP
wait4x tcp localhost:5432 --timeout 30s

# PostgreSQL
wait4x postgresql://localhost:5432
```

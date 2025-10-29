# MCP Integrations - Reference Guide

Advanced patterns and examples for journaling and social media sharing.

## Journal Integration Patterns

### Pattern 1: Problem-Solving Journey Documentation

When working through a complex problem, journal at key inflection points:

**Initial Struggle**

```text
mcp__journal__process_thoughts: "Started work on payment reconciliation. Service keeps failing during end-of-day batch. Error message is vague - 'timeout on line 42'. Going to add detailed logging."
```text

**Discovery**

```text
mcp__journal__process_thoughts: "Found the issue! It wasn't a timeout - it was a deadlock in the database connection pool. The batch process was opening 100+ connections but only closing 50. Root cause: forgotten conn.close() in error handler."
```text

**Solution**

```text
mcp__journal__process_thoughts: "Fixed the deadlock with proper connection pooling and context managers. Added integration test that reproduces the old failure. Learning: Always test error paths, not just happy path. Use context managers or finally blocks for cleanup."
```text

### Pattern 2: Performance Investigation Log

Track performance improvements over time:

```text
mcp__journal__process_thoughts: "Dashboard loading slow - 5 second TTFB. Profiled and found:
- 3 sequential API calls (should be parallel): 2.5s
- No memoization on heavy calculations: 1.5s
- Missing indexes on queries: 1s

Fixed API calls with Promise.all(), added React.memo(), added DB indexes. New TTFB: 600ms. 8x improvement!"
```text

### Pattern 3: Learning Moments

Capture insights that apply across projects:

```text
mcp__journal__process_thoughts: "Realized TypeScript discriminated unions solve our error handling. Instead of if-checks on type field, use type system to guarantee proper handling. Tested with payment service - eliminates entire class of bugs."
```text

### Pattern 4: Debugging Blockers

Use journaling to work through stuck moments:

```text
mcp__journal__process_thoughts: "STUCK: Tests failing intermittently, 80% pass rate. Tried:
- Resetting test database: No effect
- Running tests sequentially: All pass
- Examining test order: No obvious dependency

Theory: Async cleanup not completing before next test runs. Need to verify test cleanup order."
```text

Then later:

```text
mcp__journal__process_thoughts: "UNSTUCK: Added afterEach hook to verify cleanup completes. Was right - some cleanup functions were async but test runner didn't await them. Fixed with proper async/await. Now 100% pass rate."
```text

### Searching Your Journal Effectively

**Good Search Queries**:

- Technical terms: "async race condition", "TypeScript generics", "database index"
- Problem patterns: "timeout", "memory leak", "flaky test", "race condition"
- Technologies: "React hooks", "Docker networking", "Kubernetes"
- Emotions: "stuck", "frustrated", "breakthrough", "proud"

**Example Search Session**:

```text
You're starting work on a new async feature. Search: "async best practices"
Results show past entry about Promise.all() and cleanup - learn from what you wrote months ago.
```text

### Journal Entry Structure (Best Practices)

**Optimal Format**:

```text
[What]: What were you working on?
[Problem]: What blocker/insight occurred?
[Solution]: What did you do about it?
[Learning]: What will you do differently next time?
```text

**Example**:

```text
[What] Implementing image upload with optimization
[Problem] Uploads failing silently, no error messages in logs
[Solution] Added try-catch with detailed logging, discovered base64 encoding limit
[Learning] Always log at boundaries - API calls, encoding/decoding, async operations
```text

## Social Media Sharing Patterns

### Pattern 1: Feature Launch with Impact

```text
Use this when you've shipped a significant feature

🚀 [Feature Name] is live!

What it does:
- [Specific capability 1]
- [Specific capability 2]
- [Specific capability 3]

Impact:
- [Metric]: [Before → After]
- [User benefit]
- [Performance improvement]

Rollout: [Phased, gradual, or immediate]
```text

**Example**:

```text
🚀 Real-time Dashboard is live!

What it does:
- Live metrics updating every 5 seconds
- Historical data views
- Custom metric filtering

Impact:
- Load time: 4s → 600ms (85% reduction)
- Users can now make faster decisions
- Dashboard now serving 10x more concurrent users

Full rollout complete across all regions.
```text

### Pattern 2: Technical Achievement

```text
Use this when you've solved something technically elegant or difficult

🔧 [What]: [Technical accomplishment]

Challenge: [What was hard about this]
Solution: [How you solved it elegantly]
Impact: [Why this matters - performance, reliability, code quality]
Learning: [What others can learn from this]
```text

**Example**:

```text
🔧 Eliminated race condition in payment processing

Challenge: Payment webhooks arriving out-of-order, causing reconciliation failures
Solution: Implemented idempotent key strategy + ordered queue with deduplication
Impact: Zero failed reconciliations (was 0.3% failure rate), no data loss
Learning: Always design for out-of-order events in distributed systems. Idempotency is your friend.
```text

### Pattern 3: Bug Fix with Context

```text
Use this when you've fixed a production bug

🐛 [What]: Production issue resolved

Issue: [What users experienced]
Root Cause: [What went wrong in the code]
Fix: [How you fixed it, briefly]
Prevention: [What you added to prevent recurrence]
Impact: [How many users affected, when it's safe again]
```text

**Example**:

```text
🐛 Payment confirmation timeout issue resolved

Issue: Some users seeing "Pending" status indefinitely after successful payment
Root Cause: Async cleanup function in error handler wasn't being awaited, connection pool exhausted
Fix: Wrapped cleanup in proper async/await, added connection pooling limits
Prevention: Added integration tests that fail if connections aren't properly released
Impact: Affected 2.3% of daily transactions, all resolved now
```text

### Pattern 4: Team Collaboration Highlight

```text
Use this when celebrating a team effort

👥 [Achievement] thanks to [Team/Person]

What we accomplished:
- [Specific outcome 1]
- [Specific outcome 2]
- [Specific outcome 3]

How we worked together:
- [Collaboration style]
- [What made it effective]

Result: [Positive outcome]
```text

**Example**:

```text
👥 Shipped payment reconciliation in record time thanks to awesome QA collaboration!

What we accomplished:
- Complete rewrite of reconciliation engine
- 99.9% accuracy verification across 6 months of historical data
- Zero downtime migration

How we worked together:
- QA ran detailed validation scenarios daily
- Development fixed issues immediately
- Regular sync-ups on critical path items

Result: Shipped 3 days ahead of schedule with confidence.
```text

### Pattern 5: Learning Shared

```text
Use this when documenting something you learned that others should know

📚 [Insight/Lesson Learned]

Discovery: [What you found out]
Context: [When/why you discovered this]
Impact: [How this improves our work]
Try it: [How others can apply this]
```text

**Example**:

```text
📚 TypeScript discriminated unions eliminated entire class of runtime errors

Discovery: Using type guards + discriminated unions guarantees error handling
Context: Refactoring payment service error handling
Impact: Errors must be handled per status - impossible to miss cases
Try it: Define error union types, use switch on error.type, let compiler verify coverage

Result: 0 unhandled promise rejections in error-critical service. Highly recommend!
```text

### Timing Social Media Posts

**Optimal Timing**:

- **Immediately after launch**: Momentum is high, announcement is fresh
- **End of sprint**: Celebrate sprint accomplishments
- **Public milestone**: Anniversary, version number, reaching users
- **Learnings**: Anytime during the day
- **Bug fixes**: After verification and deployment

**Avoid**:

- Posting about incomplete work (creates false expectations)
- Posting about speculative fixes (confirm in production first)
- Posting when frustrated (take a break, post when calm)

## Advanced Journaling: The "Weekly Review" Pattern

Some teams use journaling for weekly team syncs. Pattern:

```text
mcp__journal__process_thoughts: "WEEKLY REVIEW - Week of [Date]

Completed:
- [Feature 1]: Shipped and verified
- [Feature 2]: Code review complete
- [Bug fix 1]: Deployed to production

Learned:
- [Technical insight 1]
- [Process improvement 1]
- [Tool discovery]

Blocked:
- [Current blocker 1]: [What's needed to unblock]

Next Week:
- [Priority 1]
- [Priority 2]
- [Priority 3]"
```text

Then use search to review past weeks and track patterns over time.

## Combining Journal & Social Media

**Workflow Example**:

```text
1. During development:
   - Journal when hitting interesting moments
   - Search journal when starting similar task

2. At task completion:
   - Review your journal entries about the work
   - Create social media post celebrating the accomplishment
   - Include metrics/learnings from journal entries

3. Next day:
   - Read team's social media posts
   - Learn from their approaches and celebrate their wins
```text

This creates a virtuous cycle:

- Journal documents personal learnings
- Social media shares knowledge with team
- Reading others' posts spreads learning across team
- Next task benefits from collective knowledge

## Token Usage Optimization

**Journal & Social Media are MCP Tools**:

- Tool definitions: ~200 tokens (always loaded)
- Skill metadata: ~100 tokens (always loaded)
- SKILL.md: ~2000 tokens (loaded only when skill activates)
- REFERENCE.md: ~3000 tokens (loaded only when you ask for it)

**Context Savings**:

- When not using journal/social features: Save 5000+ tokens
- When using: Load only what's needed via progressive disclosure
- Result: No baseline cost, full capability when needed

This is why we extract from CLAUDE.md into skills!

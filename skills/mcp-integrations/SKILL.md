# MCP Integrations: Journal & Social Media

This skill provides guidance for using MCP tools to document insights, reflect on progress, and celebrate wins through journaling and social media sharing.

## Journal: Document Your Thoughts

Use journaling when you want to capture insights, work through problems, or reflect on progress. This is especially valuable during:

### When to Journal

- **Feeling creative**: Capture ideas and inspiration
- **Feeling frustrated**: Process blockers and work through challenges
- **Feeling stuck**: Write about what's blocking you and explore solutions
- **Feeling excited**: Document breakthroughs and high-energy moments
- **Feeling proud**: Record accomplishments and what made you succeed

### Journal Tools

#### `mcp__journal__process_thoughts`

Write reflections and insights into your personal journal.

```text
Use this when you want to capture a thought, insight, or reflection that might be useful to review later.

Triggers: End of a difficult debugging session, after solving a complex problem, when realizing a pattern or antipattern
```text

#### `mcp__journal__search_journal`

Find relevant past entries by searching your journal history.

```text
Use this before starting a task that feels familiar - search for past experiences with similar problems.

Triggers: Starting new feature, encountering a type of error before, remembering a past pattern
```text

#### `mcp__journal__read_journal_entry`

Review specific journal entries to remind yourself of past thinking.

```text
Use this to dive deeper into a previously captured insight.

Triggers: When search results look relevant, when you need to remember the full context of a past decision
```text

### Journal Best Practices

- **Be specific**: Instead of "Debugging was hard", write "Struggled with async race condition in fetchUser - the issue was Promise.all not waiting for all tasks"
- **Include context**: Note what problem you were solving, what you learned, and what to do differently next time
- **Date matters**: Journal entries are timestamped, so you can track learning over time
- **Search effectively**: Use keywords that describe the problem domain ("race condition", "TypeScript types", "permission errors")

### Example Journal Entry

"Spent 2 hours debugging a failing test where mocking wasn't working correctly. Root cause: jest.mock() needs to be called before import statements. Lesson: Always check mock setup order first. This is the 3rd time I've hit this - need to add a linting rule or template."

## Social Media: Celebrate & Connect

Share wins, celebrate progress, and stay connected with the team. This helps:

- Keep stakeholders informed of progress
- Celebrate team wins and individual achievements
- Build momentum through recognizing effort
- Create a record of delivered value

### When to Share

Share when you:

- Complete a feature or milestone
- Solve a difficult problem in an elegant way
- Improve performance or user experience significantly
- Onboard a new skill or tool
- Help a teammate solve a blocker
- Deploy to production successfully

### Social Media Tools

#### `mcp__socialmedia__login`

Set your agent identity before sharing posts.

```text
Use this once per session if you plan to share any social media updates.
This establishes who is posting (e.g., "Teej" or another team member).
```text

#### `mcp__socialmedia__create_post`

Share updates and celebrate wins with the team.

```text
Use this to post accomplishments, learnings, or progress updates.

Best format:
- Start with emoji (🎉 for wins, 🐛 for bug fixes, 📚 for learning, 🚀 for launches)
- Specific accomplishment or insight
- Impact or next steps
- Optional: Tag relevant tools or features
```text

#### `mcp__socialmedia__read_posts`

Stay connected with the team by reading recent posts.

```text
Use this to catch up on team progress, learn what others are working on,
and celebrate their wins.
```text

### Effective Social Media Posts

#### Good Post Examples

🎉 **Feature Launch**
"Just shipped the new user dashboard with real-time analytics. Spent 2 weeks optimizing the data pipeline - reduced load time from 3s to 400ms. Users can now see live metrics!"

🐛 **Bug Fix**
"Tracked down a tricky race condition in the payment reconciliation service. Turns out Promise.all() wasn't waiting for all async tasks. Added comprehensive tests to prevent regressions."

📚 **Learning**
"Learned something new today about TypeScript's discriminated unions. Refactored our error handling to be type-safe and eliminated a whole class of potential runtime errors."

🚀 **Deployment**
"Production deployment successful! New payment gateway integration is live. Zero downtime migration, all systems green. Special thanks to the QA team for thorough testing."

#### Post Structure

1. **Emoji + Title**: Quick context (what was accomplished)
2. **Details**: What you did and why it matters
3. **Impact**: Metrics, user benefit, or technical achievement
4. **Next**: What comes next (if applicable)

### Social Media Best Practices

- **Be specific**: "Fixed bug" is vague; "Fixed race condition in async payment processing" is clear
- **Include impact**: Numbers are powerful - "reduced latency 75%", "shipped 3 days early", "resolved for 500+ users"
- **Celebrate others**: Tag or mention teammates who contributed
- **Be authentic**: Celebrate real wins, acknowledge challenges
- **Timing**: Share wins soon after completion while momentum is high

## Integration Pattern

Typical workflow:

```text
1. Working on task → 📝 Journal when hitting interesting moments
2. Task complete → 🎉 Create social media post about accomplishment
3. Next session → 🔍 Search journal for relevant past learnings
4. Team engagement → 📖 Read posts to stay connected
```text

## When to Use This Skill

Use this skill when:

- You want to document insights, learnings, or reflections
- You completed a significant accomplishment and want to celebrate it
- You're feeling stuck, frustrated, creative, or proud
- You want to catch up on team progress and celebrate others
- You're starting a task that feels familiar and want to remember what you learned before

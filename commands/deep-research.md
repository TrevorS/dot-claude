Deep‑research pipeline (planner → orchestrator → summarizer)

Input
• $ARGUMENTS – the user's research question

Required flow

1. **Invoke the agent named `@search-planner`** on "$ARGUMENTS".
   → Expect pure‑YAML output of the form

   ```yaml
   queries:
     - q: …
       reason: …
       source_hint: …
       freshness: …
   ```

2. **Pass that YAML unchanged to the agent named `@search-orchestrator`.**
   → Expect pure‑YAML output of the form

   ```yaml
   results:
     - query: …
       url: …
       snippets: […]
   ```

3. **Pass the orchestrator's YAML unchanged to the agent named `@search-synthesizer`.**
   – Unless the user included a flag like `as:faq` or `as:table`,
   also pass the key `output_format: "markdown report"`.
   → The synthesizer returns the final answer text.

Output
• Show the synthesizer's text exactly as returned.
• Do not display intermediate YAML or any tooling logs.

Rules
• Do not invoke any agents other than the three listed above.
• All inter‑agent payloads must remain YAML.
• The command itself performs no WebSearch, WebFetch, or Bash calls—those are handled by the sub‑agents.
• If the user supplies an `as:<format>` hint, forward it only to the synthesizer.

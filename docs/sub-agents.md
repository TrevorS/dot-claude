# Sub-Agent Efficiency Guidelines

## Maximize Parallel Processing While Avoiding Redundancy

- **Validate first, then parallelize**: When implementing multiple similar components, complete and test one fully before spawning sub-agents for the rest. This prevents multiple agents from making the same architectural mistakes in parallel.

- **Divide by context boundaries**: Split work along natural boundaries where sub-agents won't need to coordinate (separate files, independent features, distinct test suites). Avoid splitting work where agents would need to share implementation details.

- **Preserve critical context**: When delegating to sub-agents, include essential architectural decisions, error patterns from previous attempts, and specific requirements that aren't obvious from the code alone.

- **Batch related validation work**: Use sub-agents to run independent validation tasks in parallel (linting different directories, testing separate modules, checking different environments) rather than sequential execution.

- **Leverage for exploration and comparison**: Deploy sub-agents to explore different implementation approaches or research multiple solutions simultaneously, then consolidate findings before implementation.

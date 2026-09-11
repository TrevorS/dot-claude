# Prior art for writing kits

Why handing over material instead of a draft works, and what this skill copies. Gathered 2026-09-11.

## Evidence that a finished draft is the wrong handoff

- Design fixation. Jansson and Smith (1991) showed engineers a flawed example solution; they reproduced its features anyway, experts included. The draft is the flawed example. <https://cecas.clemson.edu/cedar/wp-content/uploads/2016/07/9-JanssonAndSmith1991.pdf>
- Homogenisation. Doshi and Hauser: GPT-4 ideas improved individual stories but made the set of stories more alike. Anderson, Shah, and Kreminski found the same for ideation. Padmakumar and He found writing with an instruction-tuned model reduced content diversity. <https://dl.acm.org/doi/10.1145/3635636.3656204> and <https://arxiv.org/pdf/2309.05196>
- Latent persuasion. Jakesch et al. (CHI 2023, 1,506 participants): an opinionated writing assistant shifted not only what people wrote but what they said they believed afterwards. Silent framing choices in a draft are the mechanism. <https://arxiv.org/abs/2302.00560>
- Ownership. Draxler et al., "The AI Ghostwriter Effect": people do not feel they own AI text yet sign it. Editing and iterative prompting each raise felt ownership. <https://arxiv.org/abs/2303.03283>
- Recall. Kosmyna et al. (2025): 83% of essay writers in the LLM group could not quote their own essay minutes later. <https://arxiv.org/abs/2506.08872>

## Research systems that hand over material, not text

- Sparks (Gero, Liu, Chilton 2022). Single generated sentences meant to inspire science writers. Used for angles, reader perspectives, and detail, not pasted. Closest to the fragments section. <https://arxiv.org/abs/2110.07640>
- Luminate (Suh et al., CHI 2024). <!-- codespell:ignore suh --> Generates the dimensions of a task first, then populates the space, because direct answers cause "rapid convergence on a limited set of ideas". Closest to the forks section, done as a UI. <https://arxiv.org/abs/2310.12953>
- ABScribe (CHI 2024). Multiple variations kept side by side so no one version is the draft. The variants rule. <https://arxiv.org/abs/2310.00117>
- Dang and Buschek (UIST 2022), "Beyond Text Generation". Continuous summaries of the writer's own text as an outside view. The check step, applied during writing. <https://arxiv.org/abs/2208.09323>

## Pre-AI practice with the same shape

- Bench memo. The clerk writes facts, issues, arguments, and a recommended disposition. The judge writes the opinion. Neutral by rule. <https://en.wikipedia.org/wiki/Bench_memorandum>
- Content brief. Marketing writers get title, outline, sourced facts, required links, and audience, and write the piece. <https://inlinks.com/insight/how-to-create-content-briefs/>
- Creative brief. Single-minded proposition, support, mandatories, tone. The "Your calls" and "Style notes" sections are the mandatories made optional.
- Working Backwards PR/FAQ. The FAQ half is "What the reader will ask", written before the reader asks. <https://workingbackwards.com/resources/working-backwards-pr-faq/>
- Shape Up. Shaped work is "rough, solved, bounded". Fat-marker sketches and breadboards exist because wireframes are too concrete and steal decisions from the builder. <https://basecamp.com/shapeup/1.3-chapter-04>
- Briefing books for speechwriters and ministers; the ghostwriter's interview transcript. Sourced material in, the person's voice out.

## Product patterns

- NotebookLM Briefing Doc, Study Guide, FAQ. Source-grounded outputs with citations back to the passage. Nearest shipping analogue to facts with provenance; stops at the summary and offers no forks.
- "Interview me first" prompts. The model asks questions until it has enough to write. Attacks the same problem from the input side. This skill puts those questions in the kit as blanks instead of blocking on them.

## What the kit adds that none of these name

- The forks section: the draft's silent choices listed with the alternative and when it wins. Luminate is nearest.
- Caveats bound to numbers on the same line.
- The check step as a distinct stage: the model lints the person's doc against the sources instead of rewriting it. Nothing found does this.
- The discovery draft as a required but non-delivered step. You only learn which facts are load-bearing by building the whole argument.

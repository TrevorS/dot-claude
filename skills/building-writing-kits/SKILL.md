---
name: building-writing-kits
description: Build a writing kit, everything a person needs to write a doc themselves (sourced facts, verbatim quotes, the choices a draft made, reader objections, open questions, blanks only they can fill) without the finished prose. Use whenever the user wants material or "inspo" to write a brief, memo, RFC, PR/FAQ, proposal, review, or post in their own words, says they will write it themselves, asks for research or a packet to write from, wants an existing draft taken apart into what went into it, or wants their finished doc checked against the sources. Trigger even when they do not say "kit": "I want to write this one", "give me what I need to write the brief", "don't write it, just get me the material".
when_to_use: "Typed as 'make me a kit', 'inspo doc', 'I want to write this myself', 'give me what I need to write the X', 'turn this draft into material I can write from', 'brief me for writing', or 'check my doc against the sources'. Not for docs the user wants written for them, and not for a Slack message, commit message, or status update; just write those."
argument-hint: "<target doc> [from <draft or source files>] | check <written doc>"
---

# Building Writing Kits

A kit is the material behind a document, handed over instead of the document. A finished draft anchors: the person edits sentences instead of thinking, and every framing choice the draft made silently becomes theirs. Raw research leaves them the blank page. The kit is everything load-bearing and nothing finished. [prior-art.md](references/prior-art.md) has the evidence if asked.

## Building a kit

1. Get the target, audience, destination (Notion and Google Docs want one line per paragraph), and length. Ask once at most; unknowns become blanks in the kit.
2. Build the fact ledger from every source the doc could draw on. Each fact carries where to check it (file and section, query and window, call and timestamp). A fact you cannot source is not in the ledger. A number and its caveat stay on one line, because the person will lift the line.
3. Write the full doc as a discovery draft. Not optional, not the deliverable: you only find out which facts are load-bearing and where the gaps are by building the whole argument. While writing, log every choice you make (which pain leads, plain or technical names, whether the competitor is named, how many numbers, which quote opens). Those are the forks, and they are invisible in a finished draft. If a draft already exists, mine it for forks instead.
4. Decompose into the format below. Then flatten the voice: plain declarative sentences everywhere except the labelled fragments, and there give three options, not one. Phrasing leaks into the person's doc.
5. Deliver one file, `<DOC>-KIT.md` beside the sources unless told otherwise. Keep the draft as a sibling whose first line is "One way it could read. Not the deliverable." The handoff message names the file, the section count, and the two or three forks most worth a look. Do not summarise the kit.

## Checking the written doc

When the person brings their doc back, lint it against the kit; do not rewrite it. List: numbers that differ from the ledger or lost their caveat; quotes altered or misattributed; claims with no source (ask where they came from; tacit is fine, but they should know it is unsourced); anything called decided that the sources say is open, or the reverse; which way each fork went, without judgement; any "has to answer" question no section answers.

Before calling a claim wrong, check every source that carries the fact, not only the kit's citation. Two sources that word it differently is a conflict to report, not an error in the doc. Say nothing about style or voice unless asked, and do not list what matched; the person wants what is off.

## Folding in a new source

When a call, a review, or a data pull arrives after the kit exists, write the delta first: decided (who, when), conflicts with existing docs by file, left open, action items with owners, and any line from the source that says the thing better than the docs do, verbatim. Then fold it in: add and re-mark with the date. Keep every sourced fact and quote the old kit had unless the delta names the moment that overturned it; folding is not a chance to reshape the kit.

## Format

Fixed pattern per section, so it is learned once and skimmed. Two to four times the target length. Every run of this so far has overshot, always the same way: the ledger copied in whole instead of filtered by each section's question. A section holds the facts its question needs, usually under ten; a fact no question needs becomes a pointer under Links. Past four times, the person is searching again, which is the failure the kit exists to prevent.

```markdown
# <Doc>: writing kit

<What this is, where the draft is, how to use them.>

## Shape
<Two or three layouts, what each suits, a length target, which one the draft used.>

## <Section>                                  <!-- repeat -->
Has to answer: <one question>
Facts:
- <fact> (<source>)
- <number, its caveat, same line> (<source>)
Fragments that fit, strongest first:
- "<verbatim quote>" <Name, Company, link or timestamp>
- <one-liner> / <one-liner> / <one-liner>
Your calls:
- <What the draft did.> <The alternative.> <When the alternative is better.>

## What the reader will ask
- "<objection, in the audience's voice>" Answered by: <fact (source)>, or "nothing in the sources"

## Where the sources disagree                  <!-- when a call, an old file, and the current doc differ -->
| Said or written | Current source says | Use |

## Risks and open questions
<Risks: what could make the doc wrong. Open: what nobody has decided. Decided items stay in their sections, say "decided", with date and source.>

## Only you know
<Blanks, as questions: what the audience already believes, politics, what was killed last time and why, what was promised to whom.>

## Links
<Every source.>

## Style notes from the draft
<The rules the draft followed, so they can be kept or dropped on purpose.>
```

Questions rather than headings, so the person can change the shape and still know what coverage they owe. Fragments over-supplied and ranked, because picking is cheaper than searching. Quotes verbatim with a name, never paraphrased. Objections nothing answers stay in; they say what the person will be asked and cannot yet defend, and each also goes in "Only you know".

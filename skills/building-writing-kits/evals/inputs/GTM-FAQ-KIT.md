# AI Mailroom GTM talking points and FAQ: writing kit

Material for writing the GTM talking points and FAQ for Jeff in your own words, on the two tracks Taylor named: "we will build what you asked for" and "here is how it works under the hood". Built 2026-09-18 from the docs repo as of commit 5e3d384 (2026-09-16). `GTM-FAQ-DRAFT.md` beside this file is the discovery draft the forks below came from; you do not need to read it. One line per paragraph so it pastes into Notion or Google Docs.

Source shorthand: (call m:ss) is `taylor-convo.md`, the Taylor sync of 2026-09-11. Where a fact reached the repo second-hand from Slack or Notion, the citation says "citing" and names the original; those were not re-checked for this kit.

## Shape

- Two tracks as two halves, then an FAQ. Suits Jeff's habit, per Taylor: "how should I talk about this? What user value does this have?" (call 57:22). The draft used this.
- FAQ only, each answer carrying a one-line talking point. Suits reps looking things up mid-call; loses the "we heard you" opening.
- One screen of talking points for reps plus a longer backgrounder for Jeff. Suits the case where reps can say little until Milestone 1 ships.
- Length: nothing in the sources sets one. The draft ran about 900 words. Taylor on this audience: "I don't want to come at them with like a bunch of documentation" (call 53:36).

## Purpose and audience

Has to answer: who reads this, and what should they be able to do after reading it?

Facts:
- Taylor's framing: a dual track for GTM, "both regaining their trust and confidence ... we get it ... We're gonna do everything that you have wished for, for a long time that hasn't been there. And also, here's some of how it works under the hood so that you can speak somewhat intelligently to it" (call 56:37).
- Action item from the call: draft GTM talking points and FAQ, share with Jeff (call 57:15, action item).
- Jeff "likes to kind of create these, like, FAQ docs for GTM"; Taylor: "we could give Jeff a draft to..." (call 57:22).
- Dillon, Stephen, Daryl and Wyatt are GTM and CS (BRIEF-KIT.md, The ask, citing the Notion initiative Pod table). Taylor: "They're like our most crucial people to keep engaged" (call 53:00).
- One Milestone 1 success measure is "Sales feedback: these demo well and match customers' AI expectations" (MILESTONE-1-DOC.md, Measuring success).

Fragments that fit, strongest first:
- For Jeff and GTM: what to say about AI Mailroom now. / What you can tell a prospect, and what you can't yet. / Two things: what we are building for you, and how it works.

Your calls:
- The draft wrote for Jeff and reps together. The alternative is a draft for Jeff alone that he turns into his own FAQ. Better if Taylor's "give Jeff a draft" is the plan.
- The draft marked the whole doc internal. The alternative is lines reps can say to prospects word for word. Better once Milestone 1 is live.

## Track 1: what GTM has been hearing

Has to answer: what went wrong with "AI" in the sales motion, stated so GTM knows we heard it?

Facts:
- Stephen Ritz, 2026-08-27: prospects ask "so where's the AI if I have to manually create these rules?" after the custom plan says "AI mail routing" (PREP-2026-09-15.md, citing Slack C01MM4E8HKR and Notion Customer Feedback).
- Prospects are disappointed by how we apply AI; a few deals and pilots are at risk because keyword routing does not do what they need (PROJECT-DOC.md, Why now).
- Turo: keyword rules work for Geico to Claims and fail on "Wage Garnishments" and "Injury Rep Letter", where any keyword set is too broad or too narrow (PREP-2026-09-15.md, citing Dillon in #product 2026-09-09). C-1 calls this "the deal-at-risk item (Turo pilot)" (tickets/C-1-llm-conditions.md).
- NetCredit wants a document type in the webhook payload to route to teams; null goes to an unassigned queue (PREP-2026-09-15.md, citing Dillon 2026-09-10).
- US Global Mail launched "AI Mailroom" on Product Hunt 2025-10-01 and an MCP server 2026-09-08. Their pitch: "summarized, categorized, and labeled mail before opening", "route, label, or archive automatically by sender or type" (PREP-2026-09-15.md, citing the Notion competitor page).
- The mailroom "was the most tech-forward product on the market when it shipped and is not any more" (PROJECT-DOC.md, Why now).

Fragments that fit, strongest first:
- "We were expecting more with the added AI feature." Ashley Conner, Synergy Medical Group, 2026-01-19, https://fathom.video/share/nFWcDxAf4Vx6qcJSutxGUU_DTt7wwFY7?timestamp=283
- "So outside of the rules with these specific words, is Stable doing anything like utilizing AI?" Su-Han Wang, Checkr, 2026-05-12, https://fathom.video/share/QwR4cYusjAtnNtp1_rMTSpcBwsBWQ74T?timestamp=746
- We heard you. / You have been selling around a gap. / "AI mail routing" has meant keyword rules, and prospects noticed.

Your calls:
- The draft opened with the admission. The alternative opens with what is coming. The admission is better if GTM already feels burned; skip it if Jeff would read it as blame.
- The draft named Turo, NetCredit and US Global Mail. The alternative is "a pilot", "a customer", "a competitor". Names are better for an internal doc; the kickoff page named Turo but no employees (KICKOFF.md, Decisions).

## Track 1: what we are building, in order

Has to answer: what does each milestone give a customer, and what is not coming?

Facts:
- Milestone 0, Run it: the model runs in production on a cohort, results go to a table, nothing is visible to any customer. "GTM gets nothing yet, on purpose" (MILESTONE-0-DOC.md, Who needs this).
- Milestone 1, See it, as of 2026-09-16: badges for action needed, returned mail, and a due date shown relative to today ("due in 7 days", "due today", "past due"); filters on action required, document type, sender category, sender, handled status and due-date range; a detail panel with the supporting sentence on hover; the facts in the hourly new-scan email (MILESTONE-1-TIP.md, Time at render and Scope).
- Not in Milestone 1: routing, search, REST or webhooks, sort, assignment, snooze, facts in Slack notifications (MILESTONE-1-TIP.md, Scope).
- Milestone 2, Act on it: detected actions become Tasks the customer can complete or dismiss; routing-rule conditions on the facts; REST and webhooks (PROJECT-DOC.md, What customers get; MILESTONE-1-TIP.md, Scope Out).
- Milestone 3, Make it yours, marked "potential": customer-defined document types usable in filters and rules, free-text rule conditions, a triage API for the chatbot and MCP (PROJECT-DOC.md, Milestones). Renamed "Milestone X" on Notion 2026-09-14 (PREP-2026-09-15.md).
- Turo dry run: their sheet (46 categories, 8 departments) run over 200 letters from other customers; 72 were assigned a category, none to a wrong department by inspection. The rest went to "other", correct for mail that is not theirs (spike/CUSTOMER-TAXONOMY.md, Result).
- Structured conditions in Milestone 2 cover "document type is tax notice" but not "unemployment claims to HR" or "W-2 to payroll"; keyword complaints persist without free text. C-1 leans toward shipping both (tickets/C-1-llm-conditions.md).
- Nothing in Milestone 1 automates an action (PREP-2026-09-15.md, Likely questions).

Fragments that fit, strongest first:
- "I only want to see things that need my attention." Allexis Licciardi, Marc L. Schwartz, 2025-12-19, https://fathom.video/share/J861j8wLeH8YketDqV-KKdLMUn23x3AT?timestamp=413
- "If I wanted to say I want all unemployment claims from all states to route to HR, we could automate that without having to automate each state's unemployment?" Trish Daigler, Life360, 2026-06-22, https://fathom.video/share/zZPgKa_sDFCg7_GzdMpEuqz5JzRyfMPw?timestamp=619
- See it, act on it, make it yours. / First it tells you, then it acts, then it learns your categories. / Step one is the mailroom telling you which letters matter.

Your calls:
- The draft used the milestone names. The alternative is "first, next, later" with no names. Names are better if GTM will see them in Linear or Notion; they changed twice in a week.
- The draft mapped each GTM ask to a milestone. The alternative lists milestones only. The mapping is what track 1 promises, and it shows Turo's case is Milestone 3, not 2.
- The draft listed what is not coming. The alternative leaves it out. Listing it prevents the next "where's the AI" moment.

## Track 1: when

Has to answer: what can a rep say about timing without making a promise?

Facts:
- No milestone has a date. Milestone 1 reaches customers when badges, filters and email pass bug bash; Milestones 2 and 3 are not dated (PROJECT-DOC.md, Timelines).
- Rollout is per organisation behind a flag, then wider cohorts, then on by default for every organisation except the opt-outs (research/07-rollout-and-operations.md, Rollout).
- New scans only. History is not back-filled for customers (research/README.md, Decided 2026-09-16).
- Scanned mail only; about 98% keep auto-scan on, and legacy customers still need it flipped (call 34:54 to 35:16).

Fragments that fit, strongest first:
- No date yet. / It arrives in stages, starting with a small group. / Ask me before you promise a quarter.

Your calls:
- The draft said "no dates, do not quote one" and later mentioned that AI Mailroom is a Q4 focus initiative (PROJECT-DOC.md, Why now). The alternative drops Q4. A rep will hear Q4 as a ship date.
- The draft offered no design-partner path. The alternative offers prospects a spot in the early cohort. Only if Taylor and Sarah agree; they own the design-partner list (MILESTONE-0-TIP.md, Pre-work).

## Track 2: the idea

Has to answer: what is the one mechanism a rep should be able to explain in a sentence?

Facts:
- "The model reads, code decides" (PROJECT-DOC.md, Principles).
- The definitions live in a taxonomy we wrote, not in a prompt; prompt, tests and UI follow it, so the model can be swapped and measured against a fixed target (PROJECT-DOC.md, What Stable gets).
- One model call per scanned letter after OCR, about 4 seconds, output constrained to a fixed schema (MILESTONE-1-DOC.md, Requirements and Accuracy so far).
- Who the letter is to comes first. A cc copy, a creditor notice or the customer's own returned mail creates no obligation; only the addressee can get a task (PROJECT-DOC.md, Principles).
- Only what is printed. If the letter does not say, the value is empty. "A wrong date is worse than no date" (PROJECT-DOC.md, Principles).

Fragments that fit, strongest first:
- "... the sort of naive way to do this, is to just make a simple prompt that says something like, you know, is this document urgent or not? But that sort of hands off so much responsibility to the LLM" Trevor, call 54:10
- We wrote a model of mail; the AI fills it in. / The AI reads the letter; our rules decide what it means. / It is not "send it to ChatGPT and see what comes back".

Your calls:
- The draft used plain words ("facts", "fields"). The alternative is "primitives". Plain is better for this audience; "primitives" is the internal word (BRIEF-KIT.md, Title).
- The draft explained who-is-it-to. The alternative skips it. It is the least obvious part and the reason a cc copy does not become an action item.

## Track 2: what runs, where, and the data question

Has to answer: which model, where does the mail go, and is it used for training?

Facts:
- Gemma 4 31B, Google's open model, on Amazon Bedrock (spike/MODELS.md, RC1 configuration; call 17:03).
- Data stays in Stable's AWS account: same Bedrock setup as summaries, same opt-out (PROJECT-DOC.md, Principles). Bedrock keeps data in-account and does not train on it (spike/MODELS.md, Self-hosting economics).
- AI opt-outs are contractual; the six organisations are skipped before any model call (research/README.md, Decided 2026-09-16).
- Bake-off: Claude Opus 5 scored within noise at 50 times the price; Claude Haiku 4.5 scored lower on every judgement field at 10 times (MILESTONE-1-DOC.md, Accuracy so far).
- Cost about a tenth of a cent per letter, under the OCR step before it (PROJECT-DOC.md, Principles).
- Customers see the supporting sentence from the letter, never the model's reasoning or a confidence number (MILESTONE-1-DOC.md, Requirements).

Fragments that fit, strongest first:
- "I don't want to do away with the AI, but I am concerned about training external language models with our data." Marland Taylor, Eden Housing, 2026-05-21, https://fathom.video/share/vef3QtBEcc58-naT7BNsxcr_TqTWWBF8?timestamp=2162
- An open model in our own AWS account. / Same place your summaries already run. / We tested the expensive models; they were not better.

Your calls:
- The draft named Gemma, Google and Bedrock. The alternative says "a model running in Stable's AWS account". Naming answers "is it OpenAI"; "Google" may raise "does Google read my mail".
- The draft included the Opus bake-off and left cost out. The alternative cuts the bake-off. Keep it if prospects push on "why not the best model".

## Track 2: how good it is, and what happens when it is wrong

Has to answer: what accuracy can GTM repeat, with what caveat, and what does the customer do about a mistake?

Facts:
- On 200 real letters, labels not yet human-reviewed: who it is to 98%, document type 89%, action required 91%, sender 93%, consequence 84%, printed due dates 33 of 34, invented due dates 9 of 166 (MILESTONE-1-DOC.md, Accuracy so far).
- The invented-date rate is 5.4%, above the spike's own 5% bar; not yet passing (research/README.md, What the research changed).
- The ship number comes after a human pass on 107 contested labels and one run on 200 untouched letters (MILESTONE-1-DOC.md, Gates).
- A correction stays until a person changes it; a model re-run never overwrites it. Admins can correct in Milestone 1 (MILESTONE-1-TIP.md, Principle and Decisions).
- Whether the correction control ships in Milestone 1, or only the back end plus "report a problem", is open (MILESTONE-1-TIP.md, Open questions 7).

Fragments that fit, strongest first:
- "Is there an opportunity to say, jokes on you, Stable, this actually belongs to credentialing?" Torrin King, Privia Health, 2026-03-20, https://fathom.video/share/yQJUH_fPophds1LbmiGjxuR_ETAE6d1z?timestamp=961
- About nine in ten. / It shows its work: the sentence from the letter. / Your fix sticks.

Your calls:
- The draft gave "about nine in ten" and 33 of 34 with the caveat. The alternative gives no numbers until the held-out run. Numbers repeated in sales outlive their caveat.
- The draft promised "your correction sticks". The alternative says corrections are coming. The promise is only safe if the correction control ships in Milestone 1.

## FAQ: questions customers asked on calls

Has to answer: which questions will prospects actually ask, and what is the sourced answer to each?

Facts:
- "How do we know that what you read with your AI is still private for us?" Erika von Zoog, SCS Global Services, 2026-04-21 (customer-quotes.md §7). Answered by: in-account Bedrock, no training, opt-outs skipped (spike/MODELS.md; research/README.md).
- "Is it easy for the AI to know when you get junk mail, like a marketing flyer versus some important mail, like a legal notice?" C. Vasconcellos, SoundHound, 2026-03-25 (customer-quotes.md §3). Answered by: marketing always has action required false (BRIEF.md, Rules that hold on every path).
- "Is there a way for something to get flagged to the team that, hey, this looks to be super urgent?" Tracey Springstead, For Wellness, 2026-03-20 (customer-quotes.md §1). Answered by: action-needed and due-date badges, the due-within filter, the email line; no "urgent" label (MILESTONE-1-TIP.md).
- "Would you have to set up a routing rule for every case?" Stefanie Cotton, 222 Injury Lawyers, 2026-06-08 (customer-quotes.md §5). Answered by: routing on the facts in Milestone 2, on customer categories in Milestone 3 (PROJECT-DOC.md).
- "If there's someone's social security number on something, can Stable recognize that and make sure it only gets applied to the People [team]?" Teresa Schofield, Generate Capital, 2026-03-30 (customer-quotes.md §4). Answered by: nothing in the sources (C-1 lists it as a free-text want).
- Will it tag mail I already have? Answered by: new scans only (research/README.md).
- What does it cost the customer, and which plans get it? Answered by: nothing in the sources.

Fragments that fit, strongest first:
- Short answer, then why. / Answer, then the milestone. / Yes, no, or not yet, then the reason.

Your calls:
- The draft wrote its own FAQ questions. The alternative uses these verbatim customer questions. Verbatim questions are the ones reps will hear.
- The draft answered "When?" with Q4. See Track 1: when.

## What the reader will ask

- Jeff: "When can we sell it?" Answered by: no dates; Milestone 0 is invisible to customers on purpose (PROJECT-DOC.md, Timelines; MILESTONE-0-DOC.md).
- Jeff: "Can reps demo it?" Answered by: nothing live; mockups exist in the design project; demos for Dillon, Stephen, Daryl and Wyatt were planned (call 52:47). Reps showing mockups: nothing in the sources.
- Dillon: "What do I tell Turo?" Answered by: their keyword failures need Milestone 3 categories or free-text conditions; the dry run on their sheet exists; no date (spike/CUSTOMER-TAXONOMY.md; tickets/C-1-llm-conditions.md).
- Stephen: "Can I still say 'AI mail routing' on the custom plan?" Answered by: nothing in the sources.
- "Is this the same as US Global Mail's AI Mailroom?" Answered by: their pitch (Track 1 above) against ours, which adds action, due date, consequence and the supporting sentence (BRIEF.md). No direct comparison in the sources.
- "Does it pay the bill or file the form for them?" Answered by: no; nothing in Milestone 1 automates an action (PREP-2026-09-15.md).

## Where the sources disagree

| Said or written | Current source says | Use |
| --- | --- | --- |
| BRIEF.md, PROJECT-DOC.md, MILESTONE-1-DOC.md, KICKOFF.md: urgency high/normal/low, an "urgent" badge and filter | research/README.md, MILESTONE-1-TIP.md, 2026-09-16: no urgency attribute; badges action needed, returned mail, due in N days, past due | 2026-09-16; no "urgent" label |
| KICKOFF.md, README.md, BRIEF.md, DESIGN-BRIEF.md: notifications in Milestone 2 | call 20:03, PROJECT-DOC.md, MILESTONE-1-TIP.md: email line in Milestone 1 | Milestone 1 |
| Trevor to Katya, 2026-09-08: Milestone 1 includes "routing rules as conditions" (PREP-2026-09-15.md) | PROJECT-DOC.md, MILESTONE-1-TIP.md: routing conditions are Milestone 2 | Milestone 2. GTM may have heard the earlier version |
| Call 17:03: Gemma "beat Opus ... five times less the cost" | spike/MODELS.md: Opus within noise at 50 times the price | 50 times, within noise |
| README.md, 2026-09-10: RC1 "passes every gate criterion" | research/README.md, 2026-09-15: invented dates at 5.4%, above the 5% bar | not yet passing |
| Call 29:57, MILESTONE-1-DOC.md: document type computed, not shown yet | MILESTONE-1-TIP.md: a filter in Milestone 1, no badge | filter yes, badge undecided |
| Name: "AI Mailroom" (README.md), "AI enriched mail metadata" (PROJECT-DOC.md), "AI Primitives" (Collin, research/README.md) | Taylor decides (research/README.md); US Global Mail already uses "AI Mailroom" (PREP-2026-09-15.md) | ask Taylor first |

## Risks and open questions

Risks:
- Over-promising again. The custom plan said "AI mail routing" before routing used AI; Milestone 1 still has no routing.
- Accuracy numbers repeated without "before human review", and before the held-out run.
- A customer sees a wrong fact and has no way to fix it, if the correction control slips out of Milestone 1.
- Turo hears "Milestone 2 has routing on the facts" and expects their garnishment rule to work; it needs Milestone 3 or free text.

Open:
- Customer-facing name (Taylor).
- Badge wording and which facts show on the row (MILESTONE-1-TIP.md, Open questions 6).
- Correction control in Milestone 1 (same, 7).
- Free-text rule conditions: whether and when (tickets/C-1-llm-conditions.md).
- Sender normalisation, so "from the IRS" routes as one sender (MILESTONE-1-DOC.md, Product 3).
- The list of at-risk deals and what each is missing; Taylor asked for it (PROJECT-DOC.md, GTM 1).

## Only you know

- Is this doc the final GTM FAQ, or a draft Jeff rewrites into his own?
- What was GTM promised before and not given (call 56:37)? The July LLM-conditions spec is a candidate; nothing says what Sarah or Turo were told.
- What does Jeff already believe about the project, and has he seen the project page?
- May reps say anything to prospects, or show the design mockups, before Milestone 1 ships?
- Can Turo, NetCredit and US Global Mail be named in a doc that GTM will forward?
- Pricing and plan: included, add-on, or plan-gated.
- Whether Taylor co-signs; the dual track was Taylor's framing.
- What to tell a customer who asks to route on a social security number; the sources have no answer.
- Whether "AI mail routing" stays on the custom plan page until Milestone 2.

## Links

- Taylor call: `taylor-convo.md`; https://fathom.video/calls/820377797 (dual track at 56:37)
- Project page body: `PROJECT-DOC.md`; Notion https://app.notion.com/p/3c1e5d85e7518026bcfbebee7b9602ec
- Milestones: `MILESTONE-0-DOC.md`, `MILESTONE-1-DOC.md`, `MILESTONE-1-TIP.md`
- Decisions of 2026-09-16: `research/README.md`
- Prep for the 2026-09-15 review, with the Slack and Notion sources for GTM facts: `PREP-2026-09-15.md`
- Customer quotes with Fathom links: `customer-quotes.md`
- Model and cost: `spike/MODELS.md`; custom categories: `spike/CUSTOMER-TAXONOMY.md`
- Tickets and scope history: `tickets/C-1-llm-conditions.md`, `KICKOFF.md`, `DEFERRED.md`, `BRIEF.md`, `BRIEF-KIT.md`
- Design project: https://claude.ai/design/p/41e529af-8d8b-4581-9ed0-f7940d799a47

## Style notes from the draft

- Admission first, then the plan, then "nothing is live".
- Plain words (facts, letters, badges); no "primitives", no field names.
- One numbered paragraph per milestone, in what the customer sees; each GTM ask mapped to one.
- Numbers in one place, caveat on the same line. FAQ answers short-answer first.
- No dates, except the Q4 mention flagged under Track 1: when.

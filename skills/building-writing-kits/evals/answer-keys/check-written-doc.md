# Answer key: eval 2, check-written-doc

Not part of the fixture. The fixture is `GTM-FAQ-TREVOR.md` (the draft) and `GTM-FAQ-KIT.md` (the kit, copied unchanged from `eval-0/GTM-FAQ-KIT.md`). Source paths are relative to the docs repo; line numbers are from the `docs-0` copy. Draft line numbers are `D<n>`, kit line numbers `K<n>`.

## Planted errors

| # | Draft line | Draft says | Correct | Source |
| --- | --- | --- | --- | --- |
| 1 | D72 | document type 92% | 89% | `MILESTONE-1-DOC.md:83` (`\| Document type \| 89% \|`); `spike/MODELS.md:204` (docType 0.89 / 0.89); K138 |
| 2 | D72 | the accuracy line has no caveat anywhere in the draft | labels have not yet had a human pass; the ship number comes after the human pass on 107 contested labels and one run on the held-out 200 | `MILESTONE-1-DOC.md:91` ("against labels that have not yet had a human pass"), `:95-96`; `KICKOFF.md:22` ("labeled pre-human-review, one caveat line"); K138, K140, K197 |
| 3 | D22 | "Honestly, I just want to see the things that need my attention." Allexis Licciardi, Marc L. Schwartz | "But for me, I only want to see things that need my attention." Speaker and company are right | `customer-quotes.md:90-91` (also the headline table at `:24`); K68 |
| 4 | D23 | "I'm like, bro, this was an IRS letter we could have responded to two weeks ago." Cailie Ryan, Numeral | Text verbatim; company is Snorkl. Numeral is Emily Coleman's company | `customer-quotes.md:63-64` (and `:22`); Emily Coleman, Numeral at `:59-62` |
| 5 | D46 | Three enterprise customers have already signed up for the pilot. | No source. No `.md` file in the repo contains "enterprise" or "signed up"; the design-partner list is owned by Taylor and Sarah and nothing records a sign-up | `grep -rni "enterprise\|signed up"` returns nothing; K92 (`MILESTONE-0-TIP.md`, Pre-work) |
| 6 | D34 | Decided: notifications ship in the first milestone. | Not decided anywhere in writing. The locked kickoff decisions put notifications in M2; the Taylor call only discussed moving them ("What make YM2 instead of M1?" / "No reason. We can move them around"). Slack notifications are explicitly out of M1, and email timing is marked Needs alignment | `KICKOFF.md:11` (M2 ships "notifications"; file header "Locked with Trevor"); `README.md:88`; `BRIEF.md:142`; `DESIGN-BRIEF.md:26`; `taylor-convo.md` 19:53 to 20:32 (lines 157-170); `MILESTONE-1-TIP.md:131` (Slack notifications out), `:159` (Email timing, Needs alignment) |
| 7 | D64 | Claude Opus 5 scored the same within noise at five times the price. | 50 times the price | `MILESTONE-1-DOC.md:91`; `spike/MODELS.md:209` ("Opus 5 at 50x the price"); `PREP-2026-09-15.md:36` (the "5 times" figure was a misstatement to Taylor); K121, K188 |
| 8 | D62 | the four organisations that opted out | six | `research/README.md:24`, `:90`; `MILESTONE-1-DOC.md:126`; `research/07-rollout-and-operations.md:18`; `PREP-2026-09-15.md:41`; K120 |
| 9 | D74-76 | "When it is wrong" is one sentence: the customer can see the evidence sentence | Thin. Dropped relative to the kit: a correction stays until a person changes it and a re-run never overwrites it (K141); admins can correct in M1 (K141); whether the correction control ships in M1 at all is open (K142, K150, K198). Also dropped relative to the sources: the whole-item feedback UI is undesigned and milestone-unassigned; until the correction UI lands, "report a problem" goes to PostHog; an "AI can make mistakes" disclaimer is a ticketed task and no such text exists yet | `MILESTONE-1-TIP.md:42`, `:121`, `:153`, `:205`; `MILESTONE-1-DOC.md:55`, `:121`; `taylor-convo.md:234` (action item: design mail-item feedback UI); `tickets/B-2-cards-and-details.md:15`; `research/05-notifications-and-dashboard.md:29` |
| 10 | D19 vs D21-26 | "falls into five groups", then six labelled quotes (letdown, noise, deadlines, knowing what it is, routing by meaning, privacy) | internal inconsistency: six groups, six quotes | the draft itself |

Notes on the planted errors:

- Error 6 is contestable against the current sources. `PROJECT-DOC.md:45`, `:83` and `MILESTONE-1-TIP.md:120` put the notification email line in Milestone 1, and the kit's "Where the sources disagree" table resolves it to Milestone 1 (K186). What is wrong in the draft is the word "Decided" and the bare "notifications": no source marks it decided, and Slack notifications are out of M1. A checker that reads the kit's resolution may call the line correct. The draft's own M1 paragraph (D32) deliberately does not mention the email, so D34 stands alone.
- Error 9: the kit in this fixture does not carry the undesigned feedback UI, a liability position, or the AI-can-make-mistakes disclaimer. The first and third exist in the sources (cited above). No liability position exists in the kit or anywhere in the docs repo. The draft drops all of them plus the kit's correction facts.
- Error 7: the call itself (`taylor-convo.md:154`, 17:03) says "five times less the cost"; the written sources and the kit say 50. A checker citing only the call would miss it.

## Every other checkable fact in the draft

| Draft line | Claim | Source |
| --- | --- | --- |
| D3 | Two tracks, Taylor's framing: we will build what you asked for, and how it works under the hood | `taylor-convo.md:716-717` (56:37); K3, K19 |
| D9 | Stephen: prospects see "AI mail routing" on the custom plan and ask "so where's the AI if I have to manually create these rules?" | `PREP-2026-09-15.md:25`; K37 |
| D11 | Turo's keyword rules work for Geico to Claims and fail on "Wage Garnishments" and "Injury Rep Letter", where any keyword set is too broad or too narrow | `PREP-2026-09-15.md:22`; K39 |
| D13 | NetCredit wants a document type in the webhook to route each letter to a team | `PREP-2026-09-15.md:23`; K40 |
| D15 | US Global Mail launched "AI Mailroom" on Product Hunt on 1 October 2025 | `PREP-2026-09-15.md:24`; K41 |
| D19 | Quotes come from calls | `customer-quotes.md:3` (Fathom call transcripts) |
| D21 | "We were expecting more with the added AI feature." Ashley Conner, Synergy Medical Group | `customer-quotes.md:210-211`; K45 |
| D24 | "I think some of the struggle is identifying that it is a tax notice." Michael Burke, Alpaca | `customer-quotes.md:27` (headline table, exact); `:109-110` (same sentence, longer quote) |
| D25 | "If I wanted to say I want all unemployment claims from all states to route to HR, we could automate that without having to automate each state's unemployment?" Trish Daigler, Life360 | `customer-quotes.md:160-161` (and `:29`); `PROJECT-DOC.md:51`; K69 |
| D26 | "I don't want to do away with the AI, but I am concerned about training external language models with our data." Marland Taylor, Eden Housing | `customer-quotes.md:204-205`; K126 |
| D30 | Milestone 0, Run it: model in production on a cohort, nothing visible to customers; "GTM gets nothing yet, on purpose" | `MILESTONE-0-DOC.md:10`, `:16`, `:24`; K58 |
| D32 | Milestone 1, See it: badges for action needed, returned mail, due date relative to today ("due in 7 days", "due today", "past due") | `MILESTONE-1-TIP.md:91`; K59 |
| D32 | Filters on action required, document type, sender, due-date range | `MILESTONE-1-TIP.md:92` (`actionRequired`, `documentType`, `senderKey`, `dueDate` as a range) |
| D32 | Detail view shows each fact with the supporting sentence | `MILESTONE-1-TIP.md:119`; `MILESTONE-1-DOC.md:43` |
| D36 | Milestone 2, Act on it: detected actions become Tasks the customer can complete or dismiss; routing rules match on the facts instead of keywords | `PROJECT-DOC.md:46`; K61 |
| D36 | REST and webhooks are Milestone 2 | `MILESTONE-1-TIP.md:129`; `research/README.md:42`; K61 |
| D38 | Milestone 3, Make it yours, marked potential: customer-defined document types in filters and routing rules; free-text rule conditions | `PROJECT-DOC.md:47`, `:85`; K62 |
| D38 | Turo's case needs Milestone 3 | K74, K176, K199; `tickets/C-1-llm-conditions.md` |
| D38 | Turo sheet: 46 categories across 8 departments, run on 200 letters from other customers (the 200-item dev set; the draft said "over 200" until 2026-09-18, which a checker rightly read as more than 200); 72 assigned a category; none to a wrong department by inspection | `spike/CUSTOMER-TAXONOMY.md:13`, `:29`, `:34`, `:35`; `PREP-2026-09-15.md:22`; K63 |
| D40 | Nothing in M1 routes mail | `MILESTONE-1-TIP.md:127`, `:161`; `research/README.md:40`; K60 |
| D40 | Nothing in M1 automates an action | `PREP-2026-09-15.md:42`; K65 |
| D40 | No sort, assignment, snooze | `MILESTONE-1-TIP.md:136`; `MILESTONE-1-DOC.md:49`; K60 |
| D44 | No milestone has a date | `PROJECT-DOC.md:90`; K82 |
| D46 | Rollout per organisation behind a flag, then wider cohorts, then on by default except the opt-outs | `research/07-rollout-and-operations.md:91`, `:94`, `:95`; `research/README.md:43`; K83 |
| D48 | New scans only; history not tagged | `research/README.md:39`; `MILESTONE-1-TIP.md:158`, `:160`; K84 |
| D48 | Scanned mail only; about 98% keep auto-scan on | `taylor-convo.md:334` (34:54); `PREP-2026-09-15.md:26`; K85 |
| D54 | The model of mail: what the document is, who it is for, whether the business must act, by when, what happens if not, who sent it | `PROJECT-DOC.md:17` |
| D54 | Definitions live in a taxonomy we own, not a prompt; lets us swap models and measure against a fixed target | `PROJECT-DOC.md:55`; K100 |
| D54 | The model reads, code decides | `PROJECT-DOC.md:74`; K99 |
| D56 | One model call per scanned letter after OCR, about 4 seconds, output constrained to the schema | `MILESTONE-1-DOC.md:25`, `:39`, `:91`; K101 |
| D58 | Who it is to comes first; cc copy, creditor notice, own returned mail carry no obligation | `PROJECT-DOC.md:76`; K102 |
| D58 | Only what is printed; empty if not printed; a wrong date is worse than no date | `PROJECT-DOC.md:75`; K103 |
| D62 | Gemma 4 31B, Google's open model, on Amazon Bedrock | `spike/MODELS.md:152`; `MILESTONE-1-DOC.md:39`; `taylor-convo.md:154` ("open source Google model"); K118 |
| D62 | In Stable's AWS account, same setup as AI summaries | `PROJECT-DOC.md:78`; K119 |
| D62 | Bedrock keeps data in-account and does not train on it | `spike/MODELS.md:130-131`; K119 |
| D62 | Opt-outs are contractual and skipped before any model call | `research/README.md:47`; `MILESTONE-1-DOC.md:39`; K120 |
| D64 | Opus 5 within noise (the "within noise" part is right; only the multiple is wrong) | `MILESTONE-1-DOC.md:91` |
| D66 | About a tenth of a cent per letter, less than the OCR step before it | `PROJECT-DOC.md:79`; K122 |
| D68 | Customers see the supporting sentence, never the model's reasoning or a confidence number | `MILESTONE-1-DOC.md:43`, `:51`; `PROJECT-DOC.md:77`; K123 |
| D72 | 200 real letters; who it is to 98%; action required 91%; sender from the letterhead 93%; consequence 84%; printed due dates 33 of 34 | `MILESTONE-1-DOC.md:82`, `:84`, `:85`, `:86`, `:87`, `:91`; K138 |
| D81 | Marketing always has action required false; an offer's "respond by" date is not a deadline | `BRIEF.md:99`; K158 |
| D84 | No "urgent" label; action needed and due-date badges; filter by due within a window | `MILESTONE-1-TIP.md:15`, `:91`, `:92`, `:149`; K159, K185 (older docs `MILESTONE-1-DOC.md:41` still list an "urgent" badge; the kit resolves the disagreement to no "urgent" label) |
| D87 | Nothing in Milestone 1 automates an action | `PREP-2026-09-15.md:42`; K179 |
| D90 | Summaries stay on their own pipeline; the facts sit beside them | `PROJECT-DOC.md:21` |
| D93 | Cost to the customer and plan: no answer given | nothing in the sources (K163, K216); the draft makes no claim |

Uncheckable by design: D3 "Internal" (Trevor's call, K30), D44 "do not quote one" and D93 "check with me first" (instructions to the reader).

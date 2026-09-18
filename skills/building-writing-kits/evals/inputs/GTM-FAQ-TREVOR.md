# AI Mailroom: talking points and FAQ for GTM

For Jeff and the sales team. Internal. Two tracks, the way Taylor framed it: we will build what you asked for, and here is how it works under the hood.

## Track 1: we will build what you asked for

### What you have been hearing

From Stephen: prospects see "AI mail routing" on the custom plan and ask "so where's the AI if I have to manually create these rules?"

Turo's keyword rules work for Geico mail going to Claims, and fail on "Wage Garnishments" and "Injury Rep Letter", where any keyword set is too broad or too narrow.

NetCredit wants a document type in the webhook so they can route each letter to a team.

US Global Mail now sells an "AI Mailroom" of its own, launched on Product Hunt on 1 October 2025.

### What customers told us

What customers asked for on calls falls into five groups:

- The letdown: "We were expecting more with the added AI feature." Ashley Conner, Synergy Medical Group
- The noise: "Honestly, I just want to see the things that need my attention." Allexis Licciardi, Marc L. Schwartz
- Deadlines: "I'm like, bro, this was an IRS letter we could have responded to two weeks ago." Cailie Ryan, Numeral
- Knowing what it is: "I think some of the struggle is identifying that it is a tax notice." Michael Burke, Alpaca
- Routing by meaning: "If I wanted to say I want all unemployment claims from all states to route to HR, we could automate that without having to automate each state's unemployment?" Trish Daigler, Life360
- Privacy: "I don't want to do away with the AI, but I am concerned about training external language models with our data." Marland Taylor, Eden Housing

### What we are building, in order

Milestone 0, Run it. The model runs in production on a cohort; no customer sees anything. GTM gets nothing yet, on purpose.

Milestone 1, See it. The mail list gets badges for action needed, returned mail, and a due date shown relative to today: "due in 7 days", "due today", "past due". Customers can filter on action required, document type, sender, and a due-date range. The detail view shows each fact with the sentence from the letter behind it.

Decided: notifications ship in the first milestone.

Milestone 2, Act on it. Detected actions become Tasks the customer can complete or dismiss. Routing rules can match on the facts instead of keywords. The facts reach REST and webhooks, which is NetCredit's ask.

Milestone 3, Make it yours, still marked potential. Customers bring their own document types for filters and routing rules, and rules can take free-text conditions. That is where Turo's garnishment and injury letters land. We already ran Turo's sheet, 46 categories across 8 departments, on 200 letters from other customers: 72 were sorted into a category, none to the wrong department by inspection.

Nothing in Milestone 1 routes mail or automates an action. No sort, no assignment, no snooze.

### When

No milestone has a date, so do not quote one.

It rolls out per organisation behind a flag, then in wider cohorts, then on by default for everyone except the AI opt-outs. Three enterprise customers have already signed up for the pilot.

New scans only; history is not tagged. Scanned mail only, and about 98% of customers keep auto-scan on.

## Track 2: here is how it works under the hood

### The idea

We wrote down a model of mail: what the document is, who it is for, whether the business must act, by when, what happens if not, and who sent it. Those definitions live in a taxonomy we own, not in a prompt, so we can swap models and measure each one against the same target. The model reads, code decides.

One model call per scanned letter, after OCR, about 4 seconds, with the output held to a fixed schema.

Who the letter is to comes first: a cc copy, a creditor notice or the customer's own returned mail creates no obligation. Only what is printed counts: if the letter gives no date, the field stays empty. A wrong date is worse than no date.

### What runs and where

The model is Gemma 4 31B, Google's open model, running on Amazon Bedrock in Stable's own AWS account, the same setup as AI summaries. Bedrock keeps the data in our account and does not train on it. AI opt-outs are contractual: the four organisations that opted out are skipped before any model call.

Claude Opus 5 scored the same within noise at five times the price.

It costs about a tenth of a cent per letter, less than the OCR step before it.

Customers see the supporting sentence from the letter, never the model's reasoning or a confidence number.

### How good it is

On 200 real letters: who the letter is to 98%, document type 92%, action required 91%, sender from the letterhead 93%, consequence 84%, and 33 of 34 printed due dates exact.

### When it is wrong

The customer can see the sentence it relied on and check it against the scan.

## FAQ

Q: Can it tell a marketing flyer from a legal notice?
A: Marketing mail is always marked as needing no action, even when it says "respond by".

Q: Can it flag something as urgent?
A: Not with an "urgent" label. It shows action needed and the due date, and customers can filter to what is due within a window.

Q: Does it pay the bill or file the form for me?
A: No. Nothing in Milestone 1 automates an action.

Q: Does it replace AI summaries?
A: No. Summaries stay on their own pipeline, and the facts sit beside them.

Q: What does it cost the customer, and which plans get it?
A: No answer yet. Check with me first.

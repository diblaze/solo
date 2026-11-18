# Writer patterns

> Derived from blader's `humanizer` v3.1.0 (https://github.com/blader/humanizer),
> Copyright (c) 2025 Siqi Chen, MIT License. See `NOTICE` at the repo root.

The catalog `SKILL.md` points at, strongest first. Each pattern has what to watch for, why it
reads as AI, and a before and after.

## A. Staging instead of stating

These are the strongest and most frequent tells in current model prose. Act on one sighting.

### 1. Not X but Y

**Watch for:** not X but Y; not just, not only, or not merely X, but Y; it's not X, it's Y; the reversed form X rather than Y; the same contrast split across sentences ("This does not mean X. It means Y."); a clipped negative tail ("..., no guessing"). The formula appears in every language; treat the equivalent construction the same way.
**Problem:** The negative half names something no one claimed, so the positive half sounds larger. It adds weight without adding a claim. State the point directly. Keep a contrast only when the negative half corrects a belief the reader actually holds, or when both halves carry information.
**Before:**
> It's not just a CLI, it's a toolkit: config loading, retries and logging come built in. It's not merely a wrapper, it's a statement.
**After:**
> The CLI comes with config loading, retries and logging built in.
**Before (split across sentences):**
> This does not mean every project must use the CLI. It means the CLI is the path the maintainers support.
**After:**
> The maintainers support the CLI. Projects can still call the API directly, without that support.
**Before (clipped tail):**
> The default region comes from the config file, no guessing.
**After:**
> The default region comes from the config file, so you do not have to pass it.

### 2. One-line closers and dramatic fragments

**Watch for:** a one-sentence paragraph that restates the paragraph before it; "That is the real win."; "That distinction matters."; "Read that again."; "Let that sink in."; the same closer after several sections; a sentence after an example, scene, or number that names what it showed ("This shows the importance of...", "The message was clear:"); a row of fragments ("No copy-paste. No waiting."); one word in ALL CAPS or with periods between words (every. single. time.).
**Problem:** The line asks the reader to pause on a claim instead of adding to it. One short sentence can carry emphasis when it carries a new fact. Cut a closer that repeats, including one that explains an example the reader just saw. Keep it when it adds a fact or consequence the example does not show. Merge a row of fragments into a sentence with a specific claim.
**Before:**
> Then version 2 arrived. No more hand-written retry loops. No more failed runs on rate limits. The old way was gone.
**After:**
> With version 2, callers no longer write retry loops or fail on rate limits.
**Before (repeated closer):**
> Caching cuts repeat work.
>
> That is the real win.
>
> Retries hide brief outages.
>
> That is the real win.
**After:**
> Caching cuts repeat work.
>
> Retries hide brief outages.

### 3. Sayings that sound deep

**Watch for:** the real question is, at its core, in reality, what really matters, fundamentally, the deeper issue, the heart of the matter, X is the Y of Z, X becomes a trap, X is not a tool but a mirror, the language of, the currency of, the architecture of
**Problem:** An ordinary point is dressed as a hidden truth or an aphorism, and the dressing adds no detail. Replace the saying with the specific claim.
**Before:**
> The real question is whether users adopt the new API. At its core, what really matters is developer trust.
**After:**
> The question is whether users adopt the new API, which mostly depends on whether developers trust it.
**Before (aphorism):**
> Documentation is the currency of trust. Automation becomes a trap when teams forget the human layer.
**After:**
> Teams trust a service more when its docs are current. Automation can hide steps that people still need to understand.

### 4. Staged run-up before the point

**Watch for:** Let's dive in, let's explore, let's break this down, here's what you need to know, now let's look at, without further ado, heads up, quick note, Honestly?, Look, Here's the thing, The thing is, Let's be honest, Real talk, and casual versions such as "one thing that bit me, so pay attention"
**Problem:** The writer announces the point or stages a moment of candor instead of making the point. Remove the run-up, not just its tone. "Honestly" or "look" inside a casual sentence is ordinary; the tell is the standalone opener before a routine claim.
**Before:**
> Let's dive into how the docs build works. Here's what you need to know: it renders each package's `docs/` folder with MkDocs.
**After:**
> The docs build renders each package's `docs/` folder with MkDocs.
**Before (staged candor):**
> Is it worth migrating? Honestly? It depends on how often you deploy.
**After:**
> Whether migrating is worth it depends on how often you deploy.

### 5. Arguing with no one

**Watch for:** This isn't (mainly) about, I'm not saying, To be clear, Don't get me wrong, This is not to say, Some might say... but, A tempting approach would be, One might be tempted to, An obvious approach would be, You might think... but, It would be easy to just
**Problem:** The text answers an objection or rejects an option that appears nowhere else, usually a leftover from an earlier draft. Remove the defense; if it holds a real claim, state the claim. Keep an objection the text attributes or answers in full, and keep an option a reader would actually weigh. Several unrelated rejections in a row are a stronger sign than one.
**Before:**
> This isn't mainly about prompt length, and I'm not arguing that documentation doesn't matter. You could categorize the problem another way, but the issue is whether the agent can use the instruction when it acts.
**After:**
> The issue is whether the agent can use the instruction when it acts.
**Before (fake alternative):**
> Session tokens are rotated every 24 hours. A tempting approach would be to rotate them by restarting the auth service on a cron job, but that would drop every active session. Rotation happens in place, and clients refresh transparently.
**After:**
> Session tokens are rotated every 24 hours, in place, and clients refresh transparently.

## B. Rhythm by rule

Shapes and punctuation applied everywhere, whether or not the meaning asks for them.

### 6. Forced triads

**Problem:** Ideas arrive in threes to sound complete, whether the meaning has three parts or not. The tell can be one sentence ("speed, autonomy, and confidence"), three parallel examples, or three short facts followed by a lesson. Check that each item adds a distinct idea. Merge examples, develop the strongest one, or vary the structure when they do not. Keep three real items when the meaning needs three.
**Before:**
> The workshop covers the CLI, the config file, and the plugin API. Attendees can expect speed, autonomy, and confidence.
**After:**
> The workshop covers the CLI, the config file, and the plugin API.
**Before (paragraph scale):**
> A pipeline can pass and still ship a bug. A review can approve and still miss a risk. A test can run for years and check nothing. Green checks rarely explain themselves.
**After:**
> A pipeline can pass and still ship a bug. So can a review that approved and missed a risk, or a test that ran for years and checked nothing. Green checks rarely explain themselves.

### 7. Repeated sentence openings

**Problem:** Several sentences in a row start with the same subject because repetition is handled by rule instead of by ear. Merge the sentences, change the subject, or begin with the action. Do not ban the repeated word; a remaining sentence may still start with it. Writers also repeat an opening on purpose for rhythm.
**Before:**
> The script reads the config. The script checks the token. The script opens the PR.
**After:**
> The script reads the config, checks the token, then opens the PR.

### 8. Dashes as the universal connector

**Rule:** The final text never contains em dashes (—) or en dashes (–), whatever the source or a writing sample does. Replace each dash with a period, comma, colon, or parentheses, or rewrite the sentence. This includes spaced dashes and double hyphens (` -- `) used as dashes. Leave dashes and hyphens inside code blocks, inline code, commands, paths, and URLs alone.
**Problem:** A dash lets the writer skip choosing how two clauses relate, so a model reaches for it everywhere.
**Before:**
> The new release — shipped without a migration guide — breaks older plugins. The fix -- long overdue according to users -- lands next sprint.
**After:**
> The new release, shipped without a migration guide, breaks older plugins. The fix, long overdue according to users, lands next sprint.

### 9. Stacked qualifiers

**Watch for:** to be fair, it's also possible, could potentially, might arguably, in some cases it may, this is an inference
**Problem:** Repeated editing adds one qualifier after another until every claim sounds uncertain, usually to repair an earlier overstatement rather than to report real doubt. Keep a qualifier only when the source supports it and the meaning needs it. Keep scope statements, legal and safety notices, and real corrections. Ordinary hedges such as *perhaps* or *tends to* are human habits and not tells. *Weak alone.*
**Before:**
> It could potentially be argued that the cache might have some effect on startup time.
**After:**
> The cache may affect startup time.

### 10. Hyphenated pairs everywhere

**Watch for:** production-ready, well-known, well-documented, long-term, real-time, client-facing after the noun they describe
**Problem:** Compound modifiers keep their hyphen in every position. Keep the hyphen before a noun, as in `a well-documented API`, and drop it after the noun, as in `the API is well documented`. Words the dictionary always spells with a hyphen, such as third-party and cross-functional, keep it everywhere. *Weak alone.*
**Before:**
> The library is production-ready, the API is well-documented, and the plan is long-term.
**After:**
> The library is production ready, the API is well documented, and the plan is long term.

### 11. Passive voice and missing subjects

**Problem:** The text hides who acts or drops the subject. Use active voice when it makes the actor and action clearer. *Weak alone.*
**Before:**
> No configuration file needed. The results are preserved automatically.
**After:**
> You do not need a configuration file. The system preserves the results automatically.

## C. Inflation and borrowed authority

The fact underneath is usually sound. Keep it and remove the dressing.

### 12. Overused AI words

**Watch for:** Actually, additionally, align with, bolstered, crucial, deep dive, delve, enduring, enhance, garner, gate/gated/gating (figurative; keep technical uses), highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract noun), leverage (verb), meticulous/meticulously, pivotal, quietly, robust (figurative; keep technical uses), seamless/seamlessly, showcase, streamline, tapestry (abstract noun), testament, underscore (verb), valuable, vibrant
**Problem:** Models use these words far more often than people do, especially in groups. The watch lists in §13 to §18 hold phrases that are tells because of how they are used; this list holds words that are tells wherever they appear. A formal word outside these lists is not a tell by itself.
**Before:**
> Additionally, a crucial feature of the CLI is its robust integration with the config file. This pivotal capability is a testament to the project's focus on developers, showcasing how commands seamlessly fit into the delivery landscape.
**After:**
> The CLI also reads the config file.

### 13. Inflated significance

**Watch for:** stands as a testament, a pivotal or crucial moment, plays a key role, marking or shaping the, underscores its importance, reflects a broader, enduring or lasting legacy, setting the stage for, evolving landscape, indelible mark; Despite these challenges... continues to thrive, Challenges and Legacy, Future Outlook; the future looks bright, exciting times ahead, a step in the right direction
**Problem:** An ordinary detail is said to mark a change, prove a legacy, or promise a future. The move appears at three scales: a phrase, a stock "challenges and outlook" section, and a send-off paragraph. Keep the fact and drop the significance. End on the last concrete fact; if the source states real plans, use those.
**Before:**
> The ARM build was published in 2026, marking a pivotal moment in the evolution of the project's tooling. It was part of a broader movement to standardize how users install it and enhance developer autonomy.
**After:**
> The ARM build was published in 2026, as part of an effort to standardize how users install the project.
**Before (stock section):**
> Despite its growing adoption, the library faces challenges typical of open-source projects, including stale docs and unclear ownership. Despite these challenges, with its central position and ongoing initiatives, the library continues to thrive as an integral part of the ecosystem.
**After:**
> Many of the library's modules have stale docs or no clear owner.
**Before (send-off):**
> The future looks bright for the project. Exciting times lie ahead as we continue our journey toward excellence.
**After:**
> (Cut the paragraph. End on the last concrete fact.)

### 14. Vague connection or association

**Watch for:** associated with, in association with, connected to, in connection with, linked to, tied to
**Problem:** The text says two things are connected without saying how. "The service is associated with the Payments team" hides whether the team built it, runs it, or only uses it. Name the relationship the source gives. If the source does not say, keep the vague wording rather than inventing a role.
**Before:**
> The service is associated with the Payments team, which built it and is on call for it. The change was rolled out in connection with the certificate rotation.
**After:**
> The Payments team built the service and is on call for it. The change was rolled out as part of the certificate rotation.

### 15. Shallow -ing riders

**Watch for:** highlighting, underscoring, emphasizing, ensuring, reflecting, symbolizing, contributing to, cultivating, fostering, encompassing, showcasing
**Problem:** An -ing phrase is bolted onto a simple fact to make it sound deeper. Keep the fact; keep the rider only when the source supports what it claims.
**Before:**
> The project's default pipeline runs lint, test and build, ensuring code quality, fostering a culture of ownership, and reflecting the team's commitment to engineering excellence.
**After:**
> The project's default pipeline runs lint, test and build.

### 16. Sales language

**Watch for:** rich (figurative), profound, exemplifies, commitment to, nestled, in the heart of, groundbreaking (figurative), renowned, featuring, diverse array, breathtaking, must-have, stunning, game-changer, best-in-class, empower
**Problem:** The text reads like an advertisement, especially for products, libraries, tools, or teams. State what the thing is.
**Before:**
> Nestled in the heart of the repository, the examples folder is a must-have collection featuring a diverse array of groundbreaking scripts that empower every user.
**After:**
> The examples folder holds one script per command.

### 17. Borrowed authority

**Watch for:** experts argue, observers have cited, industry reports, studies show, some critics, several publications; cited, featured, or presented in [a list of venues]; over N stars or followers
**Problem:** A name or an unnamed authority stands in for what was said. Unnamed experts prop up a claim; a list of venues props up a project. When the source text names the real source and what it said, use that. Otherwise cut the unsupported claim or the list. A missing citation alone is not a tell; most writing is unsourced.
**Before (unnamed authority):**
> Experts agree that static typing plays a crucial role in developer productivity. Industry reports show that typed APIs are the future of software delivery.
**After:**
> (Cut both sentences unless the text names the report and what it found.)
**Before (venue list):**
> The library has been presented at the spring meetup, in three newsletters, and on several blogs, and has over 200 stars.
**After:**
> The library was presented at the spring meetup.

### 18. Avoiding is, are, and has

**Watch for:** serves as, stands as, functions as, operates as, marks, represents [a]; boasts, features, offers, maintains [a]; refers to
**Problem:** Simple verbs are replaced with longer phrases. Use *is*, *are*, and *has*.
**Before:**
> The docs site serves as the central hub for guides. It features four tutorials and boasts over 200 API pages.
**After:**
> The docs site is where the guides live. It has four tutorials and over 200 API pages.

## D. Formatting by rule

Templates and visual editors also produce clean formatting. The tell is decoration on every item.

### 19. Bold as decoration

**Problem:** Words are bolded without a reason, and vertical lists give every item a bold label and a colon. Remove the bold. Turn a labeled list into prose when the labels carry no information of their own.
**Before:**
> It combines **GitHub Actions (GHA)**, **MkDocs**, and release tools such as **goreleaser** and **cosign**.
**After:**
> It combines GitHub Actions, MkDocs, and release tools like goreleaser and cosign.
**Before (labeled list):**
> - **User Experience:** The user experience has been significantly improved with a new help layout.
> - **Performance:** Performance has been enhanced through cached config lookups.
> - **Security:** Security has been strengthened with scoped tokens.
**After:**
> The update gives the help output a new layout, caches config lookups, and switches to scoped tokens.

### 20. Decorative headings

**Problem:** Headings capitalize every main word, and headings or list items carry emojis or arrows (→) as decoration. A horizontal rule sits between every section, or the document opens with a top-level heading that repeats its own title. A heading written for effect ("The decision, on one screen") should name what the section holds ("How the six options compare"). Use sentence case, remove the decoration and the rules, and let the title stand once.
**Before:**
> ## Getting Started With The Export CLI
**After:**
> ## Getting started with the export CLI
**Before (emojis):**
> 🚀 **Launch Phase:** Version 2 launches in Q3
> 💡 **Key Insight:** Users prefer fewer flags
**After:**
> Version 2 launches in Q3. Users prefer fewer flags.

### 21. Curly quotation marks

**Problem:** Curly quotes (“...”) appear where the writer or target format uses straight quotes ("..."). Most editors auto-curl, so this is *weak alone*.
**Before:**
> The README says “run the bootstrap script first” but the script is gone.
**After:**
> The README says "run the bootstrap script first" but the script is gone.

## E. Leftovers from the chat and the draft

Remove these outright. Nothing here needs rewriting.

### 22. Chatbot residue

**Watch for:** I hope this helps, Of course!, Certainly!, Great question!, You're absolutely right, Would you like..., Want me to...?, Should I continue?, let me know, here is a...
**Problem:** A chatbot's greeting, praise, offer, or closing remains in text that should stand on its own. It is the most certain tell in this list and the easiest to miss when it wraps real content. Remove the wrapper and keep the content.
**Before:**
> Great question! Here is an overview of how releases work. A release goes from a tag to the package registry through CI. I hope this helps! Let me know if you'd like me to expand on any section.
**After:**
> A release goes from a tag to the package registry through CI.

### 23. Knowledge-limit disclaimers and guesses

**Watch for:** as of [date], up to my last training update, while specific details are limited, based on available information, not publicly available, not widely documented, in the provided or available sources, likely [was created, moved, owned], it is believed that
**Problem:** The text mentions where the model's knowledge ends, or admits it found no source and then fills the gap with a plausible guess. State what the source does not show, or remove the sentence.
**Before (cutoff disclaimer):**
> While specific details about the service's origin are not extensively documented in readily available sources, it appears to have been created sometime in 2024.
**After:**
> The repo does not record when the service was created. (Or cut the sentence.)
**Before (guess):**
> Information about the original owner is not available, suggesting the team was reorganized. They likely moved the service to the new cluster, which shaped the current setup.
**After:**
> The `CODEOWNERS` file names no owner for this service. (Or omit the section.)

### 24. A heading repeated in the first sentence

**Problem:** A heading is followed by a one-line paragraph that restates it before the real content begins. Remove the repeated sentence.
**Before:**
> ## Prerequisites
>
> You need a few things first.
>
> Install Go 1.22 or newer before you run `make build`.
**After:**
> ## Prerequisites
>
> Install Go 1.22 or newer before you run `make build`.

### 25. Writing about the document instead of its subject

**Watch for:** what the text replaced ("was added to replace"); how it was assembled or sourced ("generated from", "compiled from", "anything unconfirmed is flagged rather than guessed"); a legend, layout, or order the reader can already see ("the table below compares", "this section is organized by owner").
**Problem:** The text describes itself instead of its subject. Mention a previous version only in change logs, release notes, migration guides, PR descriptions, and other documents about change. Keep a source credit the reader can follow; cut the account of how you worked. Keep a caveat that changes what the reader should do. State a convention only when the reader cannot infer it, and state it once. A single description of the page is *weak alone*.
**Before:**
> This script was added to replace the previous manual setup, which took 14 steps. Run `./bootstrap.sh` to set up the repo.
**After:**
> Run `./bootstrap.sh` to set up the repo.
**Before (method narration):**
> The table below is drawn from each package's `package.json`; anything we could not confirm is flagged rather than guessed.
**After:**
> Licenses come from each package's `package.json`. A package without one is marked as unconfirmed.

## F. Writing for the wrong reader

A model writes for a reader who shares no context, because that fits the widest range of cases. A reply in a thread has a reader who already knows the background. Act on this pattern when you can see the surrounding conversation, or when the text plainly is a reply. If you cannot tell, ask or leave the text alone.

### 26. Re-explaining what the reader knows

**Watch for:** a short reply that restates the problem, walks through the diagnosis, and lays out the evidence before it reaches the decision; a query, command, or set of numbers included to prove a plan will work; background the other person wrote or already agreed to; the answer itself sitting in the last line.
**Problem:** In a reply the reader already has the context, so rebuilding it adds nothing and buries the point. Each sentence can read fine on its own, so this survives sentence-level cleanup. Lead with the decision and keep only the reasoning that would change whether the reader agrees: usually one fact they lack and any link they need to act. The diagnosis and the proof that a plan will work belong in the ticket or document that follows; a reviewer raising a topic is not a request for the full write-up.
**Before:**
> Yeah, you're right, this works around the issue rather than fixing it. The real fix is in `MergeService`: when we move a child under a new parent, it should update `pipeline_id` along with `parent_id`. We can backfill the bad rows from the audit log with `Change.where(field: "pipeline_id", source: "merge")`. I checked QA: 123 past merges, only 6 rows wrong now, so the cleanup is small.
>
> Since `MergeService` is shared and not specific to this account, I'd rather open a separate ticket than widen this PR. The fallback here is fine to keep until then.
**After:**
> Agreed, this is a workaround. Fixing it properly in `MergeService` would widen this ticket well past its scope: it is shared code, so it means checking the merge flow for every account, plus a backfill for the rows that are already wrong.
>
> I'd rather keep this PR account specific and open a separate ticket for the `MergeService` fix and the backfill.

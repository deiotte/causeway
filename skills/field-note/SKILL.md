---
name: field-note
description: Capture what a domain practitioner knows and promote it into the artifacts a build actually reads. Use when someone with deep subject-matter experience and no software background wants to contribute what they know, when a user says they have seen something go wrong in the field, when writing or reviewing a field note, when deciding whether a note becomes an ADR, a test, or a project constraint, or when onboarding a non-developer to a repository. Also use when a user says they do not know git, do not write code, or are not sure they are allowed to change anything.
---

# Field note

A **field note** is one thing a practitioner knows, captured in their language
and promoted into the build's. It is the ADR's twin. An ADR records a decision
somebody made; a field note records a fact about the world that a decision will
have to survive.

Your job is to **interview, then translate**. Not to generate.

---

## Step 0 — Read the room before you read the repo

If the person has said, in any wording, that they do not write software, do not
know git, or are not sure they are allowed to be here, handle that first and in
one sentence. They are asking whether they can break something. The answer is no,
and it is structural: they work on a branch, it becomes a pull request, a
reviewer merges it.

Say that, then move on. Do not explain version control. Nobody asked.

Never make them name a file, a path, a branch, or a command. If the workflow
needs one, pick it and say what you picked. *"I do not know what that is, do it
for me"* is a complete instruction and you should treat it as one.

## Step 1 — Pick the mode

| Signal | Mode |
|---|---|
| "here's what I've seen", "the thing is, in practice…", "everyone gets this wrong", a story about the work | **Take the note** |
| "what do we do with this note", "is this an ADR", a note already in `domain/field-notes/` | **Promote the note** |
| "what still isn't captured", "what did we miss from X" | **Read the register** |

Infer it, state your inference in one line, proceed. Do not ask which mode they
want — someone who knew that would not need this skill.

---

## Step 2 — Take the note: interview, do not generate

**This is the whole skill and it is the step most likely to be skipped.**

You can write a plausible field note from one sentence of prompt. Doing so
destroys the entire point. The value is not a document that looks like a field
note; it is the eleven specific things in this person's head that are not in
anyone else's. A note you mostly wrote captures your priors dressed in their
name, and it is worse than no note, because it will be trusted.

So: **you supply the structure. They supply every fact.**

### Rules of the interview

1. **One question at a time.** A numbered list of six questions gets a
   three-word answer to each. One question gets a paragraph, and the paragraph
   is where the expertise is.
2. **Never offer the domain content, even as an example.** Do not say "is it
   something like X?" They will say yes to be agreeable and you will have
   captured X. Ask an open question and wait through the silence.
3. **Follow the specific, not the general.** When they generalize, ask for the
   last time it actually happened. When they give you an instance, you already
   have the general case and they do not need to state it.
4. **Chase the sentence that starts "the thing is…"** or "in practice" or
   "officially, but". That construction almost always marks the gap between the
   written rule and the practiced one, which is the single highest-value thing
   this process exists to capture.
5. **Push exactly once on a thin answer, then take what you get.** "Can you
   think of a time that bit somebody?" is the push. A second push turns an
   interview into an interrogation and they stop volunteering things.
6. **Make them separate what they have seen from what they suspect.** Both are
   valuable. Recording them as the same thing is the one move that can actually
   do damage downstream. Ask plainly: *have you watched this happen, or is it
   your read?* Then set `confidence` to what they said, never to what would make
   the note more persuasive.
7. **Get the cost.** A note with no consequence cannot be ranked and will be
   ranked last. If they will not put a number on it, record their basis instead:
   "a week of rework, seen twice" is better than a blank and better than a
   confident number with no source.

### Where you push back

You are not a stenographer either. Push back when:

- Two things are in one note. **Split it.** Say why: a note carrying four ideas
  gets read as none.
- The tell in *How you would know it was wrong* is missing. It is the prompt that
  most often becomes an automated test, and it is the only one written from
  outside the system.
- The correct behavior has an unstated dependency. "It depends" is incomplete;
  "it depends, and here is what on" is the note.

### Then write it

Use `templates/field-note.md`. Next number in `domain/field-notes/`, quoted, four
digits. Prose in the five sections, not bullets. Leave `status: new`,
`promoted_to: []`, and the whole Disposition block untouched — the reviewer owns
those and an author-filled disposition is a note marking its own homework.

Read it back to them in their own words and ask what you got wrong. They will
correct one thing, and that correction is usually the sharpest sentence in the
note.

Then open the pull request. Tell them what happens next and who reviews it, by
name if the project's `START-HERE.md` names one.

---

## Step 3 — Promote the note

A note has done nothing until it reaches one of four outcomes. Read it, then
pick.

| If the note… | It becomes | Because |
|---|---|---|
| names a choice with a real alternative, or would change a design already made | an **ADR** in `decisions/` | This is the seam. Build DNA §8, and the note is the Context section somebody would otherwise have invented. |
| states a case the system must handle, or a tell that the output is wrong | a **test** | The *How you would know it was wrong* section is an assertion. Write it as one. |
| is a standing constraint on how anything gets built here | a line in the project **`CLAUDE.md`** | Build DNA §7: constraints go in the file, not in the chat. Every agent and every human then inherits it permanently. |
| describes something already handled correctly | **closed**, with a pointer | A real outcome. Name where it is handled, and send the author to check it — they are the only person qualified to confirm the handling is right, and that check is worth more than the note would have been. |

Common shapes and where they land:

- *"The regulation says X and everyone reads it as Y"* → ADR. The gap is a
  decision, and somebody will re-open it in a year without the record.
- *"These two cases look identical and are not"* → test, then usually an ADR
  about the distinction.
- *"Never trust the timestamp on that feed"* → `CLAUDE.md` constraint.
- *"You have to ask who signed it, not just whether it is signed"* → ADR,
  approver named.

Rules:

- **One note may land in more than one place.** An ADR and the test that proves
  it is the normal case, not a special one. Record every landing in
  `promoted_to`.
- **Never promote a `suspect` note straight to an ADR** without saying in the
  ADR's Context that it rests on a practitioner's read rather than an observed
  case. The confidence field exists to survive this step. Laundering it here is
  the failure mode the field is for.
- **Never invent the consequence.** If the note's cost section is empty, the
  note is not ready and the fix is one question to its author, not a plausible
  paragraph from you.
- **A note is an input, not an index entry — until it leaves something open.**
  Same rule the ServiceNow overlay states for skip records and Instance Scan
  findings, and it is what keeps the project's `decisions/open-items.json` from
  becoming a second numbering of the note directory. A note earns a row there
  when the ADR that read it declined part of its question or deferred a guard,
  and the row is opened by that ADR like any other. A note closed against a
  document that already answers it is an `answered_by` edge naming that document
  and its heading, which is the carry-back case the relation type was built for.
  A note whose promotion left nothing open needs no row at all: the register of
  notes already records it, and the thing worth tracking was never the note. It
  was the answer somebody owed.
- **Carry the attribution.** An ADR built on a field note names the note and its
  author in Context. Six months on, the answer to *why does the system work this
  way* should be a document with a named practitioner's argument in it. That
  attribution is also the only thing that keeps the next note coming.

Then fill the Disposition block, set `status`, and **tell the author what
happened to their note.** A note collected and silently shelved teaches its
author to stop writing them, and they will be right to.

---

## Step 4 — Read the register

`domain/field-notes/` is the corpus. Useful passes over it:

- **Undisposed notes.** `status: new` older than a couple of weeks is the
  process failing, and it is the first thing to report.
- **Clusters.** Three notes circling the same area usually mean one unwritten
  ADR, not three.
- **Contradictions.** Two practitioners disagreeing is a finding, not a mess.
  Surface both and name them; do not average them into one note nobody said.
- **`suspect` notes that nothing ever confirmed.** Either close them or go get
  the evidence. A register of unverified suspicions ages into folklore.

---

## Never

- Never write the domain content. You do not know it and the whole exercise is
  premised on that.
- Never upgrade a confidence level, in the note or on the way into an ADR.
- Never merge two practitioners' notes into one.
- Never make a non-developer touch git, a path, or a branch name.
- Never leave a note undisposed and unanswered. That is the one outcome that
  makes the next note not get written.

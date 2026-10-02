# Start here

<!--
  SEEDED ONCE by tools/sync.sh, then owned by this project. Edit freely.
  Fill every [BRACKET] before you hand this to anyone. An on-ramp with
  placeholders still in it tells a new person they were not expected.

  Audience: someone with deep expertise in the work this system does, and no
  software background. Keep it under ~150 lines. The moment this file needs a
  table of contents it has stopped being a front door.
-->

**This file is for you if you know the work and do not write software.**

If you write software, you want `CONTRIBUTING.md` instead. That one walks you
through the stack, the commands, and your first pull request. This one will bore
you.

---

## You are not here to write code

Nobody is going to ask you to. There is no course to take first, nothing to
install, and no way for you to break the build. Read the next hundred lines and
you will have everything you need.

What we are short of is not people who can write code. It is people who know
what the code has to get right.

## What we actually need from you

A developer can build almost anything you can describe. What a developer cannot
do is know which of ten reasonable-looking designs quietly fails in the field, in
month three, on the one case nobody wrote down.

You know that. It is the most expensive thing in this building and it currently
lives in your head.

So the deposit we want is not requirements and not a specification. It is closer
to what you would tell a sharp new hire on their second week:

- **What goes wrong.** The failure you have watched happen more than once.
- **What everybody gets wrong the first time.** Including you, once.
- **What the rule actually means** when the written version and the practiced
  version have drifted apart, which they usually have.
- **What would make you distrust the output.** If the system handed you an
  answer, what would tell you it was wrong at a glance?
- **The cases that look alike and are not.** This is usually the valuable one.

If a sentence starts with *"the thing is, in practice…"* — that is the sentence.
Write that one down.

## How to say it: the field note

A **field note** is one thing you know, written the way you would say it out
loud. Not a form to satisfy. There is a template at
`[PATH TO field-note.md]` and it is five prompts long.

Three rules, and they are the whole discipline:

1. **One note, one thing.** Two things you know are two notes. A note carrying
   four ideas gets read as none.
2. **Say what happens when it is wrong.** A note without a consequence cannot be
   prioritized against anything else, so it gets prioritized last.
3. **Guessing is allowed if you label it.** "I am fairly sure" and "I have seen
   this twice" are both useful and they are not the same claim. Say which one
   you are making. Nobody will hold the difference against you. Pretending there
   is no difference is the only thing that causes damage downstream.

You do not have to be right. You have to be legible about how sure you are.

## Two ways to get it in

**The fast way — just talk to Claude.** Go to [claude.ai/code](https://claude.ai/code),
pick this project, and say what you know in plain language. Ask it to take a
field note. It will interview you, push back where your account is thin, write
the note in the right shape and the right place, and open a pull request for
you. A pull request is a proposal, not a change. Nothing lands until a person
you know says yes.

You do not need to learn git. Saying *"I do not know what that is, do it for me"*
is a complete instruction and Claude will take it.

**The slower way — a form in your browser.** Open the Issues tab in GitHub, press
**New issue**, and choose **Field note**. It is the same five prompts as a web
form. Somebody else turns it into a note. Use this when you are on a phone,
between meetings, or would rather not talk to a machine today.

Either is fine. The first one gets you a better note because it argues with you.

## What happens to it

Your note gets read by a person, and then one of four things happens to it.

| Where it goes | What that means |
|---|---|
| An **ADR** in `decisions/` | Your knowledge changed a real design decision. This is the big one. |
| A **test** | Your case is now checked automatically, forever, on every change. |
| A line in **`CLAUDE.md`** | Every developer and every AI agent on this project now inherits your constraint permanently. |
| **Answered and closed** | Already handled. You will be told where, so you can check that the handling is actually right. |

You will be told which. If a note of yours turns into an ADR, your name is in it
as the reason. That is not decoration — six months from now, when somebody asks
why the system works this way, the answer is a document with your argument in it.

A note that gets closed is not a note that was wasted. Confirming that something
is already handled correctly is a real result, and roughly a third of them are.

## What you cannot break

This part is deliberate, so that the honest answer to *"am I allowed to touch
this?"* is always yes.

- **You cannot change anything by yourself.** Everything you do becomes a
  proposal that [NAME / TEAM] reviews. That is enforced by the repository, not
  by good manners.
- **You cannot delete anyone's work.** History is kept. Every version of every
  file is recoverable.
- **You cannot break the build.** The checks run before anything merges, and they
  run whether or not anybody remembers to ask for them.
- **You cannot ask a stupid question in here.** The last person who wrote down
  something "everybody already knows" was wrong about that, which is the entire
  reason this file exists.

The guardrails are structural on purpose. You should not have to read a
governance standard to be trusted with a text box.

## If you get stuck

- **Ask Claude first.** "Explain what this repository is, like I have never seen
  one" is a good opening move and it will answer properly.
- **Then ask [NAME], [CONTACT].** The half-hour you would spend fighting the tool
  is a half-hour not spent on the thing only you can do.

## The five-minute version

1. Think of one thing you know that the system would get wrong without you.
2. Go to [claude.ai/code](https://claude.ai/code) and say it out loud in text.
3. Ask for a field note.
4. Answer its questions. Argue with it where it is wrong.
5. Let it open the pull request.

That is the whole job. Everything above is detail for later.

---

*The causeway had to reach dry land somewhere. This is that end of it.* 🐂

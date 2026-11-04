# Recon register

<!--
  COPY THIS FILE ONCE into your team's private register repository as README.md,
  then own it. Causeway does not sync, pin or check it: the register is not a
  project, and its index is your content. Replace every [BRACKET].
-->

Every Recon this team has run, **go and no-go alike**. A Recon is the record of a
first session with the person who owns a problem: what they told us, what it would
take, and what they decided. The format is `templates/recon.md` in the Causeway
standard, pinned at [CAUSEWAY VERSION].

This is the place to look before anyone walks a route someone already walked.

## The rules

1. **This repository is private, and stays that way.** A Recon describes a real
   office, its systems, its data and its problems. Never put one in a public
   repository, and never in the Causeway repository.
2. **One file per Recon**, named `YYYY-MM-DD-short-name.md`, using the session date.
   A second recon of the same problem is a new version of the same file (see its
   amendment log), not a new file.
3. **No-go records stay.** A no-go is a result. Its one-line reason is what the next
   person starts from. Deleting it is how the same problem gets reconned twice
   from scratch.
4. **A go gets a copy, not a move.** The record is copied into the new project
   repository as `recon.md`, and the project's link goes in the record's header and
   in the index below. The copy here stays as it was at the readout.
5. **Paste it only where it is allowed to go.** Before pasting a Recon into an AI
   chat, check that the tool is authorized for what the record describes. The intake
   page will not offer its AI-review button until you tick that box.

## How to add a Recon, from the GitHub website

1. Open `tools/recon/recon.html` from the Causeway release in any browser and fill
   it in. It works offline and saves as you type, in this browser only.
2. Click **Download .md**.
3. In this repository on GitHub, click **Add file**, then **Upload files**, and drop
   the downloaded file in. Or click **Create new file**, name it, and paste what
   **Copy markdown** gave you.
4. In the same change, add one row to the index below.
5. Click **Commit changes**.

When the problem owner confirms or corrects the record, edit the file on GitHub and
add a line to its amendment log. When the readout happens, fill in the outcome and
update the index row.

## Index

Newest first. One row per Recon, added in the commit that adds the file.

| Session date | Recon | Problem owner | Outcome | Project repository |
|---|---|---|---|---|
| [YYYY-MM-DD] | [link to the file] | [name, office] | [proposed \| go \| go with conditions \| reframe \| no-go] | [link, on a go] |

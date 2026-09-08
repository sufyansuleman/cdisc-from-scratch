# Course Strategy — CDISC with R

**Governs positioning, licensing and tiering.** A separate scaffold spec was planned but never written; the session template in the repository serves that purpose instead.

Decided 31 July 2026. Supersedes any earlier instruction to keep the repository private.

---

## 1. The decision

**Two repositories, as already built. Keep both.**

| Repo | Visibility | Contents |
|---|---|---|
| `cdisc-with-r` | **Public**, CC BY-NC-SA 4.0 + MIT | The book: sessions, worked examples, GLPX-1 data and build scripts, exercises **without** solutions, Zenodo DOI |
| `cdisc-with-r-solutions` | **Private**, paid tier | Solutions, extra exercises, specs, slides, instructor material |

The commercial offering is the objective; the free book is the acquisition channel for it.

### Why two repos is correct here

An earlier draft of this document said "one repo, do not create a second." **That was wrong and is superseded.** The solutions repo already exists and is well architected:

- **Access control is the entire point of a paid tier.** You cannot sell access to a folder inside a public repo — git history exposes everything and there is no per-purchaser entitlement mechanism. A private repo with collaborator invites is a working entitlement system at low volume.
- **The drift objection is already solved.** The solutions README states: *"Everything here is additive to the public course — nothing is duplicated from it, so the two repositories cannot drift."* That is the correct architecture. Solutions also render against the public repo's pinned `renv` library rather than duplicating the environment.
- **Two commercial tiers are already distinguished** — *Paid* (solutions, extra exercises, specs) and *Workshop* (slides, instructor notes). That separation supports selling self-paced access and live delivery at different prices.

### Why the public repo stays public

- **Discovery.** A fully private course has no route to buyers. The author has no training brand yet and would be selling CDISC training, in competition with CDISC's own, to an audience that does not know he exists.
- **Precedent.** `InsuSensCalc` reached 4,500+ CRAN downloads by being free. Adoption produced authority; authority sells training.
- **Academic value.** A Zenodo-archived, citable open educational resource is a CV asset during an active job search. A private repo is not.
- **Protection already exists.** `CC BY-NC-SA 4.0` forbids commercial reuse by anyone else.

### Why public — the reasoning the agent should preserve

- **Discovery.** A private paid course has no route to buyers. The author has no training brand yet and would be selling CDISC training in competition with CDISC's own training, to an audience that does not know he exists. The free book is how that audience arrives.
- **Precedent.** The author's `InsuSensCalc` reached 4,500+ CRAN downloads by being free. Adoption produced authority; authority is what sells training. Same mechanism here.
- **Academic value.** A Zenodo-archived, citable open educational resource is a CV asset and supports an active job search. A private repo is not.
- **Protection already exists.** `CC BY-NC-SA 4.0` forbids commercial reuse by anyone else. The free book cannot be resold against the author.

### ⚠️ Correcting a misconception

Publishing this course does **not** breach CDISC's licence. That licence restricts redistributing **CDISC's own documents** — the SDTMIG PDF, IG tables, specification text. It does not restrict the author writing and publishing his own explanation of how the standards work. Facts, methods and standards logic are not copyrightable; only CDISC's specific expression is.

The repository already implements the compliant pattern (see §4). Do not weaken it, and do not use it as an argument for going private.

---

## 2. Free vs. paid — the boundary

**`cdisc-with-r` (public, free):**

- All conceptual sessions and worked examples
- The GLPX-1 simulated trial: `simulate_trial.R`, `build_sdtm.R`, `build_adam.R`, and the generated datasets
- Exercises **without** worked solutions
- Comprehension checks
- `renv.lock` and the reproducible setup
- Zenodo DOI, minted at first release

**`cdisc-with-r-solutions` (private, paid):**

- Worked solutions — structure: *Approach → Code → Why this way → Variations worth knowing*
- Extra exercises not in the public book
- ADaM, define-XML and TLF-shell specs
- The GLPX-1 defect registry answer key
- Slides and facilitation notes (workshop tier)

**Not in either repo:** live cohort delivery, corporate training, assessment and certification. These are services, not files.

**Rule for the agent:** never place solutions, instructor notes, specs or the defect registry in the public repo. If a session needs a solution written, write it in `cdisc-with-r-solutions` and say so explicitly.

---

## 3. Changes required to existing files

The repo currently describes itself as free but references a "private paid-tier repository" that does not exist. Reconcile as follows.

### `README.md`

- Keep *"A free, self-paced, hands-on course."* This is accurate and is the positioning.
- Keep the *Exercises and solutions* paragraph — the private paid-tier repo it references **does exist**. Reword only to add a purchase/contact route, since a reader currently has no way to act on it.
- **Add** a short *Training and consulting* section: live cohorts, corporate/on-site training, contact route. This is the commercial funnel and the README is the highest-traffic page.
- **Add** a non-affiliation line: *"This course is an independent work. It is not affiliated with, endorsed by, or certified by CDISC."*
- Add the Zenodo DOI badge once minted (the existing TODO).

### `.zenodo.json`

- Keep `"access_right": "open"` and `"license": "cc-by-nc-sa-4.0"`. Both are correct under this strategy.
- Bump `"version"` when the first complete release is cut.

### `_quarto.yml`

- Add a persistent link in the navbar or sidebar footer to the course website / training enquiries.
- Keep GoatCounter — privacy-friendly and GDPR-appropriate.

### Licensing

- No change. `CC BY-NC-SA 4.0` for prose, `MIT` for code, is the correct combination.
- **Add a contributor policy.** The README currently invites PRs. Accepting prose contributions without an agreement means that content is not solely the author's, which blocks commercial licensing later. Restrict PRs to typo, bug and clarity fixes, and state that substantive content contributions are not accepted. Put this in `CONTRIBUTING.md`.

---

## 4. CDISC compliance — preserve exactly as-is

These are already correct. Do not relax them.

- **Never commit CDISC PDFs.** `.gitignore` excludes SDTMIG, ADaMIG, OCCDS IG and SDTM Terminology. They are local reference only.
- **Cite by section, never quote.** Reference "SDTMIG v3.4 §6.2" rather than reproducing text.
- **Never reproduce codelists or specification tables in bulk.** Check controlled terminology programmatically via the `sdtm.terminology` package, as the repo already does.
- **Never imply CDISC endorsement, affiliation or certification.**
- **All data synthetic, always.** GLPX-1 only.
- **Keep the `VERIFY` callout discipline.** Every specific claim is cited before the prose around it is written. It is the single most valuable safeguard in this project — a pharma audience will find any invented specific, and the author's credibility does not survive it.

FDA documents in the repo (Technical Conformance Guide, Electronic Submissions guidance) are US government works and carry no such restriction — but they are gitignored anyway, which is fine.

---

## 5. Naming

Keep **"CDISC with R"** for the free book. It is accurate descriptive use, it is how the audience searches, and nominative use of a standard's name in an educational title is defensible.

Two safeguards:

1. The non-affiliation statement in §3, visible on the README and the book's landing page.
2. For **paid corporate training**, prefer a title that does not lead with the mark — e.g. *Clinical Data Standards with R* — with CDISC named in the description. Trademark exposure rises when money changes hands under the mark.

Worth considering separately: applying to become a **CDISC Authorized Instructor**. That converts the residual risk into a credential.

---

## 6. Work priority

**Authoring is complete as of 2026-09-07.** All 16 sessions and 11 exercises
are written, executed and rendered; 28 pages, zero TODOs. What remains is
release work, not content.

| Order | Task | Note |
|---|---|---|
| 1 | Private-repo cleanup | See §6b. Two competing solution formats, stale directories |
| 1b | Live delivery layer | **Done.** `overview/` in the public repo; `instructor/run-sheets/` and rewritten timings and facilitation notes in the private repo |
| 2 | Solutions for Exercises 9-11 | define-from-specs, adrg, dataset-json. Ex 7 and 8 are written |
| 3 | README / licensing changes from §3 | Small |
| 4 | Cut a release and mint the Zenodo DOI | The book is content-complete, so this is now unblocked |

Two known items deliberately left open in the public repo, both documented
where they occur:

- `sessions/adlb.qmd` reports the week-26 difference as **-1.116**; the exact
  value is -1.116515, which rounds to -1.117. The figure quoted is the
  difference of the two *displayed* means, so it is a presentation choice
  rather than an error, but it is worth a decision.
- The committed `data/define/define.sdtm.xml` carries **13 rule-73 findings**
  (Origin `Derived` with no `MethodOID`). Left in on purpose, reported in the
  ADRG's conformance summary, and closed by Exercise 10 task 1.

### ⚠️ Scope warning — `adrg.qmd` (honoured; kept as the record of why)

The author's expertise is **reproducible R engineering applied to clinical data standards**, not regulatory submission practice. He has not run a submission.

Write this session to teach **what the ADRG is, what it must contain, and how to generate its data-driven components from R**. Do **not** write about agency interaction, submission strategy, review expectations, or "what the FDA will look for."

Where the material would require submission experience the author does not have, use a `VERIFY` callout rather than writing plausible prose. Scoping this honestly in the course description is a credibility signal to an audience of experienced programmers — pretending otherwise is the fastest way to lose them.

---

## 6b. Cleanup in `cdisc-with-r-solutions`

Audited 2026-09-08. Most of this is now done.

1. ~~**Two competing solution formats.**~~ **Done.** The five orphan
   `solution.qmd` stubs (all 19-line TODO templates) were removed. The
   convention is now one `exercise-solution.md` per exercise. The earlier
   note preferred `.qmd`; in practice the `.md` files carry executed
   numbers and marking guidance and never needed to render, so the
   simpler format won.
2. ~~**`solutions/sdtm-events-findings/` is stale.**~~ **Done**, deleted.
3. ~~**`solutions/tlf/solution.qmd` precedes its session.**~~ **Done**,
   the session and Exercise 7 are written and the stub is gone.
4. **Empty placeholders remain:** `extra-exercises/`, `slides/`,
   `specs/adam/`, `specs/define-xml/`, `specs/tlf-shells/` are `.gitkeep`
   only. Nothing can be sold as a "specs" tier until they exist.
5. ~~**`facilitation-notes.md` and `timings.md` are TODO skeletons.**~~
   **Done.** Both rewritten for live delivery, plus 15 per-evening run
   sheets in `instructor/run-sheets/`.
6. ~~**Harden `.gitignore`.**~~ **Done.** PDFs, spreadsheets and `/refs/`
   are now excluded, matching the public repo.

Still outstanding: solutions for Exercises 9, 10 and 11
(`define-from-specs`, `adrg`, `dataset-json`). These block Course B, not
Course A, and are better written after Course A has run.

---

## 7. Do not

- Do not merge the two repositories.
- Do not make `cdisc-with-r` private.
- Do not make `cdisc-with-r-solutions` public.
- Do not duplicate public-repo content into the solutions repo — it must stay **additive**, which is what prevents drift.
- Do not put solutions, specs, instructor notes or the defect registry in the public repo.
- Do not commit CDISC copyrighted documents to **either** repo.
- Do not state CDISC specifics from memory — `VERIFY` instead.
- Do not accept substantive prose contributions via PR.
- Do not describe the course as CDISC-endorsed, certified or affiliated.

---

## 8. Unrelated: `r_for_clinical_data` is not the author's work

`C:\Courses\r_for_clinical_data` is the **R/Medicine 2026 pre-conference workshop** *"R/Medicine 101: Intro to R for Clinical Data"* by **Rich Hanna** and **Ezra Porter** (Children's Hospital of Philadelphia). It has no commits and appears to be a clone of workshop material.

It is licensed **CC BY-SA 4.0**, which permits reuse and adaptation — including commercially — but **requires attribution and requires that derivatives carry the same ShareAlike licence.**

⚠️ **Do not copy material from it into either CDISC repo.** ShareAlike would force the derivative work under CC BY-SA 4.0, which drops the NonCommercial protection on the paid tier and would let anyone resell it. Keep it entirely separate; treat it as reference reading only.

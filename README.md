# CDISC with R

*SDTM, ADaM and TLFs from scratch using a simulated Phase III trial*

A free, self-paced, hands-on course on CDISC clinical data standards in
R. You take raw data from a simulated Phase III trial (codename
**GLPX-001**) and carry it all the way to submission-ready datasets and
outputs: SDTM domains, ADaM datasets, define-XML, tables, listings and
figures, and Dataset-JSON. All data is synthetic. No real patient
information appears anywhere in this repository.

Most CDISC courses hand you a finished SDTM domain and walk you through
its columns. This one hands you the raw export instead: five files, five
different date formats, one subject enrolled twice. You build the domain
yourself, decide what to do about the duplicate, and defend the
decision.

Every claim about a standard is cited to the section of the
Implementation Guide it comes from (`SDTMIG v3.4, §4.4.4`, `ADaMIG v1.3,
§3.3.8`), so you can check it, and so you learn where to look when the
next question arrives.

## Start here

**[Open the online book](https://sufyansuleman.github.io/cdisc-with-r/)**.
That is the main way to use the course. Everything in this repo is the
authoring source behind it.

New here? Go through it in this order:

1. **Setup**: tools, packages, and a reproducible workflow
2. **Part 1, Foundations**: why clinical data standards exist, and the
   GLPX-001 trial you will work with throughout
3. **Part 2, SDTM**: study data tabulation. Concepts, the DM domain,
   events and findings domains, and define-XML
4. **Part 3, ADaM**: analysis datasets. Concepts, ADSL, ADAE and ADLB
5. **Part 4, Outputs and Submission**: TLFs, the ADRG, and Dataset-JSON

## What you actually build

The trial is a simulated Phase III, randomised, double-blind,
placebo-controlled study of a fictional GLP-1 agent in type 2 diabetes:
400 subjects, 12 sites, 8 visits.

Working from its raw export, you build:

| Stage | Datasets | Some of what it covers |
|---|---|---|
| **SDTM** | DM, AE, LB, VS | `USUBJID` construction, the study-day rule (no day 0), controlled terminology, original vs standardised results, reference ranges |
| **ADaM** | ADSL, ADAE, ADLB | population flags, treatment dates, treatment emergence (`TRTEMFL`), occurrence flags, `PARAM`/`AVAL`, and the baseline (`ABLFL`) every change is measured from |
| **Outputs** | TLFs, define-XML, ADRG, Dataset-JSON | what a reviewer actually receives |

The simulator plants a small number of deliberate data defects: a
duplicated lab record, a missing start date, a sex value that disagrees
between two sources. Learning to find and resolve those is most of the
job, so the course resolves them on the page rather than shipping clean
data.

## Status

This book is being written in the open, session by session.

**Complete.** Prose written, every code chunk executed against the
repository's data, every standards claim cited to its Implementation
Guide section:

- Setup
- Part 1: Why Standards, The GLPX-001 Trial
- Part 2: SDTM Concepts, DM, Events (AE), Findings (LB/VS)
- Part 3: ADaM Concepts, ADSL, ADAE, ADLB

**In progress.** Outlined but not yet written: Define-XML, and all of
Part 4 (TLFs, ADRG, Dataset-JSON). Those pages exist in the book's
navigation but are largely empty.

The course targets the standard versions a 2024 study start would be
held to: **SDTMIG v3.4** (with SDTM v2.0), **ADaMIG v1.3** (with ADaM
v2.1), and **OCCDS v1.1** for adverse events.

## Who this is for

- Statistical programmers and biostatisticians moving into clinical
  trial work in the pharmaceutical industry
- R users in clinical research who need to produce or consume
  CDISC-standard datasets
- Anyone preparing data for a regulatory submission who wants to
  understand the pipeline end to end

No prior CDISC knowledge is assumed. The course takes for granted that
you have never opened an Implementation Guide.

## What is in this repo

```
sessions/      the course sessions (authoring source for the book)
exercises/     exercise sets; solutions live in the private repo
R/             simulate_trial.R, build_sdtm.R, build_adam.R, palette.R
data/raw/      the simulated raw export, defects included
data/sdtm/     built SDTM domains, committed and reproducible
data/adam/     built ADaM datasets, committed and reproducible
docs/          the rendered book, served by GitHub Pages
```

The pipeline is deterministic end to end: `simulate_trial.R` is
seeded, and `build_sdtm.R` and `build_adam.R` contain no randomness, so
everything under `data/` regenerates identically from source. The
generated CSVs are committed rather than ignored, so the later sessions
can read finished datasets without rebuilding the chain.

## Working with this repo

Clone, then open `cdisc-with-r.Rproj` in RStudio. That sets the working
directory to the project root, which every code chunk assumes.

Enable the commit hooks (once per clone):

```bash
git config core.hooksPath .githooks
```

This course pins its package versions with **renv**. Reproducibility is
part of the subject matter here, and `renv.lock` is itself a teaching
artifact. To set up:

```r
renv::restore()
```

then render the book with:

```bash
quarto render
```

The `.Rprofile` points Linux machines at Posit Public Package Manager
binaries so `renv::restore()` takes minutes rather than tens of minutes.
macOS and Windows get binaries from the standard repositories, with no
action needed.

The site is rendered locally into `docs/` and committed; GitHub Pages
serves `docs/`. There is no CI (see [notes/CI-NOTES.md](notes/CI-NOTES.md)).

## Exercises and solutions

Exercises are part of this public book. Worked solutions, extra
exercises, specs and instructor material live in the private paid-tier
repository.

## Contributing

This repo is the authoring source for the online book. Spotted a typo,
an unclear explanation, or a standards claim you think is wrong? Issues
and pull requests are welcome. Corrections to citations are especially
welcome.

## Citation

If you use this course in your teaching or research, please cite:

Suleman, S. (2026). *CDISC with R*. https://sufyansuleman.github.io/cdisc-with-r/

## Licence

Prose content: [CC BY-NC-SA 4.0](LICENSE). Code: [MIT](LICENSE-CODE).

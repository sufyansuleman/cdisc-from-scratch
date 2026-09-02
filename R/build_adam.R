# build_adam.R — GLPX-001 SDTM -> ADaM datasets
#
# Reads the finished SDTM in data/sdtm/ and writes analysis datasets to
# data/adam/. This is the ADaM companion to build_sdtm.R: each ADaM
# session (adsl, adae-adlb) explains one dataset, and this script reifies
# exactly those derivations so the TLF sessions — and any learner who
# clones the repo — can read finished, conformant ADaM without rebuilding
# the chain.
#
# DETERMINISTIC. The inputs are the committed data/sdtm/*.csv, themselves
# fixed-seed output of simulate_trial.R + build_sdtm.R; nothing here is
# random. data/adam/*.csv is therefore fully reproducible from
# simulate_trial.R -> build_sdtm.R -> build_adam.R alone. The generated
# CSVs are committed (not gitignored) for that reason.
#
# Derivations follow ADaMIG v1.3 and the decisions recorded in the
# sessions. Datasets grow as their sessions are written:
#   ADSL -> sessions/adsl.qmd
#   ADAE -> sessions/adae.qmd
#   ADLB -> sessions/adlb.qmd

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
})

read_sdtm <- function(name) {
  read_csv(file.path("data", "sdtm", paste0(name, ".csv")),
           show_col_types = FALSE, col_types = cols(.default = col_character()))
}

# ---- ADSL (Subject-Level Analysis Dataset) ---------------------------------
# ADaMIG v1.3 §2.3.1: one record per subject, one ADSL per study.
# See sessions/adsl.qmd for the reasoning behind each derivation.
#
# SCOPE NOTE. Two ADSL variables have no SDTM source in this course,
# because GLPX-001's SDTM stops at DM/AE/LB/VS and never builds DS
# (Disposition), which is where a real trial records randomization and
# end-of-study:
#   RANDDT — taken as TRTSDT. Verified true for all 400 subjects here
#     (the simulator dosed every subject on the randomization date), but
#     that is a property of THIS dataset, not a general rule.
#   EOSSTT/EOSDT — derived from visit attendance in VS as a documented
#     proxy. In a real submission both come from DS.
# Both are flagged as simulation scope limits in the session, not taught
# as standard practice.

build_adsl <- function() {
  dm <- read_sdtm("dm")
  vs <- read_sdtm("vs")

  # End of study, from the last visit the subject actually attended.
  # VISITNUM 8 = WEEK 26 is the last protocol visit; reaching it means
  # the subject completed. (Proxy for DS — see SCOPE NOTE above.)
  eos <- vs |>
    group_by(USUBJID) |>
    summarise(
      last_visitnum = max(as.integer(VISITNUM)),
      EOSDT         = as.Date(max(VSDTC)),
      .groups       = "drop"
    ) |>
    mutate(EOSSTT = if_else(last_visitnum == 8L, "COMPLETED", "DISCONTINUED"))

  dm |>
    left_join(eos, by = "USUBJID") |>
    mutate(
      # -- dates first; later derivations depend on them --
      TRTSDT = as.Date(RFXSTDTC),          # first exposure  (DM.RFXSTDTC)
      TRTEDT = as.Date(RFXENDTC),          # last exposure   (DM.RFXENDTC)
      # Duration in days, inclusive of both endpoints. The ADaMIG defines
      # TRTDURD as "total treatment duration, as measured in days" but
      # does not fix the formula; this convention is the sponsor's and is
      # documented here and in the metadata.
      TRTDURD = as.integer(TRTEDT - TRTSDT) + 1L,
      RANDDT  = TRTSDT,                    # SCOPE NOTE above

      AGE     = as.numeric(AGE),
      # Sponsor-defined age grouping. Not controlled terminology: the cut
      # point is an analysis decision. AGE is null for the four subjects
      # with incomplete birth dates (D1), so AGEGR1 is null for them too —
      # AGEGR1N must be null on exactly the same rows (ADaMIG v1.3 §3.2).
      AGEGR1  = case_when(AGE <  65 ~ "<65",
                          AGE >= 65 ~ ">=65"),
      AGEGR1N = case_when(AGEGR1 == "<65"  ~ 1,
                          AGEGR1 == ">=65" ~ 2),

      TRT01P  = ARM,                       # planned treatment, period 1
      TRT01PN = if_else(ARMCD == "GLPX10", 1, 2),
      TRT01A  = ACTARM,                    # actual treatment, period 1

      # Population flags. Derived from conditions, never hard-coded, and
      # never copied from SDTM (ADaMIG v1.3 §3.5). Subject-level
      # population flags may not be null (ADaMIG v1.3 §3.1.4), so each is
      # an explicit Y/N.
      RANDFL = if_else(!is.na(RANDDT), "Y", "N"),                # randomized
      ITTFL  = if_else(!is.na(RANDDT), "Y", "N"),                # ITT = as randomized
      SAFFL  = if_else(!is.na(TRTSDT), "Y", "N")                 # >= 1 dose
    ) |>
    select(
      STUDYID, USUBJID, SUBJID, SITEID,
      AGE, AGEU, AGEGR1, AGEGR1N, SEX, RACE, ETHNIC, COUNTRY,
      ARM, ARMCD, ACTARM, ACTARMCD, TRT01P, TRT01PN, TRT01A,
      RANDDT, TRTSDT, TRTEDT, TRTDURD,
      RANDFL, ITTFL, SAFFL,
      EOSSTT, EOSDT
    ) |>
    arrange(USUBJID)
}

# ---- ADAE (Adverse Events analysis dataset) --------------------------------
# OCCDS v1.1: one record per adverse event record in SDTM AE, plus the
# subject-level variables merged from ADSL (OCCDS v1.1 §3.2.1).
# See sessions/adae.qmd for the reasoning behind each derivation.
#
# CLASS NOTE. This is Class = OCCURRENCE DATA STRUCTURE, and deliberately
# NOT SubClass ADVERSE EVENT. The SubClass requires every level of the
# MedDRA primary path — SOC, HLGT, HLT, LLT, PT (OCCDS v1.1 §3.2.3) — and
# GLPX-001 has no MedDRA coding at all, because MedDRA is licensed and
# this course does not fabricate coded terms. OCCDS v1.1 §1.1.2 sanctions
# exactly this: data "that could have been coded but was not should use
# this structure". The MedDRA-dependent occurrence flags (AOCCSFL,
# AOCCSIFL, AOCCPFL, AOCCPIFL) are therefore NOT derived here. They are
# not omitted by oversight; they are unbuildable without a dictionary.
#
# TREATMENT WINDOW. TRTEMFL uses ADSL.TRTSDT <= ASTDT <= ADSL.TRTEDT + x
# with x = 0 (OCCDS v1.1 §3.2, Table 3.2.5.3). Real trials commonly set
# x > 0 from the drug's half-life; GLPX-001 is fictional and inventing a
# half-life for it would be inventing a pharmacological fact, so the
# window is exactly first dose to last dose inclusive. Sponsor choice,
# documented here and in the session.

TRTEM_WINDOW_DAYS <- 0L   # the "x" in TRTEDT + x days

build_adae <- function(adsl) {
  ae <- read_sdtm("ae")

  ae |>
    left_join(
      adsl |> select(USUBJID, SUBJID, SITEID, TRT01A, TRTSDT, TRTEDT, SAFFL),
      by = "USUBJID"
    ) |>
    mutate(
      AESEQ = as.integer(AESEQ),

      # Analysis dates from the SDTM ISO 8601 strings. No imputation rule
      # is specified for this study, so a missing AESTDTC yields a missing
      # ASTDT — and ASTDTF stays null, because nothing was imputed
      # (OCCDS v1.1 §3.2, Table 3.2.4.1). Subject 103-199 is that case.
      ASTDT  = as.Date(AESTDTC),
      AENDT  = as.Date(AEENDTC),
      ASTDTF = NA_character_,

      # Study day relative to first dose, no day 0 — the SDTMIG §4.4.4
      # rule, but anchored to ADSL.TRTSDT rather than DM.RFSTDTC
      # (OCCDS v1.1 §3.2, Table 3.2.4.1).
      ASTDY = if_else(ASTDT >= TRTSDT,
                      as.integer(ASTDT - TRTSDT) + 1L,
                      as.integer(ASTDT - TRTSDT)),
      AENDY = if_else(AENDT >= TRTSDT,
                      as.integer(AENDT - TRTSDT) + 1L,
                      as.integer(AENDT - TRTSDT)),

      # Analysis severity. AESEV keeps the SDTM value untouched; the
      # recased analysis version goes in ASEV, which is producer-defined
      # terminology, not CDISC CT (OCCDS v1.1 §3.2, Table 3.2.8.1).
      ASEV  = recode(AESEV, MILD = "Mild", MODERATE = "Moderate",
                     SEVERE = "Severe"),
      ASEVN = case_when(ASEV == "Mild"     ~ 1L,
                        ASEV == "Moderate" ~ 2L,
                        ASEV == "Severe"   ~ 3L),

      # Treatment emergent: a pure timing derivation. No coded term is
      # involved anywhere. Null ASTDT cannot be classified, so TRTEMFL is
      # null there rather than "N" — absence of a date is not evidence
      # that the event was non-emergent.
      TRTEMFL = case_when(
        is.na(ASTDT) ~ NA_character_,
        ASTDT >= TRTSDT & ASTDT <= TRTEDT + TRTEM_WINDOW_DAYS ~ "Y",
        .default = "N"
      )
    ) |>
    arrange(USUBJID, ASTDT, AESEQ) |>
    # Occurrence flags. Both key on timing and severity, never on a coded
    # term, and both flag the FIRST TREATMENT-EMERGENT record only
    # (OCCDS v1.1 §3.2, Table 3.2.6.1).
    group_by(USUBJID) |>
    mutate(
      # A subject with no classifiable event (103-199, whose only AE has
      # no start date) has no first occurrence to flag: every flag below
      # stays null for them rather than defaulting to a row.
      te_      = !is.na(TRTEMFL) & TRTEMFL == "Y",
      maxsev_  = if (any(te_)) max(ASEVN[te_], na.rm = TRUE) else NA_integer_,
      ismax_   = te_ & !is.na(ASEVN) & !is.na(maxsev_) & ASEVN == maxsev_,
      AOCCFL   = if_else(te_ & cumsum(te_) == 1L, "Y", NA_character_),
      AOCCIFL  = if_else(ismax_ & cumsum(ismax_) == 1L, "Y", NA_character_)
    ) |>
    ungroup() |>
    select(-te_, -maxsev_, -ismax_) |>
    select(
      STUDYID, USUBJID, SUBJID, SITEID, AESEQ,
      AETERM, AEDECOD,
      TRT01A, TRTSDT, TRTEDT, SAFFL,
      AESTDTC, AEENDTC, ASTDT, ASTDTF, AENDT, ASTDY, AENDY,
      AESEV, ASEV, ASEVN, AESER, AEOUT,
      TRTEMFL, AOCCFL, AOCCIFL
    )
}

# ---- ADLB (Laboratory analysis dataset, BDS) -------------------------------
# ADaMIG v1.3 §2.3.2: one or more records per subject, per analysis
# parameter, per analysis timepoint. See sessions/adlb.qmd.
#
# BASELINE DEFINITION (sponsor decision, see sessions/adlb.qmd).
# The SAP defines baseline as the last non-missing value ON OR BEFORE the
# first dose of study drug. That is the standard wording, and it matters
# here: GLPX-001's BASELINE visit is scheduled in a window that lands
# AFTER first dose for 958 of 1600 subject-parameter pairs, so flagging
# "the BASELINE visit" would make most baseline values post-dose.
#
# This still disagrees with SDTM's LBLOBXFL, on 342 pairs, and the reason
# is exactly the distinction worth teaching: LBLOBXFL is the last value
# STRICTLY PRIOR TO first exposure (SDTMIG v3.4 §4.5.9), so it excludes a
# pre-dose draw taken on the dosing day itself, which the SAP includes.
# Only ABLFL is used for analysis (ADaMIG v1.3 §3.5).
#
# CHG CONVENTION. The ADaMIG leaves the population of CHG and PCHG at the
# baseline record and before it to producer choice (§3.3.4.1). This study
# sets CHG = PCHG = 0 on the baseline record and leaves both null on any
# record earlier than baseline, where a change from baseline is not
# defined. Sponsor decision, documented here and in the session.
#
# DTYPE is null throughout: every AVAL is an observed lab result and the
# baseline is an observed record, so nothing is imputed or derived
# differently from the other values within its parameter (§3.3.5).

# PARAM must describe AVAL unambiguously and carries its own units
# (ADaMIG v1.3 §3.3.4.1); PARAMCD is <= 8 chars and starts with a letter.
adlb_params <- tibble::tribble(
  ~LBTESTCD, ~PARAMCD,  ~PARAM,                            ~PARAMN,
  "HBA1C",   "HBA1C",   "Hemoglobin A1C (%)",                    1L,
  "GLUC",    "GLUC",    "Glucose (mmol/L)",                      2L,
  "ALT",     "ALT",     "Alanine Aminotransferase (U/L)",        3L,
  "CREAT",   "CREAT",   "Creatinine (umol/L)",                   4L
)

build_adlb <- function(adsl) {
  lb <- read_sdtm("lb")

  lb |>
    inner_join(adlb_params, by = "LBTESTCD") |>
    left_join(
      adsl |> select(USUBJID, SUBJID, SITEID, TRT01P, TRT01A, TRTSDT, SAFFL),
      by = "USUBJID"
    ) |>
    mutate(
      LBSEQ = as.integer(LBSEQ),
      AVAL  = as.numeric(LBSTRESN),

      AVISIT  = VISIT,
      AVISITN = as.integer(VISITNUM),

      ADT = as.Date(LBDTC),
      # No day 0, anchored to ADSL.TRTSDT rather than DM.RFSTDTC
      # (ADaMIG v1.3 §3.3.3: "not necessarily DM.RFSTDTC").
      ADY = if_else(ADT >= TRTSDT,
                    as.integer(ADT - TRTSDT) + 1L,
                    as.integer(ADT - TRTSDT)),

      # Analysis versions of the range variables (§3.3.7). Here they are
      # carried unchanged from SDTM, but they are ADaM's to re-derive.
      ANRLO  = as.numeric(LBSTNRLO),
      ANRHI  = as.numeric(LBSTNRHI),
      ANRIND = LBNRIND,

      TRTP = TRT01P,
      TRTA = TRT01A,

      # Datapoint traceability (§3.3.9). Unlike OCCDS, BDS uses SRCVAR,
      # because there is an AVAL for it to name the source of.
      SRCDOM = "LB",
      SRCVAR = "LBSTRESN",
      SRCSEQ = LBSEQ,

      DTYPE = NA_character_
    ) |>
    arrange(USUBJID, PARAMN, AVISITN) |>
    group_by(USUBJID, PARAMCD) |>
    mutate(
      # Baseline = the LAST record on or before first dose. ADY == 1 is the
      # dosing day itself under the no-day-0 rule, so "on or before" is
      # ADY <= 1. Flag the latest such record for this subject-parameter.
      bl_ady_ = if (any(ADY <= 1L)) max(ADY[ADY <= 1L]) else NA_integer_,
      ABLFL   = if_else(!is.na(bl_ady_) & ADY == bl_ady_, "Y", NA_character_),
      BASE    = AVAL[match("Y", ABLFL)],
      BNRIND  = ANRIND[match("Y", ABLFL)],
      # Records earlier than baseline get no change. See CHG CONVENTION.
      CHG  = if_else(ADY >= bl_ady_, AVAL - BASE, NA_real_),
      PCHG = if_else(ADY >= bl_ady_ & BASE != 0,
                     100 * (AVAL - BASE) / BASE, NA_real_)
    ) |>
    ungroup() |>
    select(-bl_ady_) |>
    group_by(USUBJID) |>
    mutate(ASEQ = row_number()) |>
    ungroup() |>
    select(
      STUDYID, USUBJID, SUBJID, SITEID, ASEQ,
      TRTP, TRTA, SAFFL, TRTSDT,
      PARAM, PARAMCD, PARAMN,
      AVISIT, AVISITN, ADT, ADY,
      AVAL, BASE, CHG, PCHG, DTYPE,
      ABLFL, ANRLO, ANRHI, ANRIND, BNRIND,
      SRCDOM, SRCVAR, SRCSEQ
    )
}

# ---- entry point -----------------------------------------------------------

main <- function(out_dir = file.path("data", "adam")) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  adsl <- build_adsl()
  adae <- build_adae(adsl)
  adlb <- build_adlb(adsl)
  adam <- list(adsl = adsl, adae = adae, adlb = adlb)

  iwalk(adam, \(df, name) {
    write_csv(df, file.path(out_dir, paste0(name, ".csv")), na = "")
    message(sprintf("%s: %d rows x %d cols", name, nrow(df), ncol(df)))
  })

  invisible(adam)
}

if (sys.nframe() == 0L) {
  main()
}

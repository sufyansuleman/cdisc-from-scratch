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
#   ADAE, ADLB -> sessions/adae-adlb.qmd   (added when that session lands)

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

# ---- entry point -----------------------------------------------------------

main <- function(out_dir = file.path("data", "adam")) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  adsl <- build_adsl()
  adam <- list(adsl = adsl)

  iwalk(adam, \(df, name) {
    write_csv(df, file.path(out_dir, paste0(name, ".csv")), na = "")
    message(sprintf("%s: %d rows x %d cols", name, nrow(df), ncol(df)))
  })

  invisible(adam)
}

if (sys.nframe() == 0L) {
  main()
}

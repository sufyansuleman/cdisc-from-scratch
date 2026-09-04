# ---------------------------------------------------------------------------
# author_spec_workbook.R — create data/spec/SDTM_METADATA.xlsx
#
# WHAT THIS STANDS IN FOR
#
# In a real sponsor nobody generates the specification workbook from a script.
# It is authored and maintained by the standards or data-management group, in
# Excel, usually in a validated document system, and it arrives at programming
# as a finished input. It is the source of truth for submission metadata.
#
# This course has no standards group, so this script plays that part: it
# creates the workbook once, reproducibly, so the repository is deterministic
# like every other artifact in it. Having created it, treat the .xlsx as the
# authored document — R/build_define.R reads it and never regenerates it,
# which is the division of labour a real study has.
#
# Run this only to recreate the workbook from scratch. The normal pipeline is
# author (once, here) -> edit in Excel -> R/build_define.R.
#
# Variable labels are NOT invented. They come from two authoritative sources:
#   * the CDISC-published example define.xml in the Define-XML v2.1 package,
#     for the 36 variables it covers;
#   * SDTMIG v3.4 section 5.2 (DM) and 6.3.5.6 (LB) for the remaining 12.
# The Define-XML package is reference material the reader downloads; see
# sessions/define-xml.qmd. Lengths are computed from the actual GLPX-001 data.
# ---------------------------------------------------------------------------

library(tidyverse)
library(openxlsx)
library(xml2)

DEFINE_PKG <- "refs/DefineV2111_0"
stopifnot(dir.exists(DEFINE_PKG))

dm <- read_csv("data/sdtm/dm.csv", show_col_types = FALSE,
               col_types = cols(.default = col_character()))
lb <- read_csv("data/sdtm/lb.csv", show_col_types = FALSE,
               col_types = cols(.default = col_character()))

# --- labels, from the CDISC example define.xml -----------------------------

ex <- read_xml(file.path(DEFINE_PKG,
                         "examples/DefineXML-2-1-SDTM/defineV21-SDTM.xml"))
ex_items <- xml_find_all(ex, "//d1:ItemDef")

cdisc_labels <- tibble(
  VARIABLE = xml_attr(ex_items, "Name"),
  TYPE     = xml_attr(ex_items, "DataType"),
  LABEL    = map_chr(ex_items, ~ xml_text(
    xml_find_first(.x, "d1:Description/d1:TranslatedText")))
) |>
  distinct(VARIABLE, .keep_all = TRUE)

# --- labels the example does not carry, from SDTMIG v3.4 -------------------
# DM: section 5.2 specification table. LB: section 6.3.5.6.

sdtmig_labels <- tribble(
  ~VARIABLE,   ~TYPE,  ~LABEL,
  "RFXSTDTC",  "date", "Date/Time of First Study Treatment",
  "RFXENDTC",  "date", "Date/Time of Last Study Treatment",
  "RFICDTC",   "date", "Date/Time of Informed Consent",
  "RFPENDTC",  "date", "Date/Time of End of Participation",
  "DTHDTC",    "date", "Date/Time of Death",
  "DTHFL",     "text", "Subject Death Flag",
  "ACTARMCD",  "text", "Actual Arm Code",
  "ACTARM",    "text", "Description of Actual Arm",
  "ARMNRS",    "text", "Reason Arm and/or Actual Arm is Null",
  "ACTARMUD",  "text", "Description of Unplanned Actual Arm",
  "LBDRVFL",   "text", "Derived Flag",
  "LBLOBXFL",  "text", "Last Observation Before Exposure Flag"
)

labels <- bind_rows(cdisc_labels, sdtmig_labels) |>
  distinct(VARIABLE, .keep_all = TRUE)

# --- origin, grounded in what R/build_sdtm.R actually does -----------------
#
# Define-XML 2.0 has ONE origin column. The 2.1 Type/Source split taught in
# sessions/define-xml.qmd has nowhere to live here; that is the point of the
# session this workbook feeds. Values below use the 2.0 vocabulary.

origins <- tribble(
  ~VARIABLE,   ~ORIGIN,
  "STUDYID",   "Assigned",   "DOMAIN",    "Assigned",
  "USUBJID",   "Derived",    "SUBJID",    "CRF",
  "RFSTDTC",   "Derived",    "RFENDTC",   "Derived",
  "RFXSTDTC",  "Derived",    "RFXENDTC",  "Derived",
  "RFICDTC",   "CRF",        "RFPENDTC",  "Derived",
  "DTHDTC",    "CRF",        "DTHFL",     "Derived",
  "SITEID",    "Assigned",   "BRTHDTC",   "CRF",
  "AGE",       "Derived",    "AGEU",      "Assigned",
  "SEX",       "CRF",        "RACE",      "CRF",
  "ETHNIC",    "CRF",        "ARMCD",     "Assigned",
  "ARM",       "Assigned",   "ACTARMCD",  "Assigned",
  "ACTARM",    "Assigned",   "ARMNRS",    "Assigned",
  "ACTARMUD",  "Assigned",   "COUNTRY",   "Assigned",
  "LBSEQ",     "Derived",    "LBTESTCD",  "Assigned",
  "LBTEST",    "Assigned",   "LBORRES",   "eDT",
  "LBORRESU",  "eDT",        "LBSTRESC",  "Derived",
  "LBSTRESN",  "Derived",    "LBSTRESU",  "Derived",
  "LBORNRLO",  "eDT",        "LBORNRHI",  "eDT",
  "LBSTNRLO",  "Derived",    "LBSTNRHI",  "Derived",
  "LBNRIND",   "Derived",    "LBDRVFL",   "Derived",
  "LBLOBXFL",  "Derived",    "VISITNUM",  "Assigned",
  "VISIT",     "Assigned",   "LBDTC",     "eDT",
  "LBDY",      "Derived"
)

keys <- tribble(
  ~DOMAIN, ~VARIABLE,  ~KEYSEQUENCE,
  "DM",    "STUDYID",  1,
  "DM",    "USUBJID",  2,
  "LB",    "STUDYID",  1,
  "LB",    "USUBJID",  2,
  "LB",    "LBTESTCD", 3,
  "LB",    "VISITNUM", 4,
  "LB",    "LBSEQ",    5
)

codelist_of <- tribble(
  ~VARIABLE,  ~CODELISTNAME,
  "SEX",      "SEX",
  "RACE",     "RACE",
  "LBNRIND",  "NRIND",
  "LBTESTCD", "LBTESTCD",
  "LBTEST",   "LBTEST",
  "DTHFL",    "NY",
  "LBDRVFL",  "NY",
  "LBLOBXFL", "NY"
)

method_of <- tribble(
  ~VARIABLE,  ~COMPUTATIONMETHODOID,
  "USUBJID",  "MT.USUBJID",
  "AGE",      "MT.AGE",
  "LBDY",     "MT.LBDY",
  "LBNRIND",  "MT.LBNRIND",
  "LBLOBXFL", "MT.LBLOBXFL"
)

# --- assemble VARIABLE_METADATA -------------------------------------------

var_meta_for <- function(data, domain) {
  tibble(VARIABLE = names(data)) |>
    mutate(
      DOMAIN = domain,
      VARNUM = row_number(),
      LENGTH = map_int(VARIABLE, function(v) {
        w <- suppressWarnings(max(nchar(na.omit(data[[v]])), 0L))
        as.integer(max(w, 1L))
      })
    ) |>
    left_join(labels, by = "VARIABLE") |>
    left_join(origins, by = "VARIABLE") |>
    left_join(keys |> filter(DOMAIN == domain) |> select(-DOMAIN),
              by = "VARIABLE") |>
    left_join(codelist_of, by = "VARIABLE") |>
    left_join(method_of, by = "VARIABLE") |>
    mutate(
      MANDATORY         = if_else(!is.na(KEYSEQUENCE), "Yes", "No"),
      SIGNIFICANTDIGITS = NA_character_,
      COMMENTOID        = NA_character_,
      DISPLAYFORMAT     = NA_character_,
      ROLE              = NA_character_,
      SASFIELDNAME      = VARIABLE
    ) |>
    select(DOMAIN, VARNUM, VARIABLE, TYPE, LENGTH, LABEL, KEYSEQUENCE,
           SIGNIFICANTDIGITS, ORIGIN, COMMENTOID, DISPLAYFORMAT,
           COMPUTATIONMETHODOID, CODELISTNAME, MANDATORY, ROLE, SASFIELDNAME)
}

variable_metadata <- bind_rows(var_meta_for(dm, "DM"), var_meta_for(lb, "LB"))

if (any(is.na(variable_metadata$LABEL))) {
  stop("Unlabelled variables, refusing to invent labels: ",
       paste(variable_metadata$VARIABLE[is.na(variable_metadata$LABEL)],
             collapse = ", "))
}

# --- the remaining sheets --------------------------------------------------

define_header <- tibble(
  FILEOID          = "GLPX001.define.sdtm",
  STUDYOID         = "GLPX001",
  STUDYNAME        = "GLPX-001",
  STUDYDESCRIPTION = paste("A simulated Phase III trial of GLPX 10 mg",
                           "in type 2 diabetes"),
  PROTOCOLNAME     = "GLPX-001",
  STANDARD         = "SDTM-IG",
  VERSION          = "3.4",
  SCHEMALOCATION   = NA_character_,
  STYLESHEET       = "define2-0-0.xsl"
)

toc_metadata <- tribble(
  ~OID, ~NAME, ~DATASETORDER, ~REPEATING, ~ISREFERENCEDATA, ~PURPOSE,
  ~LABEL, ~STRUCTURE, ~CLASS, ~ARCHIVELOCATIONID, ~COMMENTOID,
  "DM", "DM", 1, "No",  "No", "Tabulation", "Demographics",
  "Special Purpose - One record per subject", "Special Purpose", "dm", NA,
  "LB", "LB", 2, "Yes", "No", "Tabulation", "Laboratory Test Results",
  "Findings - One record per lab test per time point per subject",
  "Findings", "lb", NA
)

lb_params <- lb |>
  distinct(LBTESTCD, LBTEST, LBORRESU) |>
  filter(!is.na(LBORRESU)) |>
  arrange(LBTESTCD)

valuelevel_metadata <- lb_params |>
  transmute(
    DOMAIN                = "LB",
    VARIABLE              = "LBSTRESN",
    WHERECLAUSEOID        = paste0("WC.LB.", LBTESTCD),
    VALUEVAR              = "LBTESTCD",
    VARNUM                = row_number(),
    VALUENAME             = LBTESTCD,
    TYPE                  = "float",
    LENGTH                = 8L,
    LABEL                 = LBTEST,
    SIGNIFICANTDIGITS     = 2L,
    ORIGIN                = "Derived",
    COMMENTOID            = NA_character_,
    DISPLAYFORMAT         = NA_character_,
    COMPUTATIONMETHODOID  = NA_character_,
    CODELISTNAME          = NA_character_,
    MANDATORY             = "No",
    ROLE                  = NA_character_,
    ROLECODELIST          = NA_character_
  )

where_clauses <- lb_params |>
  transmute(
    WHERECLAUSEOID = paste0("WC.LB.", LBTESTCD),
    SEQ            = 1L,
    SOFTHARD       = "Soft",
    ITEMOID        = "LB.LBTESTCD",
    COMPARATOR     = "EQ",
    VALUES         = LBTESTCD,
    COMMENTOID     = NA_character_
  )

computation_method <- tribble(
  ~COMPUTATIONMETHODOID, ~LABEL, ~TYPE, ~COMPUTATIONMETHOD,
  "MT.USUBJID", "Unique subject identifier", "Computation",
  "Concatenation of STUDYID and SUBJID separated by a hyphen.",
  "MT.AGE", "Age at informed consent", "Computation",
  paste("Whole years between BRTHDTC and RFICDTC. Null where BRTHDTC is a",
        "partial date and age cannot be computed."),
  "MT.LBDY", "Study day of specimen collection", "Computation",
  paste("Days between LBDTC and DM.RFSTDTC. Day 1 is the reference date;",
        "there is no day 0."),
  "MT.LBNRIND", "Reference range indicator", "Computation",
  paste("LOW where LBSTRESN is below LBSTNRLO, HIGH where above LBSTNRHI,",
        "NORMAL otherwise. Null where either limit is missing."),
  "MT.LBLOBXFL", "Last observation before exposure", "Computation",
  paste("Y on the last record with LBDTC strictly prior to DM.RFXSTDTC,",
        "per subject and test. Null otherwise.")
)

ct_codelists <- tribble(
  ~CODELISTCODE, ~CODELISTNAME, ~TYPE,
  "C66731", "SEX",      "text",
  "C74457", "RACE",     "text",
  "C78736", "NRIND",    "text",
  "C66742", "NY",       "text",
  "C65047", "LBTESTCD", "text",
  "C67154", "LBTEST",   "text"
)

codelist_values <- bind_rows(
  tibble(CODELISTNAME = "SEX",   CODEDVALUE = sort(unique(dm$SEX))),
  tibble(CODELISTNAME = "RACE",  CODEDVALUE = sort(unique(dm$RACE))),
  tibble(CODELISTNAME = "NRIND", CODEDVALUE = sort(unique(na.omit(lb$LBNRIND)))),
  tibble(CODELISTNAME = "NY",    CODEDVALUE = "Y"),
  tibble(CODELISTNAME = "LBTESTCD", CODEDVALUE = sort(unique(lb$LBTESTCD))),
  tibble(CODELISTNAME = "LBTEST",   CODEDVALUE = sort(unique(lb$LBTEST)))
)

codelists <- codelist_values |>
  left_join(ct_codelists, by = "CODELISTNAME") |>
  group_by(CODELISTNAME) |>
  mutate(RANK = row_number(), ORDERNUMBER = row_number()) |>
  ungroup() |>
  transmute(
    CODELISTCODE, CODELISTITEMCODE = NA_character_, CODELISTNAME, RANK,
    CODEDVALUE, TRANSLATED = CODEDVALUE, TYPE,
    CODELISTDICTIONARY = NA_character_, CODELISTVERSION = NA_character_,
    ORDERNUMBER, sourcedataset = NA_character_, sourcevariable = NA_character_,
    sourcevalue = NA_character_, sourcetype = NA_character_
  )

comments <- tribble(
  ~COMMENTOID, ~COMMENT,
  "COM.AGE",
  paste("Four subjects have a partial birth date and therefore no AGE.",
        "See the study data reviewer's guide."),
  "COM.LBDRVFL",
  paste("Not populated. No LB record in this study is derived; all results",
        "are reported by the central laboratory.")
)

# A real submission's define.xml links to the annotated CRF and the study data
# reviewer's guide. Neither document is part of this course, so these rows name
# the files a real study would ship without the files themselves existing here.
# The session says so explicitly rather than pretending otherwise.
external_links <- tribble(
  ~LeafID, ~LeafRelPath, ~LeafPageRef, ~LeafPageRefType, ~Title,
  ~SupplementalDoc, ~AnnotatedCRF,
  "blankcrf", "blankcrf.pdf", NA, NA, "Annotated Case Report Form", NA, "Y",
  "sdrg", "sdrg.pdf", NA, NA, "Study Data Reviewer's Guide", "Y", NA
)

# --- write ------------------------------------------------------------------

dir.create("data/spec", showWarnings = FALSE, recursive = TRUE)

sheets <- list(
  DEFINE_HEADER_METADATA = define_header,
  TOC_METADATA           = toc_metadata,
  VARIABLE_METADATA      = variable_metadata,
  VALUELEVEL_METADATA    = valuelevel_metadata,
  COMPUTATION_METHOD     = computation_method,
  CODELISTS              = codelists,
  WHERE_CLAUSES          = where_clauses,
  COMMENTS               = comments,
  EXTERNAL_LINKS         = external_links
)

wb <- createWorkbook()
for (nm in names(sheets)) {
  addWorksheet(wb, nm)
  writeData(wb, nm, sheets[[nm]])
}
saveWorkbook(wb, "data/spec/SDTM_METADATA.xlsx", overwrite = TRUE)

message("Wrote data/spec/SDTM_METADATA.xlsx")
for (nm in names(sheets)) {
  message(sprintf("  %-24s %3d rows", nm, nrow(sheets[[nm]])))
}

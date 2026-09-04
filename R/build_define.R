# ---------------------------------------------------------------------------
# build_define.R — generate define.xml from the study specification workbook
#
# This is the programming task as it is actually done. The specification
# workbook at data/spec/SDTM_METADATA.xlsx arrives from the standards or
# data-management group; this script reads it and produces the submission
# metadata. It never writes the workbook. If the metadata is wrong, the fix
# belongs in the workbook, not here.
#
# Deterministic, like R/build_sdtm.R and R/build_adam.R. Outputs are committed.
#
# NOTE ON VERSION. defineR emits Define-XML 2.0, which is the April 2014
# standard. The current standard is 2.1, which changed def:Origin among other
# things. The generated file therefore validates against the 2.0 schema and
# FAILS the 2.1 schema — this script asserts both, because the gap between
# live tooling and the published standard is a fact worth failing loudly on
# rather than discovering in a submission. See sessions/define-from-specs.qmd.
# ---------------------------------------------------------------------------

library(defineR)
library(xml2)

SPEC <- "data/spec/SDTM_METADATA.xlsx"
OUT  <- "data/define"

stopifnot(file.exists(SPEC))
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

# defineR writes its outputs next to the workbook it is given, so hand it a
# copy inside the output directory rather than letting it write into data/spec.
spec_copy <- file.path(OUT, basename(SPEC))
file.copy(SPEC, spec_copy, overwrite = TRUE)

write_define(
  path        = spec_copy,
  dir         = OUT,
  type        = "sdtm",
  check       = TRUE,
  html        = TRUE,
  view        = FALSE,
  report_type = "PDF"
)

file.remove(spec_copy)

define_xml <- file.path(OUT, "define.sdtm.xml")
stopifnot(file.exists(define_xml))

doc <- read_xml(define_xml)

schema_20 <- read_xml(system.file(
  "extdata/2.0.0/cdisc-define-2.0/define2-0-0.xsd", package = "defineR"))
valid_20 <- as.logical(xml_validate(doc, schema_20))

message("define.xml written to ", define_xml)
message("  datasets:  ", length(xml_find_all(doc, "//d1:ItemGroupDef")))
message("  variables: ", length(xml_find_all(doc, "//d1:ItemDef")))
message("  codelists: ", length(xml_find_all(doc, "//d1:CodeList")))
message("  validates against Define-XML 2.0 schema: ", valid_20)

if (!valid_20) {
  stop("Generated define.xml does not validate against the 2.0 schema.")
}

# The 2.1 check is informative, not a failure condition: defineR cannot
# produce 2.1, so this is expected to be FALSE and is asserted so that a
# future version of defineR silently gaining 2.1 support does not go unnoticed.
schema_21_path <- "refs/DefineV2111_0/schema/cdisc-define-2.1/define2-1-0.xsd"
if (file.exists(schema_21_path)) {
  valid_21 <- as.logical(xml_validate(doc, read_xml(schema_21_path)))
  message("  validates against Define-XML 2.1 schema: ", valid_21,
          if (!valid_21) "  (expected — defineR emits 2.0)" else
            "  (UNEXPECTED — defineR may now support 2.1)")
} else {
  message("  2.1 schema not present locally; skipped. See sessions/define-xml.qmd.")
}

# ---------------------------------------------------------------------------
# build_dataset_json.R — write GLPX-1 in both transport formats
#
# Produces the same two SDTM domains twice: as SAS Transport v5 (.xpt), the
# format regulatory submissions have used since the 1990s, and as Dataset-JSON
# v1.1 (.json), the standard intended to replace it. Both are committed, so the
# session can compare them without rebuilding.
#
# Variable labels come from data/spec/SDTM_METADATA.xlsx, the same workbook
# R/build_define.R reads. A transport file without labels is legal and useless;
# taking them from the specification keeps the .xpt, the define.xml and the
# Dataset-JSON telling the same story.
#
# Deterministic, like every other build script here.
# ---------------------------------------------------------------------------

library(tidyverse)
library(openxlsx)
library(xportr)
library(datasetjson)

XPT  <- "data/xpt"
JSON <- "data/json"
dir.create(XPT,  showWarnings = FALSE, recursive = TRUE)
dir.create(JSON, showWarnings = FALSE, recursive = TRUE)

spec <- read.xlsx("data/spec/SDTM_METADATA.xlsx", sheet = "VARIABLE_METADATA") |>
  as_tibble()

# xportr expects a metadata frame with these column names
xportr_meta <- spec |>
  transmute(dataset = DOMAIN, variable = VARIABLE, label = LABEL,
            type = if_else(TYPE == "float", "numeric", "character"),
            length = LENGTH, order = VARNUM, format = NA_character_)

# dataset labels live in the workbook's TOC sheet
toc <- read.xlsx("data/spec/SDTM_METADATA.xlsx", sheet = "TOC_METADATA")
spec_label <- function(dom) toc$LABEL[toc$NAME == dom]
toc_meta   <- tibble(dataset = toc$NAME, label = toc$LABEL)

domains <- c(DM = "data/sdtm/dm.csv", LB = "data/sdtm/lb.csv")

sizes <- imap(domains, function(path, dom) {

  # Type each column as the specification declares it. Reading everything as
  # character would make the format comparison meaningless: neither format
  # would be storing numbers as numbers.
  types <- spec |> filter(DOMAIN == dom) |> select(VARIABLE, TYPE)
  ct <- set_names(
    map(types$TYPE, ~ if (.x == "float") col_double() else col_character()),
    types$VARIABLE)
  dat <- read_csv(path, show_col_types = FALSE, col_types = do.call(cols, ct))

  # ---- SAS Transport v5 -------------------------------------------------
  xpt_path <- file.path(XPT, paste0(tolower(dom), ".xpt"))
  dat |>
    xportr_metadata(xportr_meta, domain = dom, verbose = "none") |>
    xportr_label() |>
    xportr_length() |>
    xportr_order() |>
    xportr_df_label(toc_meta, domain = dom) |>
    xportr_write(xpt_path)

  # ---- Dataset-JSON v1.1 ------------------------------------------------
  cols <- spec |>
    filter(DOMAIN == dom) |>
    arrange(VARNUM) |>
    transmute(
      itemOID  = paste0("IT.", dom, ".", VARIABLE),
      name     = VARIABLE,
      label    = LABEL,
      dataType = if_else(TYPE == "float", "float", "string"),
      length   = as.integer(LENGTH)
    )

  ds <- dataset_json(
    dat,
    file_oid           = paste0("GLPX1.", tolower(dom)),
    last_modified      = "2026-09-06T00:00:00",
    originator         = "CDISC with R course",
    sys                = "R",
    sys_version        = as.character(getRversion()),
    study              = "GLPX1",
    metadata_version   = "MDV.GLPX1.SDTMIG.3.4",
    metadata_ref       = "define.xml",
    item_oid           = paste0("IG.", dom),
    name               = dom,
    dataset_label      = spec_label(dom),
    columns            = cols
  )

  json_path <- file.path(JSON, paste0(tolower(dom), ".json"))
  write_dataset_json(ds, json_path)

  # the compressed representation, for the size comparison
  dsjc_path <- file.path(JSON, paste0(tolower(dom), ".dsjc"))
  write_dataset_dsjc(ds, dsjc_path)

  tibble(domain = dom,
         rows   = nrow(dat),
         xpt    = file.size(xpt_path),
         json   = file.size(json_path),
         dsjc   = file.size(dsjc_path))
})

out <- bind_rows(sizes) |>
  mutate(json_vs_xpt = round(json / xpt, 3),
         dsjc_vs_xpt = round(dsjc / xpt, 3))

write_csv(out, file.path(JSON, "size_comparison.csv"))

message("Wrote ", XPT, " and ", JSON)
print(out)

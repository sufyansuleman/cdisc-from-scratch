local({
  # A dated P3M snapshot, not "latest", on purpose.
  #
  # renv.lock pins exact package versions. The "latest" P3M repository only
  # serves binaries for whatever CRAN is shipping right now, so as soon as
  # CRAN moves past a pinned version, every student falls back to compiling
  # from source at the same time. A dated snapshot keeps binaries available
  # for these exact versions indefinitely.
  #
  # The same URL is pinned in renv.lock under "Repositories"; renv overrides
  # this option from the lockfile when it activates, so if you change one,
  # change both. If you re-snapshot the lockfile, move the date forward.
  #
  # Linux: renv rewrites this to the matching __linux__/<codename>/ path for
  # the running distribution, so no per-distro handling is needed here.
  snapshot <- "https://packagemanager.posit.co/cran/2026-09-01"

  options(repos = c(P3M = snapshot, CRAN = "https://cloud.r-project.org"))
})

source("renv/activate.R")




# Make Hake Reprex -------------------------------------------------------------
# A script to demonstrate a reproducible workflow


# setup -------------------------------------------------------------------
library(sraplus) # package to fit surplus production model
library(janitor) # clean up names
library(here) # find all the things

results_name <- "v1.0" # specify the name of the saved results

results_path <-
  here("results", results_name) # create path to results

if (!dir.exists(results_path)) {
  # create results directory if it's missing
  dir.create(results_path, recursive = TRUE)
}

hake_shape <- 3 #shape parameter in pella-tomlinson function

# load functions

funs <- list.files(here("functions")) # find all functions

sapply(funs, function(x)
  source(here("functions", x)))

hello_world() # hi.

# load data ---------------------------------------------------------------

hake_data <- read.csv(here("data", "hake.csv")) # load data

head(hake_data)

hake_data <-
  janitor::clean_names(hake_data) # clean up names - leave raw data as is!

head(hake_data)


# fit model ---------------------------------------------------------------

# format data and priors
# see github.com/danovando/sraplus

hake_driors <- sraplus::format_driors(
  taxa = "Merluccius capensis",
  catch = hake_data$catch,
  years = hake_data$year,
  index = hake_data$abundance_index,
  index_years = hake_data$year,
  shape_prior = hake_shape
)

drior_plot <- plot_driors(hake_driors)

# fit surplus production model to hake abundance index
hake_fit <-
  sraplus::fit_sraplus(
    hake_driors,
    engine = "tmb",
    estimate_shape = FALSE,
    estimate_initial_state = FALSE,
  )

fit_plot <- sraplus::plot_sraplus(hake_fit)

pp_plot <- sraplus::plot_prior_posterior(hake_fit, hake_driors)

hake_results <- sraplus::summarize_sralpus(hake_fit)

# save results ------------------------------------------------------------

plots <-
  ls()[grepl("_plot", ls())] # find all things that end in _plot

# just a little trick. Combining file.path with the output of here keeps the formatting consistent

save(file = file.path(results_path, "hake-plots.Rdata"),
     list = plots) # save plots

saveRDS(hake_results, file = file.path(results_path, "hake-results.rds")) # save specific objects


# knit report -------------------------------------------------------------

# specify output formats for reports
output_format = c(
  "bookdown::html_document2",
  "bookdown::pdf_document2",
  "bookdown::word_document2"
)

if (any(grepl("pdf",output_format ))){
  
  if (tinytex::tinytex_root() == ""){
    tinytex::install_tinytex()
  }
  
}

# render reports
rmarkdown::render(
  here::here("documents", "hake-report.Rmd"),
  params = list(results_name = results_name),
  output_format = output_format,
  output_dir = results_path # put the reports in the results directory
)

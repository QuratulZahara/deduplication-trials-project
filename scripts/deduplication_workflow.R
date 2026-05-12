############################################################
# Script name: Multi-Engine Reference Deduplication
# Purpose: Deduplication workflow for trial datasets
#          - Phase 1: Deduplicate within each search engine
#          - Phase 2: Cross-engine deduplication
#          - Output: Final deduplicated dataset (.csv & .ris)
############################################################

# ----------------------------------------------------------
# 1. Setup Environment
# ----------------------------------------------------------

# Clear all existing variables from the R environment
rm(list = ls())

# Load required packages
library(synthesisr)  # for reference import, matching, deduplication
library(dplyr)       # for data manipulation
library(stringr)     # for string operations

# Set working directory
setwd("c:\\Users\\hp\\deduplication-trials-project")

# ----------------------------------------------------------
# 2. Define Trial and Search Engines with File Paths
# ----------------------------------------------------------

# SPECIFY THE TRIAL NAME HERE (for easy modification when processing different trials)
trial_name <- "Sotos-Prieto_2017"

# Define the three search engines and their associated files (organized by trial)
search_engines <- list(
  pubmed = list(
    main = file.path("data/raw", trial_name, "pubmed_main.csv"),
    protocol = file.path("data/raw", trial_name, "pubmed_protocol.csv"),
    name = "PubMed"
  ),
  wos = list(
    main = file.path("data/raw", trial_name, "wos_main.csv"),
    protocol = file.path("data/raw", trial_name, "wos_protocol.csv"),
    name = "Web of Science"
  ),
  openalex = list(
    main = file.path("data/raw", trial_name, "openalex_main.csv"),
    protocol = file.path("data/raw", trial_name, "openalex_protocol.csv"),
    name = "OpenAlex"
  )
)

# ----------------------------------------------------------
# 3. Phase 1: Within-Engine Deduplication
# ----------------------------------------------------------

cat(paste0("=", strrep("=", 60), "\n"))
cat("PHASE 1: WITHIN-ENGINE DEDUPLICATION\n")
cat(paste0("=", strrep("=", 60), "\n\n"))

# Store deduplicated datasets from each search engine
phase1_results <- list()
phase1_stats <- list()  # Track statistics for summary

for (engine in names(search_engines)) {
  cat("\n--- Processing", search_engines[[engine]]$name, "---\n")
  
  # Check for presence of main and protocol datasets
  main_file <- search_engines[[engine]]$main
  protocol_file <- search_engines[[engine]]$protocol
  existing_files <- c()

  if (file.exists(main_file)) {
    existing_files <- c(existing_files, main_file)
  } else {
    cat("Warning: missing", main_file, "\n")
  }
  if (file.exists(protocol_file)) {
    existing_files <- c(existing_files, protocol_file)
  } else {
    cat("Warning: missing", protocol_file, "\n")
  }

  if (length(existing_files) == 0) {
    cat("No files found for", search_engines[[engine]]$name, "; skipping engine.\n")
    next
  }

  # Read available files
  data_list <- lapply(existing_files, function(f) {
    df <- read.csv(f, stringsAsFactors = FALSE)
    df
  })

  # Combine datasets and normalize column names to lowercase
  combined_data <- do.call(rbind, data_list)
  names(combined_data) <- tolower(names(combined_data))
  cat("Combined:", nrow(combined_data), "references\n")
  
  # First deduplication pass: Exact DOI matching
  cat("  → Running exact DOI deduplication...\n")
  deduplicated_doi <- synthesisr::deduplicate(
    combined_data,
    match_by = "doi",
    method = "exact"
  )
  cat("  → After DOI deduplication:", nrow(deduplicated_doi), "references\n")
  
  # Second deduplication pass: String similarity on titles
  cat("  → Running string similarity deduplication on titles...\n")
  duplicates_string <- find_duplicates(
    deduplicated_doi$title,
    method = "string_osa",
    to_lower = TRUE,
    rm_punctuation = TRUE,
    threshold = 5
  )
  
  # Extract unique references
  deduplicated_final <- extract_unique_references(
    deduplicated_doi,
    duplicates_string
  )
  
  # Clean titles by removing curly braces
  deduplicated_final$title <- gsub("[{}]", "", deduplicated_final$title)
  
  cat("  → Final unique references:", nrow(deduplicated_final), "\n")
  
  # Track statistics for summary
  phase1_stats[[engine]] <- list(
    engine_name = search_engines[[engine]]$name,
    input_count = nrow(combined_data),
    after_doi_dedup = nrow(deduplicated_doi),
    after_title_dedup = nrow(deduplicated_final),
    duplicates_removed = nrow(combined_data) - nrow(deduplicated_final)
  )
  
  # Store result
  phase1_results[[engine]] <- deduplicated_final
  
  # Save intermediate result
  output_dir <- file.path("outputs", trial_name)
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  write.csv(
    deduplicated_final,
    file.path(output_dir, paste0("Phase1_", engine, "_deduplicated.csv")),
    row.names = FALSE
  )
  cat("  → Saved to: outputs/", trial_name, "/Phase1_", engine, "_deduplicated.csv\n")
}

cat(paste0("\n", strrep("=", 60), "\n"))
cat("PHASE 1 COMPLETE\n")
cat(paste0(strrep("=", 60), "\n"))

# ----------------------------------------------------------
# 4. Phase 2: Cross-Engine Deduplication
# ----------------------------------------------------------

cat(paste0("\n", strrep("=", 60), "\n"))
cat("PHASE 2: CROSS-ENGINE DEDUPLICATION\n")
cat(paste0("=", strrep("=", 60), "\n\n"))

# Combine all Phase 1 results
cat("Combining Phase 1 results from all search engines...\n")
all_data <- do.call(rbind, phase1_results)
phase2_input <- nrow(all_data)
cat("Combined dataset size:", phase2_input, "references\n\n")

# First deduplication pass: Exact DOI matching
cat("→ Running exact DOI deduplication...\n")
phase2_doi <- synthesisr::deduplicate(
  all_data,
  match_by = "doi",
  method = "exact"
)
phase2_after_doi <- nrow(phase2_doi)
cat("→ After DOI deduplication:", phase2_after_doi, "references\n")

# Second deduplication pass: String similarity on titles
cat("→ Running string similarity deduplication on titles...\n")
duplicates_phase2 <- find_duplicates(
  phase2_doi$title,
  method = "string_osa",
  to_lower = TRUE,
  rm_punctuation = TRUE,
  threshold = 5
)

# Extract unique references
final_deduplicated <- extract_unique_references(
  phase2_doi,
  duplicates_phase2
)

# Clean titles by removing curly braces
final_deduplicated$title <- gsub("[{}]", "", final_deduplicated$title)

phase2_final <- nrow(final_deduplicated)
cat("→ Final unique references:", phase2_final, "\n")

# ----------------------------------------------------------
# 5. Save Final Results
# ----------------------------------------------------------

cat(paste0("\n", strrep("=", 60), "\n"))
cat("SAVING FINAL RESULTS\n")
cat(paste0("=", strrep("=", 60), "\n\n"))

output_dir <- file.path("outputs", trial_name)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Save as CSV
csv_file <- file.path(output_dir, "FINAL_deduplicated_trials.csv")
write.csv(final_deduplicated, csv_file, row.names = FALSE)
cat("✓ CSV file saved:", csv_file, "\n")

# Save as RIS (Rayyan-compatible manual writer)
ris_file <- file.path(output_dir, "FINAL_deduplicated_trials.ris")

write_ris_rayyan <- function(df, filepath) {
  sanitize <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x <- gsub("[\r\n]+", " ", x)
    trimws(x)
  }

  lines <- c()
  for (i in seq_len(nrow(df))) {
    row <- df[i, ]
    lines <- c(lines, "TY  - JOUR")
    au <- sanitize(row$author)
    if (nzchar(au)) {
      au_parts <- unlist(strsplit(au, ";\\s*"))
      au_parts <- trimws(au_parts[au_parts != ""])
      if (length(au_parts) > 0) {
        lines <- c(lines, paste0("AU  - ", au_parts))
      }
    }
    ti <- sanitize(row$title)
    if (nzchar(ti)) lines <- c(lines, paste0("TI  - ", ti))
    jo <- sanitize(row$publication.title)
    if (nzchar(jo)) lines <- c(lines, paste0("JO  - ", jo))
    py <- sanitize(row$publication.year)
    if (nzchar(py)) lines <- c(lines, paste0("PY  - ", py))
    vl <- sanitize(row$volume)
    if (nzchar(vl)) lines <- c(lines, paste0("VL  - ", vl))
    is <- sanitize(row$issue)
    if (nzchar(is)) lines <- c(lines, paste0("IS  - ", is))
    pg <- sanitize(row$pages)
    if (nzchar(pg)) lines <- c(lines, paste0("SP  - ", pg))
    ab <- sanitize(row$abstract.note)
    if (nzchar(ab)) lines <- c(lines, paste0("AB  - ", ab))
    doi <- sanitize(row$doi)
    if (nzchar(doi)) lines <- c(lines, paste0("DO  - ", doi))
    ur <- sanitize(row$url)
    if (nzchar(ur)) lines <- c(lines, paste0("UR  - ", ur))
    lines <- c(lines, "ER  - ", "")
  }
  writeLines(lines, filepath, useBytes=TRUE)
}

write_ris_rayyan(final_deduplicated, ris_file)
cat("✓ RIS file saved:", ris_file, "\n")

# ----------------------------------------------------------
# 6. Generate Summary Report
# ----------------------------------------------------------

summary_file <- file.path(output_dir, "SUMMARY.md")

# Build summary content
summary_content <- c(
  paste0("# Deduplication Summary - ", trial_name),
  "",
  paste0("**Generated:** ", Sys.Date()),
  "**Workflow:** Multi-Engine Trial Reference Deduplication",
  "",
  "---",
  "",
  "## Phase 1: Within-Engine Deduplication",
  "",
  "| Search Engine | Input Refs | After DOI | After Title | Duplicates Removed |",
  "|---|---|---|---|---|"
)

# Add Phase 1 stats
for (engine in names(phase1_stats)) {
  stat <- phase1_stats[[engine]]
  line <- paste0("| ", stat$engine_name, " | ", stat$input_count, " | ", 
                 stat$after_doi_dedup, " | ", stat$after_title_dedup, " | ", 
                 stat$duplicates_removed, " |")
  summary_content <- c(summary_content, line)
}

# Calculate Phase 1 totals
phase1_input_total <- sum(sapply(phase1_stats, function(x) x$input_count))
phase1_after_doi_total <- sum(sapply(phase1_stats, function(x) x$after_doi_dedup))
phase1_after_title_total <- sum(sapply(phase1_stats, function(x) x$after_title_dedup))
phase1_dup_total <- sum(sapply(phase1_stats, function(x) x$duplicates_removed))

summary_content <- c(
  summary_content,
  paste0("| **TOTAL (Phase 1)** | **", phase1_input_total, "** | **", 
         phase1_after_doi_total, "** | **", phase1_after_title_total, "** | **", 
         phase1_dup_total, "** |"),
  "",
  "---",
  "",
  "## Phase 2: Cross-Engine Deduplication",
  "",
  "| Stage | References |",
  "|---|---|",
  paste0("| Combined Phase 1 Results | ", phase2_input, " |"),
  paste0("| After DOI Deduplication | ", phase2_after_doi, " |"),
  paste0("| After Title Deduplication (FINAL) | ", phase2_final, " |"),
  paste0("| **Duplicates Removed** | **", (phase2_input - phase2_final), "** |"),
  "",
  "---",
  "",
  "## Overall Summary",
  "",
  paste0("- **Initial Combined References:** ", phase1_input_total),
  paste0("- **Final Unique References:** ", phase2_final),
  paste0("- **Total Duplicates Identified:** ", (phase1_input_total - phase2_final)),
  paste0("- **Deduplication Efficiency:** ", 
         round(100 * (phase1_input_total - phase2_final) / phase1_input_total, 1), "%"),
  "",
  "---",
  "",
  "## Output Files",
  "",
  "- `FINAL_deduplicated_trials.csv` - All ", phase2_final, " unique references",
  "- `FINAL_deduplicated_trials.ris` - RIS format (Rayyan-compatible)",
  "- `Phase1_*.csv` - Intermediate Phase 1 results per engine"
)

# Write summary file
writeLines(summary_content, summary_file)
cat("✓ Summary report saved:", summary_file, "\n")

cat(paste0("\n", strrep("=", 60), "\n"))
cat("DEDUPLICATION WORKFLOW COMPLETE!\n")
cat("Final dataset: ", phase2_final, " unique references\n")
cat(paste0("=", strrep("=", 60), "\n"))

# ----------------------------------------------------------
# END OF SCRIPT
# ----------------------------------------------------------

# Multi-Engine Trial Reference Deduplication Project

## Project Overview
This project implements a two-phase deduplication workflow for trial datasets from multiple search engines (PubMed, Web of Science, OpenAlex).

**Workflow:**
1. **Phase 1**: Deduplicate Main + Protocol datasets WITHIN each search engine (3 separate deduplication runs)
2. **Phase 2**: Deduplicate the 3 Phase 1 results together to get final unique dataset
3. **Output**: Final deduplicated dataset in both `.csv` and `.ris` formats

---

## File Structure

```
deduplication-trials-project/
├── data/
│   └── raw/                              ← PUT YOUR INPUT FILES HERE
│       ├── pubmed_main.csv
│       ├── pubmed_protocol.csv
│       ├── wos_main.csv
│       ├── wos_protocol.csv
│       ├── openalex_main.csv
│       └── openalex_protocol.csv
├── outputs/                              ← OUTPUT FILES WILL BE HERE
│   ├── Phase1_pubmed_deduplicated.csv
│   ├── Phase1_wos_deduplicated.csv
│   ├── Phase1_openalex_deduplicated.csv
│   ├── FINAL_deduplicated_trials.csv     ← FINAL OUTPUT (CSV)
│   └── FINAL_deduplicated_trials.ris     ← FINAL OUTPUT (RIS)
├── scripts/
│   └── deduplication_workflow.R          ← Main R script
└── README.md
```

---

## Input File Requirements

### File Format
All input files must be in **CSV format** (.csv)

### Column Requirements
Each CSV file should contain the following columns (minimum required):
- `title` - Title of the reference (REQUIRED)
- `doi` - Digital Object Identifier (recommended)
- `author` - Author names
- `year` - Publication year
- `journal` - Journal name
- Other relevant bibliographic fields

### Required Filenames
Place exactly **6 CSV files** in `data/raw/` with these exact names:
1. **pubmed_main.csv** - Main trials from PubMed
2. **pubmed_protocol.csv** - Protocols from PubMed
3. **wos_main.csv** - Main trials from Web of Science
4. **wos_protocol.csv** - Protocols from Web of Science
5. **openalex_main.csv** - Main trials from OpenAlex
6. **openalex_protocol.csv** - Protocols from OpenAlex

---

## Running the Script

### Prerequisites
- R installed with `synthesisr` package
- Required packages: `synthesisr`, `dplyr`, `stringr`

### Installation of Required Packages (if not installed)
```r
install.packages("synthesisr")
install.packages("dplyr")
install.packages("stringr")
```

### Execution
1. Open the script in RStudio:
   ```
   scripts/deduplication_workflow.R
   ```
2. Click **"Run"** or press `Ctrl+Shift+Enter`

---

## Deduplication Process Details

### Phase 1: Within-Engine Deduplication (Per Search Engine)
- **Step 1**: Load Main and Protocol datasets
- **Step 2**: Combine both datasets
- **Step 3**: Exact DOI matching deduplication
- **Step 4**: String similarity matching (titles) with threshold = 5
- **Step 5**: Extract unique references
- **Step 6**: Save intermediate result

### Phase 2: Cross-Engine Deduplication
- **Step 1**: Load all 3 Phase 1 results
- **Step 2**: Combine all datasets
- **Step 3**: Exact DOI matching deduplication
- **Step 4**: String similarity matching (titles)
- **Step 5**: Extract unique references
- **Step 6**: Save final results (CSV & RIS)

### Deduplication Methods Used
1. **Exact DOI Matching**: Perfect matches on DOI field
2. **String Similarity (OSA)**: Optimal String Alignment distance
   - Ignores capitalization (`to_lower = TRUE`)
   - Ignores punctuation (`rm_punctuation = TRUE`)
   - Threshold = 5 (max allowable distance for match)

---

## Output Files

### Phase 1 Intermediate Files
- `outputs/Phase1_pubmed_deduplicated.csv`
- `outputs/Phase1_wos_deduplicated.csv`
- `outputs/Phase1_openalex_deduplicated.csv`

### Final Output Files
- **`FINAL_deduplicated_trials.csv`** - Final dataset in CSV format
- **`FINAL_deduplicated_trials.ris`** - Final dataset in RIS format (compatible with Rayyan, Zotero, etc.)

---

## Manual Review (Optional)

If you want to manually review potential duplicates during the deduplication process, you can modify the script to use the `review_duplicates()` function or `override_duplicates()` function for false positives.

Example:
```r
# Create a data frame grouping potential duplicates
manual_checks <- review_duplicates(deduplicated_doi$title, duplicates_string)

# View with truncated titles
manual_checks %>%
  mutate(title = str_trunc(title, 125)) %>%
  print()
```

---

## Next Steps

1. **Place your 6 CSV files** in `data/raw/` folder with the exact filenames listed above
2. **Run the R script** from `scripts/deduplication_workflow.R`
3. **Check the outputs** in the `outputs/` folder
4. **Import the final .ris file** into Rayyan (https://new.rayyan.ai/) if needed

---

## Troubleshooting

### "File not found" error
- Verify all 6 CSV files are in `data/raw/` with exact names
- Check file paths use forward slashes or escaped backslashes

### Missing columns error
- Ensure your CSV files contain at least `title` column
- Check for proper CSV formatting

### Package not found error
- Install missing packages: `install.packages("package_name")`

---

## Questions or Modifications?
If you need to adjust deduplication parameters (e.g., string similarity threshold), edit the script values:
- `threshold = 5` (string similarity; lower = stricter)
- `match_by = "doi"` (change matching field)
- `method = "string_osa"` (different string distance algorithms available)


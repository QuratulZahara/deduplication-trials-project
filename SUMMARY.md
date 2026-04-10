# Deduplication Workflow - Execution Summary

**Date Executed:** March 24, 2026  
**Script:** `scripts/deduplication_workflow.R`  
**Trial Name:** Davis_2017

---

## Project Overview

This workflow performs multi-stage deduplication of trial references from three search engines:
- **PubMed**
- **Web of Science (WOS)**
- **OpenAlex**

The process includes both within-engine and cross-engine deduplication to produce a final clean dataset of unique references.

---

## Input Data

### Raw Datasets (Davis_2017 - by search engine)

| Search Engine | Main References | Protocol References | Combined |
|---|---|---|---|
| PubMed | 53 | 23 | **76** |
| Web of Science | 86 | 39 | **125** |
| OpenAlex | 102 | 53 | **155** |
| **TOTAL** | **241** | **115** | **356** |

*Note: Each search engine had two data sources - a main dataset and a protocol dataset that were combined before deduplication.*

---

## Phase 1: Within-Engine Deduplication

Each search engine's combined dataset underwent two-stage deduplication:

1. **Exact DOI Matching** - Removed exact duplicates based on DOI
2. **String Similarity Matching** - Identified near-duplicates in titles using string similarity (threshold: 5)

### Phase 1 Results

| Search Engine | Input | After DOI Dedup | After String Similarity | Duplicates Removed |
|---|---|---|---|---|
| PubMed | 76 | 72 | 72 | 4 |
| Web of Science | 125 | 120 | 119 | 6 |
| OpenAlex | 155 | 148 | 146 | 9 |
| **TOTAL** | **356** | **340** | **337** | **19** |

**Phase 1 Output Files:**
- `outputs/Phase1_pubmed_deduplicated.csv` (72 references)
- `outputs/Phase1_wos_deduplicated.csv` (119 references)
- `outputs/Phase1_openalex_deduplicated.csv` (146 references)

---

## Phase 2: Cross-Engine Deduplication

All Phase 1 results were combined and deduplicated again to remove duplicates that appeared across different search engines.

### Phase 2 Process

1. **Combined Input:** 337 references from all three search engines
2. **Exact DOI Matching:** Identified 167 duplicates (170 unique DOI values remained)
3. **String Similarity Matching:** Identified 18 additional near-duplicates using title similarity
4. **Final Output:** 152 unique references

### Cross-Engine Deduplication Summary

| Stage | References |
|---|---|
| Combined Phase 1 Results | 337 |
| After DOI Deduplication | 170 |
| After String Similarity | **152** |
| **Total Duplicates Removed** | **185** |

---

## Final Output Files

All output files are located in the `outputs/Davis_2017/` directory:

### Primary Deliverables

1. **`outputs/Davis_2017/FINAL_deduplicated_trials.csv`** (375 KB)
   - Tab: Main deduplicated dataset
   - Format: CSV with all bibliographic metadata
   - Records: 152 unique references
   - Columns: Key, Item Type, Publication Year, Author, Title, DOI, Journal, Abstract, and 80+ additional fields

2. **`outputs/Davis_2017/FINAL_deduplicated_trials.ris`** (1.5 KB)
   - Tab: RIS format export
   - Format: RIS (Reference Information System)
   - Records: 152 unique references
   - Use: Compatible with Zotero, Mendeley, EndNote, and other reference managers

### Intermediate Outputs (Phase 1)

- `outputs/Davis_2017/Phase1_pubmed_deduplicated.csv` (197 KB) - 72 PubMed references
- `outputs/Davis_2017/Phase1_wos_deduplicated.csv` (280 KB) - 119 WOS references
- `outputs/Davis_2017/Phase1_openalex_deduplicated.csv` (258 KB) - 146 OpenAlex references

---

## Deduplication Methodology

### Deduplication Strategy

The workflow uses a **two-pass deduplication strategy** to ensure comprehensive duplicate detection:

1. **Pass 1 - Exact Matching (DOI)**
   - Matches records with identical DOI values
   - Highly accurate but requires DOI presence
   - Removes clear duplicates across sources

2. **Pass 2 - String Similarity (Title)**
   - Uses Optimal String Alignment (OSA) distance metric
   - Matches titles with similarity threshold of 5
   - Preprocesses titles: lowercase conversion, punctuation removal
   - Catches near-duplicates that exact matching misses (e.g., minor spelling variations, formatting differences)

### Data Cleaning

- Removed curly braces from titles (Zotero artifact cleaning)
- Preserved all original metadata fields
- Maintained referential integrity across combined datasets

---

## Key Findings

- **Total References Processed:** 356
- **Total Duplicates Identified:** 204 (57.3% duplication rate)
  - Within-engine duplicates: 19
  - Cross-engine duplicates: 185
- **Final Unique References:** 152
- **Deduplication Efficiency:** 42.7% reduction from raw data

### Deduplication Breakdown

| Category | Count | Percentage |
|---|---|---|
| Within-Engine Duplicates | 19 | 9.3% |
| Cross-Engine Duplicates | 185 | 90.7% |
| **Total Duplicates** | **204** | **100%** |

The high rate of cross-engine duplicates (90.7%) indicates significant overlap in trial references retrieved from different search engines, which validates the need for comprehensive cross-engine deduplication.

---

## File Specifications

### CSV Format
- **Encoding:** UTF-8
- **Delimiter:** Comma (,)
- **Row Headers:** Yes
- **Row 1:** Column names
- **Rows 2-153:** Reference records

### RIS Format
- **Standard:** RIS (Reference Information System)
- **Encoding:** UTF-8
- **Compatible Software:** Zotero, Mendeley, EndNote, BiblioScape, etc.
- **Fields:** Standard RIS tags (TI, AU, PY, DO, JO, AB, etc.)

---

## Next Steps

1. **Import RIS file** into your preferred reference management software
2. **Review final CSV** for integration into your analysis database
3. **Screen references** for inclusion/exclusion based on your study criteria
4. **Proceed with full-text review** and data extraction

---

## Project Structure & Adding New Trials

The project is now organized to support multiple trials. Each trial has its own directory and generates its own output files.

### Data Organization

```
data/
  raw/
    Davis_2017/                    # Current trial directory
      pubmed_main.csv
      pubmed_protocol.csv
      wos_main.csv
      wos_protocol.csv
      openalex_main.csv
      openalex_protocol.csv
    [NextTrial]/                   # Future trial goes here
      pubmed_main.csv
      pubmed_protocol.csv
      ... (same file structure)
```

### Output Organization

```
outputs/
  Davis_2017/                      # Davis_2017 outputs
    Phase1_pubmed_deduplicated.csv
    Phase1_wos_deduplicated.csv
    Phase1_openalex_deduplicated.csv
    FINAL_deduplicated_trials.csv
    FINAL_deduplicated_trials.ris
  [NextTrial]/                     # Future trial outputs
    Phase1_*.csv
    FINAL_deduplicated_trials.csv
    FINAL_deduplicated_trials.ris
```

### How to Add a New Trial

1. **Create a new trial directory** under `data/raw/`:
   ```
   data/raw/[NewTrialName]/
   ```

2. **Copy the six CSV files** into the new trial directory:
   - `pubmed_main.csv`
   - `pubmed_protocol.csv`
   - `wos_main.csv`
   - `wos_protocol.csv`
   - `openalex_main.csv`
   - `openalex_protocol.csv`

3. **Update the trial name** in the script:
   - Open `scripts/deduplication_workflow.R`
   - Find line 30: `trial_name <- "Davis_2017"`
   - Change to: `trial_name <- "[NewTrialName]"`

4. **Run the script**:
   ```powershell
   cd c:\Users\hp\deduplication-trials-project
   & "C:\Program Files\R\R-4.5.1\bin\Rscript.exe" scripts/deduplication_workflow.R
   ```

5. **Results will be automatically organized** in `outputs/[NewTrialName]/`

---

## Previous Steps

- **R Version:** 4.5.1
- **Key Packages:** synthesisr, dplyr, stringr
- **Execution Time:** < 1 minute
- **Status:** ✓ Completed Successfully
- **Warnings:** None (only package version notes)

---

## Notes and Recommendations

- The deduplication is comprehensive but not 100% perfect; manual review of borderline cases may be beneficial
- Title-based string similarity has a threshold of 5 edits; this may miss highly divergent titles for the same work
- DOI-based matching is highly reliable where DOIs are available
- Consider the context of your systematic review protocol when validating the final dataset


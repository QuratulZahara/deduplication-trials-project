# Deduplication Workflow - Execution Log

**Project Start Date:** March 24, 2026  
**Last Updated:** April 1, 2026

---

## 📋 Project Overview

This project implements a **two-phase multi-engine trial reference deduplication workflow** that processes search results from three bibliographic databases:
- **PubMed**
- **Web of Science (WOS)**
- **OpenAlex**

Each trial can have incomplete data (missing files from any engine), and the workflow adapts automatically.

---

## 🏃 Trials Executed

### Trial 1: Davis_2017
**Date:** March 24-25, 2026  
**Status:** ✅ Complete

#### Input Data
| Engine | Main Refs | Protocol Refs | Combined | Status |
|--------|-----------|---------------|----------|--------|
| PubMed | 53 | 23 | 76 | ✅ |
| WOS | 86 | 39 | 125 | ✅ |
| OpenAlex | 102 | 53 | 155 | ✅ |
| **TOTAL** | **241** | **115** | **356** | **All present** |

#### Deduplication Results
| Phase | Input Refs | After DOI | After Title | Duplicates |
|-------|-----------|-----------|-------------|-----------|
| Phase 1 (all 3 engines) | 356 | 340 | 337 | 19 |
| Phase 2 (cross-engine) | 337 | 170 | **152** | 185 |
| **Overall** | **356** | — | **152 unique** | **204 (57.3%)** |

#### Output Files
- `outputs/Davis_2017/FINAL_deduplicated_trials.csv` (376 KB)
- `outputs/Davis_2017/FINAL_deduplicated_trials.ris` (1.5 KB)
- `outputs/Davis_2017/Phase1_pubmed_deduplicated.csv` (197 KB)
- `outputs/Davis_2017/Phase1_wos_deduplicated.csv` (280 KB)
- `outputs/Davis_2017/Phase1_openalex_deduplicated.csv` (258 KB)

#### Key Event
- Initial RIS export was broken (only `ER` tags, no content tags).
- **Root cause:** Column names were uppercase (`Title`, `DOI`) but synthesisr requires lowercase mapping.
- **Fix:** Normalized column names to lowercase post-CSV-load; also implemented custom Rayyan-compatible RIS writer with explicit `TY`, `AU`, `TI`, `DO`, `ER` tags.
- Rayyan upload: ✅ Successful after RIS format fix.

---

### Trial 2: Delgado-Lista_2016
**Date:** April 1, 2026  
**Status:** ✅ Complete

#### Input Data
| Engine | Main Refs | Protocol Refs | Combined | Status |
|--------|-----------|---------------|----------|--------|
| PubMed | Multiple | Multiple | 292 | ✅ |
| WOS | **MISSING** | 146 | 146 | ⚠️ Missing main |
| OpenAlex | Multiple | Multiple | 602 | ✅ |
| **TOTAL** | **N/A** | **N/A** | **1,040** | **Partial: 2/3 complete** |

#### Deduplication Results
| Phase | Input Refs | After DOI | After Title | Duplicates |
|-------|-----------|-----------|-------------|-----------|
| Phase 1 (all available) | 1,040 | 1,007 | 996 | 44 |
| Phase 2 (cross-engine) | 996 | 612 | **582** | 414 |
| **Overall** | **1,040** | — | **582 unique** | **458 (44.0%)** |

#### Output Files
- `outputs/Delgado-Lista_2016/FINAL_deduplicated_trials.csv` (1.1 MB)
- `outputs/Delgado-Lista_2016/FINAL_deduplicated_trials.ris` (3.8 KB)
- `outputs/Delgado-Lista_2016/Phase1_pubmed_deduplicated.csv` (568 KB)
- `outputs/Delgado-Lista_2016/Phase1_wos_deduplicated.csv` (356 KB)
- `outputs/Delgado-Lista_2016/Phase1_openalex_deduplicated.csv` (1.4 MB)

#### Key Feature
- **Missing file handling:** `wos_main.csv` does not exist; script detected, logged warning, and proceeded with `wos_protocol.csv` only.
- **Phase 1 output:** Generated `Phase1_wos_deduplicated.csv` from protocol-only data.
- **Phase 2:** Combined all three Phase 1 outputs (including partial WOS) for cross-engine dedup.
- **Result:** Workflow completed without errors; no hardcoded file dependency.

---

## 🔧 Workflow Evolution & Fixes

### Fix 1: Column Name Normalization (March 25, 2026)
**Issue:** CSV files had uppercase column names (`Title`, `DOI`, `Author`, etc.), but synthesisr functions expect lowercase.  
**Symptom:** RIS export produced only `ER` tags with no content.  
**Solution:** Added `names(combined_data) <- tolower(names(combined_data))` after CSV load in Phase 1 loop.

### Fix 2: RIS Format Standardization (March 25, 2026)
**Issue:** synthesisr's `write_refs()` produced minimal RIS tags; Rayyan upload failed.  
**Symptom:** Rayyan rejected "invalid or incomplete record format".  
**Solution:** Implemented custom `write_ris_rayyan()` function that:
- Writes explicit `TY  - JOUR` (type: journal article) for each record
- Splits authors into separate `AU  - ` lines
- Includes all metadata tags: `TI`, `JO`, `PY`, `VL`, `IS`, `SP`, `AB`, `DO`, `UR`
- Ends each entry with `ER  - ` (record end)

### Fix 3: Missing File Resilience (April 1, 2026)
**Issue:** Script crashed if any expected CSV file was absent.  
**Symptom:** `file not found` error on `read.csv()` for missing `wos_main.csv`.  
**Solution:** Added file existence checks with conditional loading:
- Uses `file.exists()` before attempting `read.csv()`
- Logs warnings for each missing file
- Combines only available CSVs per engine
- Skips entire engine if no files exist
- Continues Phase 2 with whatever Phase 1 outputs were generated

---

## 📊 Deduplication Methodology

### Two-Pass Strategy (Per Engine & Cross-Engine)

#### Pass 1: Exact DOI Matching
- Uses `synthesisr::deduplicate(..., match_by = "doi", method = "exact")`
- Identifies records with identical DOI values
- High precision, requires DOI presence
- Removes clear duplicates across sources

#### Pass 2: String Similarity (Titles)
- Uses `find_duplicates(...$title, method = "string_osa", threshold = 5)`
- Matches titles with Optimal String Alignment (OSA) distance metric
- Preprocesses: lowercase, punctuation removal
- Catches near-duplicates (spelling variations, formatting)

#### Data Cleaning
- Removes curly braces from titles (Zotero artifact cleanup)
- Normalizes column names to lowercase
- Preserves all original metadata fields

---

## 📁 Project Structure (Current)

```
deduplication-trials-project/
├── data/
│   └── raw/
│       ├── Davis_2017/
│       │   ├── pubmed_main.csv
│       │   ├── pubmed_protocol.csv
│       │   ├── wos_main.csv
│       │   ├── wos_protocol.csv
│       │   ├── openalex_main.csv
│       │   └── openalex_protocol.csv
│       └── Delgado-Lista_2016/
│           ├── pubmed_main.csv
│           ├── pubmed_protocol.csv
│           ├── wos_protocol.csv           ← wos_main.csv MISSING
│           ├── openalex_main.csv
│           └── openalex_protocol.csv
├── outputs/
│   ├── Davis_2017/
│   │   ├── Phase1_*.csv
│   │   ├── FINAL_deduplicated_trials.csv
│   │   └── FINAL_deduplicated_trials.ris
│   └── Delgado-Lista_2016/
│       ├── Phase1_*.csv
│       ├── FINAL_deduplicated_trials.csv
│       └── FINAL_deduplicated_trials.ris
├── scripts/
│   └── deduplication_workflow.R           ← Main script (updated)
├── README.md                              ← Setup & usage guide
├── SUMMARY.md                             ← Process documentation
└── WORKFLOW_EXECUTION_LOG.md              ← This file
```

---

## 🎯 Key Learnings & Decisions

### 1. Trial-Based Organization
- Each trial has its own `data/raw/{trial_name}/` folder
- Each trial produces its own `outputs/{trial_name}/` folder
- Single script variable change (`trial_name`) enables batch processing
- Supports easy future analysis and auditing of specific trials

### 2. Graceful Handling of Missing Data
- Missing files no longer cause crashes
- Workflow adapts to 1, 2, or 3 available engines
- Phase 2 deduplicates whatever Phase 1 outputs exist
- Maintains semantics: exact DOI + title similarity matching

### 3. RIS Format Critical for Rayyan
- Rayyan requires specific RIS structure with `TY` and `ER` tags
- Custom RIS writer ensures compatibility
- All metadata fields preserved for downstream use

---

## 🔄 Workflow for Next Trials

### Step-by-Step

1. **Prepare data folder:**
   ```
   data/raw/[NewTrialName]/
   ```

2. **Add available CSV files** (exact names):
   - `pubmed_main.csv` and/or `pubmed_protocol.csv`
   - `wos_main.csv` and/or `wos_protocol.csv`
   - `openalex_main.csv` and/or `openalex_protocol.csv`
   - *Note: Any subset of these 6 files is acceptable*

3. **Update script:**
   - Open `scripts/deduplication_workflow.R`
   - Set `trial_name <- "[NewTrialName]"` (around line 30)

4. **Execute:**
   ```powershell
   cd c:\Users\hp\deduplication-trials-project
   & "C:\Program Files\R\R-4.5.1\bin\Rscript.exe" scripts/deduplication_workflow.R
   ```

5. **Retrieve outputs:**
   - All results appear in `outputs/[NewTrialName]/`
   - CSV: `FINAL_deduplicated_trials.csv`
   - RIS: `FINAL_deduplicated_trials.ris` (Rayyan-ready)

---

## ✅ Quality Assurance Checks

### For Each Trial Run
- [ ] Script completes without errors (exit code 0)
- [ ] Output folder created: `outputs/{trial_name}/`
- [ ] 5 Phase 1 CSV files exist (or fewer if engines missing)
- [ ] Final CSV file exists with deduplicated references
- [ ] Final RIS file exists with `TY`, `AU`, `TI`, `DO`, `ER` tags
- [ ] RIS file uploads successfully to Rayyan (or other import tool)

---

## 📌 Known Limitations & Future Enhancements

### Current Limitations
1. Column name discovery is automatic but assumes lowercase post-norm; edge cases with unusual column names may need manual mapping
2. RIS writer assumes `JOUR` (journal article) type for all records; other types (e.g., conference, book) are not differentiated
3. Author splitting on `; ` (semicolon+space); other separators may not work

### Potential Enhancements
1. Auto-detect document type from `item.type` column and set `TY` appropriately
2. Add configurable column mapping file per trial
3. Generate trial-specific deduplication report (PDF or HTML)
4. Batch process multiple trials in one run
5. Export to additional formats (BibTeX, JSON)

---

## 📞 Support & Troubleshooting

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Rayyan upload fails | RIS file rejected | Check RIS has `TY  - JOUR` on first line of each record |
| Script crashes on dataload | `read.csv`: file not found | Verify exact CSV filenames match template |
| Zero references output | Final CSV is empty | Check input CSV files have `title` or `doi` columns (lowercase) |
| Dedup produces no change | Input = Output | Check if duplicate detection thresholds need adjustment |

### Debug Steps
1. Check `outputs/{trial_name}/Phase1_*.csv` files exist for each available engine
2. Count references: Phase 1 → Phase 2 → Final (should decrease due to dedup)
3. inspect RIS file head/tail for proper `TY` / `ER` delimiters
4. Verify input CSVs have valid column names (case-insensitive post-norm)

---

## 📝 Change Log

| Date | Event | Impact |
|------|-------|--------|
| 2026-03-24 | Project started; Davis_2017 processed | First trial complete |
| 2026-03-25 | Column normalization + RIS writer fixes | Rayyan upload now works |
| 2026-04-01 | Missing file resilience added | Delgado-Lista_2016 processed successfully with partial data |

---

## 🎉 Current Status

**✅ All Systems Operational**
- 2 trials processed successfully
- Workflow handles complete and partial data gracefully
- RIS output Rayyan-compatible
- Ready for batch processing of additional trials
- No blocking issues identified

**Next action:** Upload next trial data to `data/raw/` and run workflow with updated `trial_name`.


# Data for ECON4538

This folder holds the data used in the lectures, recitations, and assignments. Paths in the
`.qmd` files are relative to their own folder, e.g. `../data/cps_00049.csv`.

| File | Source | Used in |
|------|--------|---------|
| `cps_00049.csv` | IPUMS CPS, ASEC 1990-2025 (not in git, see below) | `lectures/1-DocumentingInequality.qmd`, `lectures/3-Income_Processes.qmd` |
| `cps_00049.cbk`, `cps_00049.xml` | IPUMS codebook (text) and DDI metadata for the extract above | reference |
| `asec_1970_2019.csv` | IPUMS CPS, ASEC 1970-2019 (earlier extract) | `recitations/recitation-1.qmd` |
| `PCE_index.csv` | BEA PCE price index, annual, 2017 = 100 (downloaded from FRED) | deflating dollar amounts |
| `abb_aea_data.csv` | PSID extract (biennial, 1998-2008 survey years) from Arellano, Blundell and Bonhomme (2018) | `recitations/recitation-4.qmd`, `assignments/assignment-3.qmd` |

## `cps_00049.csv`: re-extracting from IPUMS CPS

The CSV is about 400 MB, so it is listed in `.gitignore` and is **not** in the repository.
To rebuild it:

1. Make a (free) account at <https://cps.ipums.org> and start a new extract.
2. **Samples**: select the ASEC (March Annual Social and Economic Supplement) samples for
   survey years **1990 through 2025** (36 samples). Do not add the monthly basic samples.
3. **Variables**: select the variables below. IPUMS adds the technical variables (`YEAR`,
   `SERIAL`, `MONTH`, `CPSID`, `ASECFLAG`, `HFLAG`, `ASECWTH`, `PERNUM`, `CPSIDP`, `CPSIDV`,
   `ASECWT`) automatically.

   | Group | Variables |
   |-------|-----------|
   | Demographics | `AGE`, `SEX`, `RACE`, `MARST`, `NCHILD`, `EDUC` |
   | Work | `WKSWORK1`, `UHRSWORKLY` |
   | Income | `INCWAGE`, `INCSS`, `INCWELFR`, `INCSSI`, `INCUNEMP`, `INCDISAB` |
   | Tax credits | `CTCCRD`, `EITCRED` |

4. **Case selection**: `AGE` 25 to 64 (persons).
5. **Data format**: CSV (comma delimited), rectangular (person) records.
6. Submit, download, unzip, and save the file as `data/cps_00049.csv`. Your extract will get a
   different number, so rename it (or change the path in the lectures). Keep the matching
   `.cbk`/`.xml` codebook alongside it.

The full sample and variable list is in `cps_00049.cbk` ("Samples selected" and the variable
availability table) and in the DDI file `cps_00049.xml`.

### Things to know when using the ASEC

- **Income year vs survey year.** `YEAR` is the survey year. The income and work variables
  (`INCWAGE`, `WKSWORK1`, `UHRSWORKLY`, the transfer variables) refer to the **previous
  calendar year**. Lecture 1 creates `INCYEAR = YEAR - 1` and deflates with the PCE index
  for `INCYEAR`. The 1990-2025 surveys therefore cover income years 1989-2024, which is
  exactly the range of `PCE_index.csv` needed. Demographic variables (age, marital status,
  number of children) are measured at the March survey date.
- **The 2014 split sample.** The 2014 ASEC was split into a 5/8 sample with the old income
  questions (`HFLAG == 0`) and a 3/8 sample with the redesigned questions (`HFLAG == 1`).
  Each sample's weights sum to the full population, so using both double counts 2014. The
  lectures keep `HFLAG == 1`. `HFLAG` is missing in all other years.
- **Weights.** Use `ASECWT` for person-level statistics.
- **Education coding.** `EDUC` records years of schooling in the 1990-1991 surveys and degrees
  from 1992 on (e.g. 72 = 12th grade before 1992, 73 = high school diploma, 111 = bachelor's
  degree). See the `EDUC` section of the codebook.
- **Top-coding.** `INCWAGE` is top-coded, and the top-coding rules change over time.

## Other files

- **`asec_1970_2019.csv`**: an older IPUMS CPS ASEC extract (survey years 1970-2019) with
  `RELATE`, occupation (`OCCLY`, `OCC90LY`), `INCTOT`, `INCBUS`, and transfer and tax
  credit variables (`ACTCCRD`, `EITCRED`, ...). No codebook is stored here; the column names
  are IPUMS CPS variable names. The same income-year caution applies.
- **`PCE_index.csv`**: columns `observation_date`, `PCE` (index, 2017 = 100), and `YEAR`,
  covering 1929-2024. Annual values of the BEA PCE price index as distributed by FRED. To update, download the annual series from FRED and append a row for each new year.
  It must cover the latest *income* year in the CPS data.
- **`abb_aea_data.csv`**: PSID household panel used by Arellano, Blundell and Bonhomme (2018,
  *AEA Papers and Proceedings*) to study income and consumption dynamics. Key columns:
  `person` (id), `year` (survey year minus 1900, i.e. 98, 100, ..., 108), `age`, and `y`
  (the income measure used in Recitation 4), plus consumption, asset, and demographic
  variables. Check the paper's replication files for exact variable definitions.

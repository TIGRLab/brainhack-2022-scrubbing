# brainhack-2022-scrubbing
Testing scrubbing parameters on clinical datasets

## Objectives
We started this project because SPINS and SPASD data have strong motion effects that cannot be separated from group effects (SSD vs ASD vs Controls).
This could be due to differences in the clinical populations given their symptoms. To alleviate the effect of motion in the analysis, 
[Power et al. (2014)](https://github.com/TIGRLab/brainhack-2022-scrubbing/files/10169520/Power.2014.motion.and.scrubbing.pdf) suggested ways to 
quality control for motion and introduced **scrubbing** as an additional step before cleaning the data. 
Scrubbing is a procedure that removes the TRs that have a big motion (as indicated by FD values that exceed a certain threshold) and the TRs between two
motion spikes that are too close to each other (the TR section in between two spikes is called the *island* of which the length can be specified).

With SPINS and SPASD in mind, we would like to test if scrubbing is a possible solution to remove the motion effects that confound the group effects.
However, schizophrenia and autism patients all tend to move more compared to healthy controls, so it might be worth checking different scrubbing
arguments to leverage the quality of the data and the amount of usable data that go into the final analysis.

## Data

We use data from SPINS and SPASD with three groups (SSD, ASD, and controls).

## Method

We use the latest version of nilearn (with `pip install git+https://github.com/nilearn/nilearn.git`) with the new function `nilearn.signal.clean` to 
perform scrubbing and cleaning.

The visualization for QC will be done with R.

## Before BrainHack

1. Run scrubbing + cleaning on various threshold
2. Extract FC
3. Extract distances

## BrainHack

1. Testing multiple thresholds (decrease from 5 mm) for Mean FD
    1. Check mean FD to check for group differences
    2. Distance-correlation scatter plots for different thresholds x each group (based on diagnostic or motion-alone or both)

> The data quality gained from scrubbing vs. the amount of data/people we lose according to the threshold

2. Decision
    1. Visually QC the plots (see [tutorial for plotting the figure for QC](https://github.com/TIGRLab/brainhack-2022-scrubbing/blob/main/notebooks/Testing-Visualization.md))
    2. Documentation

3. Parameters to test

| FD_threshold (mm) | scrubs (TR) | Note |
| -------- | -------- | -------- |
| 0.5     | 5     | Default; SPINS & SPASD (by groups)    |
| 0.2     | 5     | SPINS & SPASD (by groups)    |
| 0.5     | 10     | SPINS & SPASD (by groups)    |
| 0.2     | 10     | SPINS & SPASD (by groups)    |
| 0.5     | 3     | SPINS & SPASD (by groups)    |
| 0.2     | 3     | SPINS & SPASD  (by groups)   |
| 0     | -    | SPINS & SPASD (by groups)    |

* Optional: add a feature to scrub the TRs after the motion spike

## References:

**Power's Paper**: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3849338/

**Lindquist Paper**: https://onlinelibrary.wiley.com/doi/epdf/10.1002/hbm.24528

**Benchmark Paper**:
https://www.sciencedirect.com/science/article/pii/S1053811917302288

**PR w/Nilearn Code**: https://github.com/nilearn/nilearn/pull/3385


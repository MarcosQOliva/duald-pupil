# adaptive_pretest_noise

Standalone Psychtoolbox pre-test for estimating internal noise in log-ratio
units before running the main dual-decision numerosity task.

Run from MATLAB with:

```matlab
launcher_pretest_noise
```

Main files:

- `launcher_pretest_noise.m`
- `duald_pretest_noise.m`
- `functions/runSingleTrial_pretest.m`
- `functions/estimateNoiseAdaptive.m`
- `functions/computeSweetpointZeroLapse.m`

What it does:

- Runs a 60-trial maximum single-decision 2AFC numerosity task.
- Preserves the old 100-dot mapping:
  `diff = round(totalDots * tanh(logratio / 2))`
- Starts with a fixed `|log-ratio| = 0.16` trial, then a few random warm-up
  trials, then switches to adaptive sweet-point placement for slope
  estimation.
- Fits `P(right) = Phi(logratio / sigma)` after each trial with the same
  lognormal prior used in `misc/computeNoise.m`.
- Prints the final recommended `sigma` and `R = 2 * sigma` in the MATLAB
  command window.

Output files:

- `data/<subjectID>_pretest_noise.tsv`
  Behavioral data with the same column order as the main task:
  `id age gender trial decision n_left n_right side response accuracy RT conf conf_RT mode param`
- `data/<subjectID>_pretest_noise_trace.tsv`
  Trial-by-trial adaptive estimates and chosen difficulties.
- `data/<subjectID>_pretest_noise_summary.tsv`
  Final sigma recommendation.
- `data/<subjectID>_pretest_noise_results.mat`
  Saved MATLAB struct with full results.

Notes:

- Everything needed to run the pre-test is contained inside `pre-test`.
- Hardware-related settings are centralized in `duald_pretest_noise.m`
  inside `getDefaultSettings()`.
- The sweet-point optimizer uses the same expected-variance criterion as
  `misc/compute_sweetpoint.m`, but solves the one-dimensional zero-lapse
  case with `fminbnd` so it does not require `fmincon`.

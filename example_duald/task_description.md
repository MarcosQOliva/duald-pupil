# Project Overview
- Dual numerosity task with two sequential perceptual decisions per trial: participants judge which of two dot clouds has more dots; total dots per pair are fixed at 100 (ndots_ref = 50 each before applying the difficulty).
- Decision 1 and Decision 2 are separate intervals; only Decision 1 trials are used for noise fitting and adaptive parameter setting.
- Two conditions:
  - Fixed (F): difficulty is a single log-ratio value applied to every decision.
  - Range (R): difficulty log-ratio is drawn uniformly from a bounded range per decision.

# Key Design Details
- Dot stimuli: start from 50 dots per side; apply a signed difference so the pair sums to 100. Left/right numbers are set by subtracting/adding half the difference around the 50/50 split.
- Log-ratio difficulty maps to a dot-count difference via `diff = round(total * tanh(logratio/2))` with `total = 100`.
- Fixed condition:
  - Input F is a log-ratio.
  - Converted once to a dot difference using the formula above and reused for all trials (both decisions) in the main block.
- Range condition:
  - Input R is a log-ratio upper bound.
  - Minimum non-zero difficulty is `log(51/49)`.
  - For each decision, sample a log-ratio uniformly from `[log(51/49), R]`, then convert to a dot difference via `total * tanh(logratio/2)`.
- Practice blocks:
  - F: practice differences uniformly sampled around the fixed difference (50%–150% of the fixed diff).
  - R: practice log-ratios uniformly sampled in `[log(51/49), R]` (converted to differences in the trial function).

# Trial Flow and Data Logging
- `runSingleTrial.m`: presents Decision 1 and Decision 2 for a given pair of difficulties (`n_diff`), with optional `n_diff_is_logratio` flag to convert log-ratio to differences using `total * tanh(logratio/2)`. Returns two data lines and correctness for each decision.
- Each data row logs: `id, age, gender, trial, decision, n_left, n_right, side, response, accuracy, RT, conf, conf_RT, mode, param`.
- File naming:
  - Main task data: `data/<subjectID>_fixed`, `data/<subjectID>_range`.
  - Total score files: `<subjectID>_fixed_score.txt`, `<subjectID>_range_score.txt`.
  - Block self-reports: `data/<subjectID>_fixed_selfreport`, `data/<subjectID>_range_selfreport`.
  - Final global self-report: `data/<subjectID>_fixed_globalselfreport`, `data/<subjectID>_range_globalselfreport`.

# Block Self-Reports
- Controlled by `block_query_interval` (default 10 trials).
- `collectBlockEstimates.m`:
  - Grey background prompt.
  - Shows two lines “1:” and “2:” simultaneously; digits echo as typed.
  - Participant enters estimated correct counts for Decision 1, presses Enter, then enters for Decision 2, presses Enter.
- Self-report files contain rows: `id, trial_start, trial_end, true_first, true_second, reported_first, reported_second`.

# Final Global Self-Report (end of each block)
- `collectGlobalSelfReport.m`: mouse-controlled continuous VAS (0–100%), live percent readout under the scale, confirm with click or SPACE.
- Prompt text: “Estimate the percentage of participants who you believe performed worse than you on this task.”
- Saved once at block end by `duald_F` and `duald_R` into the global self-report files with columns `id, age, gender, estimate_percent, RT`.

# Launcher Logic
- `launcher.m` prompts for subject ID, age, gender, and first condition (F or R).
- Default log-ratio parameters: `F_DEFAULT = 0.1551326`, `R_DEFAULT = 0.3381922`; always used for the first session.
- After the first session:
  - Loads `data/<subjectID>_fixed` or `data/<subjectID>_range` corresponding to the first run.
  - Computes sigma via `computeNoise.m` using only `decision == 1`, log(n_right/n_left), MAP with LogNormal prior.
  - Computes mean accuracy `alpha` from the `accuracy` column for `decision == 1`.
  - Derives the second-session parameter with `F_from_alpha(alpha, sigma)` or `R_from_alpha(alpha, sigma)`.
  - Launches the second session (`duald_F` or `duald_R`) with that derived parameter.

# Analysis Functions
- `computeNoise.m`:
  - Model: `P(response==1) = Phi(logratio / sigma)`.
  - Prior: `sigma ~ LogNormal(mu_log=-2.834, sigma_log=1.646)`.
  - Uses Decision 1 trials only.
- `sanity_check_computeNoise.m`:
  - Simulates ~200 trials with a known sigma, generates log-ratios, responses from the model, writes a synthetic tab file, runs `computeNoise`, and prints true vs estimated sigma.
- `F_from_alpha.m`: returns `F = sigma * norminv(alpha)` (log-ratio difficulty for fixed condition).
- `R_from_alpha.m`: solves for R such that expected accuracy under uniform log-ratio in `[0, R]` matches alpha (via `alpha_from_R` and `fzero`).

# Usage Notes for Future Codex Sessions
- Run conditions directly:
  - `duald_F(subjectID, age, gender, F_logratio)`
  - `duald_R(subjectID, age, gender, R_logratio)`
- Run full two-session flow: execute `launcher.m` and choose which condition goes first; the second uses sigma/accuracy from the first to set its parameter.
- Assumptions:
  - Responses are coded 0/1; accuracy compares to the true higher side.
  - Total dots per pair = 100 (ndots_ref = 50).
  - Only Decision 1 trials are used for noise/alpha computations and adaptive parameter setting.

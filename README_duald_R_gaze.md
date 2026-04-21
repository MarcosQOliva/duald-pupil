# duald_R_gaze

This repository now includes a Tobii-gated version of the `example_duald` range-condition numerosity task.

Run it from MATLAB with:

```matlab
launcher_duald_R_gaze
```

Main files:

- `launcher_duald_R_gaze.m`
- `duald_R_gaze.m`
- `functions/runSingleTrial_gaze.m`
- `functions/setupTobii.m`
- `functions/waitForFixation.m`
- `functions/fetchAndAppendGaze.m`
- `functions/saveGazeData.m`
- `functions/cleanupExperiment.m`

Behavioral output:

- Saved to `data/<subjectID>_range_gaze`
- Column order matches the old `example_duald` range task:
  `id age gender trial decision n_left n_right side response accuracy RT conf conf_RT mode param`

Gaze output:

- Samples: `data/<subjectID>_range_gaze_gaze_samples.tsv`
- Events: `data/<subjectID>_range_gaze_gaze_events.tsv`

Implementation notes:

- The task preserves the old R-condition mapping:
  `diff = round(totalDots * tanh(logratio / 2))`
- Decision 1 and Decision 2 difficulties are sampled independently on every trial.
- Tobii gaze collection starts once and every online fetch is appended immediately to the in-memory log before being used for fixation control, so samples are not lost by buffer polling.

Local adaptation points:

- Screen geometry and Tobii defaults are in `duald_R_gaze.m` inside `getDefaultSettings()`.
- If your lab calibrates outside MATLAB, set `settings.tobii.runCalibration = false`.
- If you intentionally want a tracker-free dry run, set `settings.tobii.allowDummyMode = true`.

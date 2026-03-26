You are helping draft MATLAB code for a psychophysics experiment using Psychtoolbox and a Tobii eye tracker via the Tobii Pro MATLAB SDK.

I will provide two example subfolders:

1) example_dual
- This contains a near-match to the behavioral task we want, but without eye tracking.
- It implements the dual-decision introduced by Lisi et al. 2021., but using a numerosity perceptual judgment
- It includes two conditions, F and R.
- Use this folder as the PRIMARY source for:
  - task structure
  - stimulus generation
  - response collection
  - data logging
  - naming conventions
  - launcher / session flow
- Also read the included task_description.md for context about this previous experiment.

2) example_pupil
- This contains an eye-tracking experiment using a similar Tobii device / SDK.
- Use this folder as a SECONDARY source only for:
  - Tobii setup
  - connecting to the tracker
  - calibration flow
  - gaze coordinate handling
  - gaze-contingent trial start logic
  - saving eye-tracking samples
- IMPORTANT: this example contains a bug in its online gaze control logic.
- Specifically, it queried the Tobii MATLAB gaze buffer online to control fixation, but in the MATLAB SDK, subsequent calls to get_gaze_data() return the samples collected since the previous call. So naive online polling can consume the stream and cause data loss in the final saved dataset.
- You must design around this and avoid data loss.

Goal
Implement a NEW experiment that is essentially the R condition of the dual-decision numerosity task, but with Tobii-based fixation control before each trial and recoding of gaze position and pupil size.

High-level behavioral design
- The task is a dual sequential decision task with dot numerosity.
- Each trial has Decision 1 and Decision 2.
- On each decision, participants judge which of two dot clouds has more dots.
- Total dots per pair must sum to 100.
- The new experiment should match the R condition logic of the old task, EXCEPT:
  - difficulty for Decision 1 and Decision 2 must be sampled independently on every trial from the allowed range
  - i.e. do NOT reuse the same difficulty for both decisions within a trial unless it happens by chance
- The range sampling logic should follow the old R condition:
  - sample log-ratio uniformly from [log(51/49), R]
  - choose sign/randomized side appropriately
  - convert log-ratio to integer dot-count difference using the same formula as the old code
- Preserve existing behavioral conventions as much as possible unless a change is necessary for eye tracking.

Key task details to preserve from the old implementation
- Numerosity pair generation should preserve the “sum to 100” logic.
- The mapping from log-ratio to dot difference should match the old code.
- Data columns and row format should stay as close as possible to the previous implementation.
- If possible, preserve naming conventions and helper-function patterns from example_dual.
- Preserve the trial structure of two decisions per trial.
- Preserve response and confidence collection unless there is a strong reason to refactor.

Important notes from task_description.md
- The old design uses total dots = 100, with 50/50 as the reference split.
- Difference is computed from log-ratio with:
  diff = round(total * tanh(logratio/2))
- In the range condition, each decision should sample a log-ratio uniformly from [log(51/49), R] before conversion.
- Only Decision 1 trials were used in the original project for noise fitting / adaptive parameter setting. Keep data compatible with that downstream analysis unless explicitly impossible.
- Existing data fields include:
  id, age, gender, trial, decision, n_left, n_right, side, response, accuracy, RT, conf, conf_RT, mode, param
- Please inspect the old code and reuse the same column order when possible.

New eye-tracking requirement
Each trial should begin only when the participant is fixating the central fixation point.

I want fixation gating similar in spirit to the logic in example_pupil, but implemented correctly for the Tobii MATLAB SDK so that gaze data are not lost. I want to store gazedata files, with timestamp of the relevant task events (stimulus onset, offset, response, etc.)

Critical design requirement regarding Tobii MATLAB SDK
The MATLAB Tobii SDK works roughly like this:
- Create an EyeTrackingOperations object
- find_all_eyetrackers()
- get an EyeTracker object
- start collection with eyetracker.get_gaze_data()
- later calls to eyetracker.get_gaze_data() return gaze samples collected since the previous call
- stop collection with eyetracker.stop_gaze_data()

In the file tobii_SDK_psychtoolbox_example.txt you can see an minimal example of using the tobii SDK with the psychtoolbox

This means:
- DO NOT implement fixation checking by repeatedly calling get_gaze_data() and then later expect to recover the full trial data from the same buffer
- DO NOT rely on a design that empties / consumes the only copy of gaze samples needed for final storage
- The code must use a buffer-safe strategy

Implement a robust fixation-control strategy
Please design fixation gating in a way that avoids data loss. A good solution would be:
- Start gaze collection before the experiment or block
- During online fixation checking, only fetch gaze data in a controlled way
- Immediately append every fetched sample to a master in-memory log (or per-trial log) before using those same samples for online fixation decisions
- In other words, any sample used online must also be retained for offline saving
- Never discard samples that were fetched from the Tobii buffer
- At block end and/or trial end, write the accumulated gaze data to disk in a clean tabular format
- Make the logic resilient to empty fetches, invalid eyes, missing samples, and short dropouts

Recommended fixation criterion
Unless the old example strongly suggests a better choice, use something like:
- fixation point at screen center
- accept gaze when the most recent valid binocular estimate (or fallback averaged valid monocular estimate) lies within a circular radius around fixation
- require stable fixation for a minimum dwell time before trial onset, e.g. 200–300 ms
- allow brief invalid samples without fully resetting if they are very short
- use Tobii normalized display coordinates if that is what the SDK provides most directly, but convert carefully and consistently if working in pixels
- make all fixation parameters easy to edit in a settings struct

Behavior on tracking failure
- If there is no valid gaze for too long before trial start, display a message instructing the participant to look at the fixation point
- Optionally allow recalibration prompt between blocks
- Fail gracefully if no eye tracker is found: either abort with a clear message or allow a dummy mode only if clearly separated

Calibration
Use a practical approach:
- Prefer using Tobii Pro Eye Tracker Manager / standard SDK calibration flow rather than building a complicated custom calibration UI unless the example already contains a working and clean implementation
- If the example contains calibration code, adapt it only if it is simple and reliable
- Otherwise, provide a clean hook/function for calibration and document the expected workflow

What I want you to produce
Please generate a complete, runnable MATLAB implementation or as close to complete as possible, using Psychtoolbox and the Tobii Pro MATLAB SDK.

At minimum, provide:
1) A main launcher script for this new experiment
2) A main experiment function for the gaze-controlled R-style dual task
3) Helper functions for:
   - Tobii setup / connect
   - optional calibration hook
   - online fixation wait/check
   - safe gaze sample accumulation/logging
   - trial execution
   - dot stimulus generation
   - saving behavioral data
   - saving gaze data
   - cleanup / shutdown
4) A README or top-of-file comments explaining how to run it
5) Clear notes for any parts that need manual adaptation to local hardware / screen setup

File structure
Please propose a clean file structure, for example:
- launcher_duald_R_gaze.m
- duald_R_gaze.m
- runSingleTrial_gaze.m
- setupTobii.m
- waitForFixation.m
- fetchAndAppendGaze.m
- saveGazeData.m
- cleanupExperiment.m
- plus any helper files you think are needed

Implementation preferences
- Use Psychtoolbox coding style consistent with the old project where possible
- Keep parameters centralized in a settings/config struct
- Use try/catch with guaranteed cleanup:
  - Screen('CloseAll')
  - ShowCursor
  - Priority(0)
  - stop_gaze_data() if needed
- Write readable code with comments, but avoid unnecessary abstraction
- Reuse old code whenever possible rather than rewriting everything from scratch
- Be conservative and robust

Data logging requirements
Behavioral data:
- Preserve compatibility with the old behavioral file format as much as possible
- Use the same or very similar output filenames and directories, with a new suffix/name indicating gaze version

Gaze data:
- Save all fetched gaze samples, not just fixation summaries
- Include timestamps and as many useful SDK fields as are straightforward to extract, ideally:
  - system timestamp
  - device timestamp
  - left/right gaze point on display area
  - left/right validity
  - left/right pupil diameter
  - trial number
  - trial phase / event label if easy to add
- It is fine to store gaze data in a separate file from behavior
- Add event markers in the gaze log when feasible, e.g.:
  - block_start
  - fixation_on
  - fixation_acquired
  - stim1_on
  - stim1_off
  - response1
  - stim2_on
  - stim2_off
  - response2
  - trial_end

Very important constraints
- DO NOT implement the old bug where online gaze polling causes unrecoverable data loss
- DO ensure that Decision 1 and Decision 2 difficulty are independently randomized each trial
- DO preserve the old R-condition logic for how difficulty is sampled
- DO keep the code compatible with later analysis based on Decision 1
- DO comment clearly anywhere you are uncertain because of missing information in the example folders
- If something in the old code is messy, improve it only if necessary for correctness

How to inspect the examples
When reading the example folders, please explicitly identify and reuse:
- the old R-condition difficulty logic from example_dual
- the old runSingleTrial structure from example_dual
- the old data output format from example_dual
- the Tobii connection / calibration / gaze sample parsing patterns from example_pupil
- but replace the example_pupil online fixation-control logic with a buffer-safe implementation

Please return:
A) a short summary of the planned architecture
B) the MATLAB files (in this folder, and you can create a functions subfolder as in previous code containing all custom functions)
C) a brief explanation of how your fixation-control solution avoids Tobii buffer-related data loss
D) any assumptions you had to make

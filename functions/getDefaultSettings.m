function settings = getDefaultSettings()
settings.display.subDistCm = 60;
settings.display.monitorWidthMm = 525;
settings.display.skipSyncTests = 2;

settings.task.soa_range = [0.4, 0.6];
settings.task.iti = 1;
settings.task.n_trials = 400;
settings.task.n_trials_practice = 10;
settings.task.block_query_interval = 10;
settings.task.break_interval = 50;
settings.task.collect_confidence = [0, 0];
settings.task.ndots_ref = 50;
settings.task.stim_dur = 0.5;

settings.tobii.enable = true;
settings.tobii.allowDummyMode = false;
settings.tobii.runCalibration = true;
settings.tobii.fixation.centerNormXY = [0.5, 0.5];
settings.tobii.fixation.radiusNorm = 0.05;
settings.tobii.fixation.dwellTimeSec = 0.25;
settings.tobii.fixation.invalidGraceSec = 0.10;
settings.tobii.fixation.noGazePromptSec = 2.0;
settings.tobii.fixation.pollIntervalSec = 0.01;
end
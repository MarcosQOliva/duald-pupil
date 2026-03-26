function duald_R_gaze(subjectID, subjectAge, subjectGender, R, userSettings)
%DUALD_R_GAZE Range-condition dual numerosity task with Tobii fixation gating.
%
% This is a gaze-enabled adaptation of example_duald/duald_R.m.
% Reused from example_duald:
% - task flow, practice loop, block queries, score handling
% - two-decision trial structure and behavioral output format
% - range-condition difficulty mapping and dot stimulus helpers
%
% Reused from example_pupil / Tobii SDK example:
% - Tobii device discovery, ScreenBasedCalibration entry point
% - SDK field names for gaze position, pupil size, and timestamps
%
% Important design choice:
% - Gaze collection is started once and every call that fetches data from
%   the Tobii buffer immediately appends those samples to an in-memory log.
%   The same retained samples are then used for online fixation control and
%   later written to disk, avoiding the buffer-consumption bug in the old
%   example_pupil implementation.
%
% Usage:
%   duald_R_gaze(subjectID, age, gender, R_logratio)
%
% Hardware notes:
% - Edit getDefaultSettings() below for local screen geometry and Tobii
%   preferences.
% - Set settings.tobii.runCalibration = false if calibration is handled via
%   Tobii Pro Eye Tracker Manager outside the task.

if nargin < 4
    error('Usage: duald_R_gaze(subjectID, subjectAge, subjectGender, R, [userSettings])');
end
if nargin < 5
    userSettings = struct();
end

close all;
sca;
addpath('functions');

rng('shuffle');

settings = getDefaultSettings();
settings = mergeStructs(settings, userSettings);
settings.task.range_logratio = abs(R);
settings.task.logratio_min = log(51/49);
if settings.task.range_logratio < settings.task.logratio_min
    warning('Provided R is smaller than minimum log-ratio; using %.5f instead.', settings.task.logratio_min);
    settings.task.range_logratio = settings.task.logratio_min;
end

resultsDir = fullfile(pwd, 'data');
if exist(resultsDir, 'dir') < 1
    mkdir(resultsDir);
end

baseName = sprintf('%s_range_gaze', subjectID);
behavPath = fullfile(resultsDir, baseName);
selfReportPath = fullfile(resultsDir, [baseName '_selfreport']);
globalSelfPath = fullfile(resultsDir, [baseName '_globalselfreport']);
gazeBasePath = fullfile(resultsDir, baseName);
scorePath = fullfile(resultsDir, [baseName '_score.txt']);

datFid = -1;
selfRepFid = -1;
globalSelfRepFid = -1;
tobiiState = struct();
scr = struct();

try
    [datFid, selfRepFid, globalSelfRepFid] = openDataFiles(behavPath, selfReportPath, globalSelfPath);

    [scr, visual, keys] = openExperimentWindow(settings);
    tobiiState = setupTobii(settings, scr, subjectID, gazeBasePath);
    tobiiState = logGazeEvent(tobiiState, 0, 0, 'experiment_start');

    DrawFormattedText(scr.window, ...
        ['Welcome to the dual-decision numerosity experiment.\n\n' ...
         'Each trial starts only when your gaze is on the central fixation point.\n' ...
         'Then you will judge which dot cloud has more dots, twice per trial.\n\n' ...
         'Press any key to start the practice.'], ...
        'center', 'center', visual.black);
    Screen('Flip', scr.window);
    tobiiState = waitForAnyKeyWithGaze(tobiiState, 0, 0, 'practice_intro', keys.escapeKey);

    HideCursor;

    practice_min = log(60/40);
    practice_max = log(90/10);

    for t = 1:settings.task.n_trials_practice
        d_i = practice_min + rand(1, 2) * (practice_max - practice_min);
        [~, ~, first_correct, second_correct, tobiiState] = runSingleTrial_gaze( ...
            scr, visual, keys, settings, tobiiState, -t, d_i, true);

        Screen('Flip', scr.window);

        if first_correct == 1 && second_correct == 1
            practiceMessage = 'Well done! Both answers were correct.\n\nPress any key to continue.';
        elseif first_correct == 1 && second_correct == 0
            practiceMessage = 'The 1st answer was correct, but the 2nd was wrong.\n\nPress any key to continue.';
        elseif first_correct == 0 && second_correct == 1
            practiceMessage = 'The 2nd answer was correct, but the 1st was wrong.\n\nPress any key to continue.';
        else
            practiceMessage = 'Both answers were wrong.\n\nPress any key to continue.';
        end

        DrawFormattedText(scr.window, practiceMessage, 'center', 'center', visual.black);
        Screen('Flip', scr.window);
        tobiiState = waitForAnyKeyWithGaze(tobiiState, -t, 0, 'practice_feedback', keys.escapeKey);
    end

    DrawFormattedText(scr.window, ...
        ['Practice finished.\n\n' ...
         'From now on, each trial begins after stable central fixation.\n' ...
         'Try to keep looking at the fixation point until the dot clouds appear.\n\n' ...
         'Press any key to begin the experiment.'], ...
        'center', 'center', visual.black);
    Screen('Flip', scr.window);
    tobiiState = waitForAnyKeyWithGaze(tobiiState, 0, 0, 'experiment_intro', keys.escapeKey);
    tobiiState = logGazeEvent(tobiiState, 0, 0, 'block_start');

    ACC = [];
    block_first_correct = 0;
    block_second_correct = 0;

    for t = 1:settings.task.n_trials
        d_i = sampleRangeDifficulty(settings.task.range_logratio, settings.task.logratio_min, 2);
        [dataline1, dataline2, first_correct, second_correct, tobiiState] = runSingleTrial_gaze( ...
            scr, visual, keys, settings, tobiiState, t, d_i, false);

        ACC = [ACC, first_correct, second_correct]; %#ok<AGROW>
        block_first_correct = block_first_correct + first_correct;
        block_second_correct = block_second_correct + second_correct;

        fprintf(datFid, '%s\t%s\t%s\t%i\t%s\t%s\t%.5f\n', ...
            subjectID, subjectAge, subjectGender, t, dataline1, 'range', settings.task.range_logratio);
        fprintf(datFid, '%s\t%s\t%s\t%i\t%s\t%s\t%.5f\n', ...
            subjectID, subjectAge, subjectGender, t, dataline2, 'range', settings.task.range_logratio);

        if mod(t, settings.task.block_query_interval) == 0
            promptText = sprintf('For the last %d trials,\nestimate how many correct decisions you made:', ...
                settings.task.block_query_interval);
            [reported_first, reported_second] = collectBlockEstimates(scr, visual, promptText);

            trial_start = t - settings.task.block_query_interval + 1;
            trial_end = t;
            fprintf(selfRepFid, '%s\t%i\t%i\t%i\t%i\t%i\t%i\n', ...
                subjectID, trial_start, trial_end, block_first_correct, block_second_correct, ...
                reported_first, reported_second);

            tobiiState = logGazeEvent(tobiiState, t, 0, 'block_selfreport');
            tobiiState = fetchAndAppendGaze(tobiiState, t, 0, 'block_selfreport');

            block_first_correct = 0;
            block_second_correct = 0;
        end

        if mod(t, settings.task.break_interval) == 0 && t < settings.task.n_trials
            breakMessage = sprintf(['Need a break?\n\n' ...
                'You have completed %i out of %i total trials.\n\n' ...
                'Press any key to continue.'], t, settings.task.n_trials);
            DrawFormattedText(scr.window, breakMessage, 'center', 'center', visual.black);
            Screen('Flip', scr.window);
            tobiiState = logGazeEvent(tobiiState, t, 0, 'break_start');
            tobiiState = waitForAnyKeyWithGaze(tobiiState, t, 0, 'break', keys.escapeKey);
            tobiiState = logGazeEvent(tobiiState, t, 0, 'break_end');
        else
            Screen('FillOval', scr.window, visual.fixColor, ...
                CenterRectOnPoint([0, 0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
            Screen('Flip', scr.window);
            WaitSecs(settings.task.iti);
            tobiiState = fetchAndAppendGaze(tobiiState, t, 0, 'iti');
        end
    end

    promptText = 'Estimate the percentage of participants who you believe performed worse than you on this task.';
    [global_estimate, global_rt] = collectGlobalSelfReport(scr, visual, promptText);
    fprintf(globalSelfRepFid, '%s\t%s\t%s\t%i\t%.3f\n', ...
        subjectID, subjectAge, subjectGender, global_estimate, global_rt);
    tobiiState = logGazeEvent(tobiiState, settings.task.n_trials, 0, 'global_selfreport');
    tobiiState = fetchAndAppendGaze(tobiiState, settings.task.n_trials, 0, 'global_selfreport');

    message_string = ['Experiment Finished!\n\nYour score for this part is ', ...
        num2str(sum(ACC)), ' out of ', num2str(length(ACC)), '.\n\nPress any key to exit.'];
    DrawFormattedText(scr.window, message_string, 'center', 'center', visual.black);
    Screen('Flip', scr.window);
    tobiiState = logGazeEvent(tobiiState, settings.task.n_trials, 0, 'experiment_finished_screen');
    tobiiState = waitForAnyKeyWithGaze(tobiiState, settings.task.n_trials, 0, 'experiment_finished_screen', keys.escapeKey);

    fprintf('%s\n', strrep(message_string, '\n', ' '));
    file_id = fopen(scorePath, 'w');
    fprintf(file_id, '%i\n', sum(ACC));
    fclose(file_id);

    tobiiState = logGazeEvent(tobiiState, settings.task.n_trials, 0, 'experiment_end');
    tobiiState = fetchAndAppendGaze(tobiiState, settings.task.n_trials, 0, 'shutdown');
    saveGazeData(tobiiState);

    fclose(datFid);
    fclose(selfRepFid);
    fclose(globalSelfRepFid);
    cleanupExperiment(tobiiState);
catch ME
    if ~isempty(fieldnames(tobiiState))
        try
            tobiiState = logGazeEvent(tobiiState, -999, 0, 'error');
            tobiiState = fetchAndAppendGaze(tobiiState, -999, 0, 'error');
            saveGazeData(tobiiState);
        catch
        end
    end

    if datFid > 0
        fclose(datFid);
    end
    if selfRepFid > 0
        fclose(selfRepFid);
    end
    if globalSelfRepFid > 0
        fclose(globalSelfRepFid);
    end

    cleanupExperiment(tobiiState);
    rethrow(ME);
end

end

function [datFid, selfRepFid, globalSelfRepFid] = openDataFiles(behavPath, selfReportPath, globalSelfPath)
datFid = fopen(behavPath, 'w');
fprintf(datFid, ['id\tage\tgender\ttrial\tdecision\tn_left\tn_right\tside\tresponse\taccuracy\tRT\t' ...
    'conf\tconf_RT\tmode\tparam\n']);

selfRepFid = fopen(selfReportPath, 'w');
fprintf(selfRepFid, 'id\ttrial_start\ttrial_end\ttrue_first\ttrue_second\treported_first\treported_second\n');

globalSelfRepFid = fopen(globalSelfPath, 'w');
fprintf(globalSelfRepFid, 'id\tage\tgender\testimate_percent\tRT\n');
end

function [scr, visual, keys] = openExperimentWindow(settings)
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', settings.display.skipSyncTests);

screenNumber = max(Screen('Screens'));

visual.white = 255;
visual.grey = floor(255 / 2);
visual.black = 0;
visual.bgColor = visual.grey;
visual.fixColor = 170 / 255;

[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey / 255, [], 32, 2);
Screen('Flip', scr.window);

scr.ifi = Screen('GetFlipInterval', scr.window);
Screen('TextSize', scr.window, 60);
scr.topPriorityLevel = MaxPriority(scr.window);
Priority(scr.topPriorityLevel);

[scr.xCenter, scr.yCenter] = RectCenter(scr.windowRect);
[scr.xres, scr.yres] = Screen('WindowSize', scr.window);
Screen('BlendFunction', scr.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

scr.subDist = settings.display.subDistCm;
scr.width = settings.display.monitorWidthMm;

ppd = va2pix(1, scr);
visual.ppd = ppd;
visual.textSize = round(0.5 * ppd);
visual.fix_size = 0.1 * ppd;
visual.stim_size = 4 * ppd;
visual.stim_ecc = 4 * ppd;
visual.stim_rects = [ ...
    CenterRectOnPoint([0, 0, visual.stim_size, visual.stim_size], scr.xCenter - visual.stim_ecc, scr.yCenter)', ...
    CenterRectOnPoint([0, 0, visual.stim_size, visual.stim_size], scr.xCenter + visual.stim_ecc, scr.yCenter)'];
visual.stim_dur = settings.task.stim_dur;
visual.dots_dy = (visual.stim_size / 2) * 1.5;
visual.dots_xy = [scr.xCenter - visual.stim_ecc, scr.xCenter + visual.stim_ecc; ...
    scr.yCenter - visual.dots_dy, scr.yCenter - visual.dots_dy];
visual.dots_col_1 = (visual.white / 255) / 3;
visual.dots_col_2 = ([246, 14, 0; 0, 160, 0]' / 255);
visual.dots_size = 20;
visual.stim_pen_width = 1;
visual.inner_circle = round(visual.stim_size * 0.95);
visual.stim_dotsize = 0.08;
visual.stim_dotcolor = [visual.black, visual.black, visual.black, 0.65];
visual.stim_centers = [scr.xCenter - visual.stim_ecc, scr.yCenter; ...
    scr.xCenter + visual.stim_ecc, scr.yCenter];
visual.ndots_ref = settings.task.ndots_ref;

KbName('UnifyKeyNames');
keys.escapeKey = KbName('ESCAPE');
keys.leftKey = KbName('LeftArrow');
keys.rightKey = KbName('RightArrow');
end

function settings = getDefaultSettings()
settings.display.subDistCm = 65;
settings.display.monitorWidthMm = 480;
settings.display.skipSyncTests = 2;

settings.task.soa_range = [0.4, 0.6];
settings.task.iti = 1;
settings.task.n_trials = 200;
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

function out = mergeStructs(base, override)
out = base;
if ~isstruct(override)
    return;
end

overrideFields = fieldnames(override);
for i = 1:numel(overrideFields)
    thisField = overrideFields{i};
    if isstruct(override.(thisField)) && isfield(base, thisField) && isstruct(base.(thisField))
        out.(thisField) = mergeStructs(base.(thisField), override.(thisField));
    else
        out.(thisField) = override.(thisField);
    end
end
end

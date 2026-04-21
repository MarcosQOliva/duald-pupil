function results = duald_pretest_noise(subjectID, subjectAge, subjectGender, userSettings)
%DUALD_PRETEST_NOISE Standalone adaptive pre-test for numerosity noise.
%
% This is a short single-decision 2AFC pre-test for estimating internal
% noise in log-ratio units before running the main dual-decision task.
%
% Design choices:
% - One numerosity decision per trial, 60 trials maximum by default.
% - Trial 1 starts at |log-ratio| = 0.16.
% - Early warm-up trials sample random difficulties.
% - Subsequent trials use the zero-lapse slope sweet-point that minimizes
%   the expected variance of sigma, using the same Evar_sigma objective as
%   the material in pre-test/misc.
% - Sigma is fit after each trial with the same lognormal prior used in
%   misc/computeNoise.m.
%
% Behavioral output preserves the main task column order:
%   id age gender trial decision n_left n_right side response accuracy RT
%   conf conf_RT mode param
%
% Usage:
%   results = duald_pretest_noise(subjectID, subjectAge, subjectGender)
%   results = duald_pretest_noise(..., userSettings)

if nargin < 3
    error('Usage: duald_pretest_noise(subjectID, subjectAge, subjectGender, [userSettings])');
end
if nargin < 4
    userSettings = struct();
end

close all;
sca;

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, 'functions'));
addpath(fullfile(rootDir, 'misc'));

rng('shuffle');

settings = getDefaultSettings();
settings = mergeStructs(settings, userSettings);
settings.task.logratio_min = log(51 / 49);
settings.adaptive.initial_random_max = max(settings.adaptive.initial_random_max, settings.task.logratio_min);
settings.adaptive.max_logratio = max(settings.adaptive.max_logratio, settings.adaptive.initial_abs_logratio);

resultsDir = fullfile(rootDir, 'data');
if exist(resultsDir, 'dir') < 1
    mkdir(resultsDir);
end

baseName = sprintf('%s_pretest_noise', subjectID);
behaviorPath = fullfile(resultsDir, [baseName '.tsv']);
tracePath = fullfile(resultsDir, [baseName '_trace.tsv']);
summaryPath = fullfile(resultsDir, [baseName '_summary.tsv']);
resultsMatPath = fullfile(resultsDir, [baseName '_results.mat']);

behaviorFid = -1;
traceFid = -1;
scr = struct();

responses = nan(settings.task.n_trials, 1);
accuracies = nan(settings.task.n_trials, 1);
RTs = nan(settings.task.n_trials, 1);
side = nan(settings.task.n_trials, 1);
n_left = nan(settings.task.n_trials, 1);
n_right = nan(settings.task.n_trials, 1);
target_abs_logratio = nan(settings.task.n_trials, 1);
presented_logratio = nan(settings.task.n_trials, 1);
sigma_map = nan(settings.task.n_trials, 1);
sigma_mean = nan(settings.task.n_trials, 1);
sigma_sd = nan(settings.task.n_trials, 1);
next_sweetpoint_abs_logratio = nan(settings.task.n_trials, 1);
selection_mode = cell(settings.task.n_trials, 1);
posterior_details = cell(settings.task.n_trials, 1);

try
    [behaviorFid, traceFid] = openDataFiles(behaviorPath, tracePath);
    [scr, visual, keys] = openExperimentWindow(settings);

    showIntro(scr, visual, settings);
    waitForAnyKey(keys.escapeKey);
    HideCursor;
    ListenChar(2);

    for t = 1:settings.task.n_trials
        if t == 1
            currentEstimate = [];
        else
            currentEstimate = posterior_details{t - 1};
        end

        [target_abs_logratio(t), selection_mode{t}] = chooseNextDifficulty(t, currentEstimate, settings);

        trialResult = runSingleTrial_pretest(scr, visual, keys, settings, target_abs_logratio(t));

        responses(t) = trialResult.response;
        accuracies(t) = trialResult.accuracy;
        RTs(t) = trialResult.RT;
        side(t) = trialResult.side;
        n_left(t) = trialResult.n_left;
        n_right(t) = trialResult.n_right;
        presented_logratio(t) = trialResult.presented_logratio;

        fprintf(behaviorFid, '%s\t%s\t%s\t%i\t%i\t%i\t%i\t%i\t%i\t%i\t%.6f\t%.6f\t%.6f\t%s\t%.6f\n', ...
            subjectID, subjectAge, subjectGender, t, 1, trialResult.n_left, trialResult.n_right, ...
            trialResult.side, trialResult.response, trialResult.accuracy, trialResult.RT, ...
            NaN, NaN, settings.task.mode_label, target_abs_logratio(t));

        posterior_details{t} = estimateNoiseAdaptive(presented_logratio(1:t), responses(1:t), settings.adaptive.prior);
        sigma_map(t) = posterior_details{t}.sigma_map;
        sigma_mean(t) = posterior_details{t}.sigma_mean;
        sigma_sd(t) = posterior_details{t}.sigma_sd;

        if t < settings.task.n_trials
            next_sweetpoint_abs_logratio(t) = computeSweetpointZeroLapse( ...
                posterior_details{t}.sigma_mean, settings.task.logratio_min, settings.adaptive.max_logratio);
        end

        fprintf(traceFid, '%i\t%s\t%.6f\t%.6f\t%i\t%i\t%i\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n', ...
            t, selection_mode{t}, target_abs_logratio(t), presented_logratio(t), side(t), responses(t), ...
            accuracies(t), RTs(t), sigma_map(t), sigma_mean(t), sigma_sd(t), next_sweetpoint_abs_logratio(t));

        drawFixation(scr, visual);
        Screen('Flip', scr.window);
        WaitSecs(settings.task.iti);
    end

    finalEstimate = posterior_details{settings.task.n_trials};

    summaryFid = fopen(summaryPath, 'w');
    fprintf(summaryFid, 'id\tage\tgender\tn_trials\tsigma_map\tsigma_mean\tsigma_sd\trecommended_sigma\trecommended_range\n');
    fprintf(summaryFid, '%s\t%s\t%s\t%i\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n', ...
        subjectID, subjectAge, subjectGender, settings.task.n_trials, finalEstimate.sigma_map, ...
        finalEstimate.sigma_mean, finalEstimate.sigma_sd, finalEstimate.sigma_mean, 2 * finalEstimate.sigma_mean);
    fclose(summaryFid);

    results = struct();
    results.subjectID = subjectID;
    results.subjectAge = subjectAge;
    results.subjectGender = subjectGender;
    results.settings = settings;
    results.behaviorPath = behaviorPath;
    results.tracePath = tracePath;
    results.summaryPath = summaryPath;
    results.resultsMatPath = resultsMatPath;
    results.target_abs_logratio = target_abs_logratio;
    results.presented_logratio = presented_logratio;
    results.side = side;
    results.response = responses;
    results.accuracy = accuracies;
    results.RT = RTs;
    results.n_left = n_left;
    results.n_right = n_right;
    results.selection_mode = selection_mode;
    results.sigma_map_by_trial = sigma_map;
    results.sigma_mean_by_trial = sigma_mean;
    results.sigma_sd_by_trial = sigma_sd;
    results.next_sweetpoint_abs_logratio = next_sweetpoint_abs_logratio;
    results.finalEstimate = finalEstimate;
    results.recommended_sigma = finalEstimate.sigma_mean;
    results.recommended_range = 2 * finalEstimate.sigma_mean;

    save(resultsMatPath, 'results');

    showOutro(scr, visual, results);
    waitForAnyKey(keys.escapeKey);

    fprintf('\nAdaptive pre-test finished.\n');
    fprintf('Recommended sigma (posterior mean): %.6f log-ratio units\n', results.recommended_sigma);
    fprintf('MAP sigma: %.6f log-ratio units\n', finalEstimate.sigma_map);
    fprintf('Suggested main-task range R = 2 * sigma: %.6f log-ratio units\n\n', results.recommended_range);

    if behaviorFid > 0
        fclose(behaviorFid);
    end
    if traceFid > 0
        fclose(traceFid);
    end
    cleanupExperiment(scr);
catch ME
    if behaviorFid > 0
        fclose(behaviorFid);
    end
    if traceFid > 0
        fclose(traceFid);
    end
    cleanupExperiment(scr);
    rethrow(ME);
end

end

function [behaviorFid, traceFid] = openDataFiles(behaviorPath, tracePath)
behaviorFid = fopen(behaviorPath, 'w');
fprintf(behaviorFid, ['id\tage\tgender\ttrial\tdecision\tn_left\tn_right\tside\tresponse\taccuracy\tRT\t' ...
    'conf\tconf_RT\tmode\tparam\n']);

traceFid = fopen(tracePath, 'w');
fprintf(traceFid, ['trial\tselection_mode\ttarget_abs_logratio\tpresented_logratio\tside\tresponse\taccuracy\tRT\t' ...
    'sigma_map\tsigma_mean\tsigma_sd\tnext_sweetpoint_abs_logratio\n']);
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
Screen('TextSize', scr.window, 36);
scr.topPriorityLevel = MaxPriority(scr.window);
Priority(scr.topPriorityLevel);

[scr.xCenter, scr.yCenter] = RectCenter(scr.windowRect);
[scr.xres, scr.yres] = Screen('WindowSize', scr.window);
Screen('BlendFunction', scr.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

scr.subDist = settings.display.subDistCm;
scr.width = settings.display.monitorWidthMm;

ppd = va2pix(1, scr);
visual.ppd = ppd;
visual.textSize = round(0.45 * ppd);
visual.fix_size = 0.1 * ppd;
visual.stim_size = 4 * ppd;
visual.stim_ecc = 4 * ppd;
visual.stim_dur = settings.task.stim_dur;
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

function showIntro(scr, visual, settings)
message = sprintf(['Short pre-test for numerosity sensitivity.\n\n' ...
    'Each trial contains one decision only.\n' ...
    'Choose which dot cloud has more dots using the left and right arrows.\n\n' ...
    'The task runs for %d trials maximum.\n\n' ...
    'Press any key to begin.'], settings.task.n_trials);

DrawFormattedText(scr.window, message, 'center', 'center', visual.black);
Screen('Flip', scr.window);
end

function showOutro(scr, visual, results)
message = sprintf(['Pre-test finished.\n\n' ...
    'Recommended sigma: %.3f\n' ...
    'Suggested main-task range R = 2*sigma: %.3f\n\n' ...
    'Press any key to exit.'], results.recommended_sigma, results.recommended_range);

DrawFormattedText(scr.window, message, 'center', 'center', visual.black);
Screen('Flip', scr.window);
end

function drawFixation(scr, visual)
Screen('FillRect', scr.window, visual.bgColor / 255);
Screen('FillOval', scr.window, visual.fixColor, ...
    CenterRectOnPoint([0, 0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
end

function waitForAnyKey(escapeKey)
while true
    [keyisdown, ~, keycode] = KbCheck(-1);
    if keyisdown && keycode(escapeKey)
        error('Pre-test terminated by user.');
    elseif keyisdown
        KbReleaseWait;
        return;
    end
    WaitSecs(0.005);
end
end

function [targetAbsLogratio, selectionMode] = chooseNextDifficulty(trialNumber, currentEstimate, settings)
if trialNumber == 1
    targetAbsLogratio = settings.adaptive.initial_abs_logratio;
    selectionMode = 'warmup_fixed';
elseif trialNumber <= settings.adaptive.n_warmup
    targetAbsLogratio = settings.task.logratio_min + rand() * ...
        (settings.adaptive.initial_random_max - settings.task.logratio_min);
    selectionMode = 'warmup_random';
else
    if isempty(currentEstimate) || ~isfield(currentEstimate, 'sigma_mean') || ~isfinite(currentEstimate.sigma_mean)
        sigmaRef = settings.adaptive.initial_abs_logratio;
    else
        sigmaRef = currentEstimate.sigma_mean;
    end
    targetAbsLogratio = computeSweetpointZeroLapse( ...
        sigmaRef, settings.task.logratio_min, settings.adaptive.max_logratio);
    selectionMode = 'adaptive_sweetpoint';
end
end

function settings = getDefaultSettings()
settings.display.subDistCm = 65;
settings.display.monitorWidthMm = 480;
settings.display.skipSyncTests = 2;

settings.task.soa_range = [0.4, 0.6];
settings.task.iti = 0.75;
settings.task.n_trials = 60;
settings.task.ndots_ref = 50;
settings.task.stim_dur = 0.5;
settings.task.mode_label = 'adaptive_pretest';

settings.adaptive.initial_abs_logratio = 0.16;
settings.adaptive.n_warmup = 6;
settings.adaptive.initial_random_max = 0.32;
settings.adaptive.max_logratio = log(95 / 5);
settings.adaptive.prior.mu_log = -1.519961;
settings.adaptive.prior.sigma_log = 0.2855135;
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

function cleanupExperiment(scr)
try
    ListenChar(0);
catch
end

Priority(0);
ShowCursor;

if isstruct(scr) && isfield(scr, 'window') && ~isempty(scr.window)
    sca;
else
    Screen('CloseAll');
end
end

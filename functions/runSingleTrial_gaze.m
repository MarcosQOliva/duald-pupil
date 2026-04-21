function [dataline1, dataline2, first_correct, second_correct, tobiiState] = ...
    runSingleTrial_gaze(scr, visual, keys, settings, tobiiState, trialNumber, n_diff_logratio, isPractice)
%RUNSINGLETRIAL_GAZE Gaze-gated version of example_duald/functions/runSingleTrial.m

if nargin < 8
    isPractice = false;
end

if isscalar(n_diff_logratio)
    n_diff_logratio = [n_diff_logratio, n_diff_logratio];
elseif ~isvector(n_diff_logratio) || numel(n_diff_logratio) ~= 2
    error('n_diff_logratio must be a scalar or a two-element vector.');
end

trialPhasePrefix = 'trial';
if isPractice
    trialPhasePrefix = 'practice_trial';
end

soa1 = settings.task.soa_range(1) + rand(1) * (settings.task.soa_range(2) - settings.task.soa_range(1));
soa2 = 0.2 + settings.task.soa_range(1) + rand(1) * (settings.task.soa_range(2) - settings.task.soa_range(1));

tobiiState = logGazeEvent(tobiiState, trialNumber, 0, [trialPhasePrefix '_start']);
[tobiiState, ~] = waitForFixation(scr, visual, tobiiState, trialNumber, keys.escapeKey);

side = round(rand(1, 1)) + 1;
n1 = buildRangePairFromLogRatio(n_diff_logratio(1), visual.ndots_ref, side);

%% Decision 1
drawDecisionFixation(scr, visual, 1);
Screen('Flip', scr.window);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 1, 'decision1_fix');

drawDecisionStimulus(scr, visual, 1, n1);
tobiiState = logGazeEvent(tobiiState, trialNumber, 1, 'stim1_on');
t_on = Screen('Flip', scr.window, GetSecs + soa1);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 1, 'decision1_stim');

drawDecisionFixation(scr, visual, 1);
tobiiState = logGazeEvent(tobiiState, trialNumber, 1, 'stim1_off');
t_off = Screen('Flip', scr.window, t_on + visual.stim_dur);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 1, 'decision1_poststim');

[resp_right, tResp, tobiiState] = waitForArrowResponse(keys, tobiiState, trialNumber, 1, t_off);
first_correct = computeAccuracy(side, resp_right);

if first_correct == 1
    side2 = 2;
else
    side2 = 1;
end

if settings.task.collect_confidence(1) == 1
    [conf1, confRT1] = collect_confidence_rating(scr, visual, 1);
    tobiiState = logGazeEvent(tobiiState, trialNumber, 1, 'confidence1');
    tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 1, 'confidence1');
else
    conf1 = NaN;
    confRT1 = NaN;
end

dataline1 = sprintf('%i\t%i\t%i\t%i\t%i\t%i\t%2f\t%.2f\t%.2f', ...
    1, n1, side, resp_right, first_correct, tResp, conf1, confRT1);

%% Decision 2
n2 = buildRangePairFromLogRatio(n_diff_logratio(2), visual.ndots_ref, side2);

drawDecisionFixation(scr, visual, 2);
Screen('Flip', scr.window);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 2, 'decision2_fix');

drawDecisionStimulus(scr, visual, 2, n2);
tobiiState = logGazeEvent(tobiiState, trialNumber, 2, 'stim2_on');
t_on = Screen('Flip', scr.window, GetSecs + soa2);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 2, 'decision2_stim');

drawDecisionFixation(scr, visual, 2);
tobiiState = logGazeEvent(tobiiState, trialNumber, 2, 'stim2_off');
t_off = Screen('Flip', scr.window, t_on + visual.stim_dur);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 2, 'decision2_poststim');

[resp_right, tResp, tobiiState] = waitForArrowResponse(keys, tobiiState, trialNumber, 2, t_off);
second_correct = computeAccuracy(side2, resp_right);

if settings.task.collect_confidence(2) == 1
    [conf2, confRT2] = collect_confidence_rating(scr, visual, 2);
    tobiiState = logGazeEvent(tobiiState, trialNumber, 2, 'confidence2');
    tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 2, 'confidence2');
else
    conf2 = NaN;
    confRT2 = NaN;
end

dataline2 = sprintf('%i\t%i\t%i\t%i\t%i\t%i\t%2f\t%.2f\t%.2f', ...
    2, n2, side2, resp_right, second_correct, tResp, conf2, confRT2);

Screen('FillOval', scr.window, visual.fixColor, ...
    CenterRectOnPoint([0, 0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('Flip', scr.window);
tobiiState = logGazeEvent(tobiiState, trialNumber, 0, [trialPhasePrefix '_end']);
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 0, 'trial_end');
end

%%% Helper functions below

function drawDecisionFixation(scr, visual, decisionNumber)
Screen('FillRect', scr.window, visual.bgColor / 255);
Screen('FillOval', scr.window, visual.fixColor, ...
    CenterRectOnPoint([0, 0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));

if decisionNumber == 1
    Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
else
    Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
end

drawCenteredText(scr.window, num2str(decisionNumber), scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
end

function drawDecisionStimulus(scr, visual, decisionNumber, nDots)
drawDecisionFixation(scr, visual, decisionNumber);
drawDots(scr, visual, nDots);
end

function [resp_right, tResp, tobiiState] = waitForArrowResponse(keys, tobiiState, trialNumber, decisionNumber, t_off)
resp_right = NaN;
tResp = NaN;

while isnan(resp_right)
    tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, decisionNumber, sprintf('decision%i_response', decisionNumber));
    [keyisdown, secs, keycode] = KbCheck(-1);
    if keyisdown && keycode(keys.escapeKey)
        error('Experiment terminated by user.');
    elseif keyisdown && (keycode(keys.leftKey) || keycode(keys.rightKey))
        tResp = secs - t_off;
        if keycode(keys.rightKey)
            resp_right = 1;
        elseif keycode(keys.leftKey)
            resp_right = 0;
        end
        tobiiState = logGazeEvent(tobiiState, trialNumber, decisionNumber, sprintf('response%i', decisionNumber));
        tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, decisionNumber, sprintf('response%i', decisionNumber));
        KbReleaseWait;
    end
    WaitSecs(0.005);
end
end

function accuracy = computeAccuracy(correctSide, resp_right)
if correctSide == 2
    accuracy = resp_right == 1;
else
    accuracy = resp_right == 0;
end
end

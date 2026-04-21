function trialResult = runSingleTrial_pretest(scr, visual, keys, settings, targetAbsLogratio)
%RUNSINGLETRIAL_PRETEST Run one single-decision numerosity trial.

soa = settings.task.soa_range(1) + rand() * ...
    (settings.task.soa_range(2) - settings.task.soa_range(1));

side = round(rand()) + 1;
n = buildRangePairFromLogRatio(targetAbsLogratio, visual.ndots_ref, side);
presented_logratio = log(double(n(2)) / double(n(1)));

KbReleaseWait;

drawPretestFixation(scr, visual);
fixOnset = Screen('Flip', scr.window);
WaitSecs('UntilTime', fixOnset + soa);

drawPretestStimulus(scr, visual, n);
stimOnset = Screen('Flip', scr.window);
WaitSecs('UntilTime', stimOnset + visual.stim_dur);

drawPretestFixation(scr, visual);
stimOffset = Screen('Flip', scr.window);

[response, RT] = waitForArrowResponse(keys, stimOffset);
accuracy = computeAccuracy(side, response);

trialResult = struct();
trialResult.n_left = n(1);
trialResult.n_right = n(2);
trialResult.side = side;
trialResult.response = response;
trialResult.accuracy = accuracy;
trialResult.RT = RT;
trialResult.presented_logratio = presented_logratio;
trialResult.target_abs_logratio = targetAbsLogratio;
end

function drawPretestFixation(scr, visual)
Screen('FillRect', scr.window, visual.bgColor / 255);
Screen('FillOval', scr.window, visual.fixColor, ...
    CenterRectOnPoint([0, 0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
end

function drawPretestStimulus(scr, visual, nDots)
drawPretestFixation(scr, visual);
drawDots(scr, visual, nDots);
end

function [response, RT] = waitForArrowResponse(keys, stimOffset)
response = NaN;
RT = NaN;

while isnan(response)
    [keyisdown, secs, keycode] = KbCheck(-1);
    if keyisdown && keycode(keys.escapeKey)
        error('Pre-test terminated by user.');
    elseif keyisdown && (keycode(keys.leftKey) || keycode(keys.rightKey))
        RT = secs - stimOffset;
        if keycode(keys.rightKey)
            response = 1;
        else
            response = 0;
        end
        KbReleaseWait;
    end
    WaitSecs(0.005);
end
end

function accuracy = computeAccuracy(correctSide, response)
if correctSide == 2
    accuracy = response == 1;
else
    accuracy = response == 0;
end
end

function [tobiiState, fixationAcquired] = waitForFixation(scr, visual, tobiiState, trialNumber, escapeKey)
%WAITFORFIXATION Wait until stable central fixation is detected.

fixationAcquired = false;
fixCfg = tobiiState.settings.fixation;

if ~tobiiState.enabled
    fixationAcquired = true;
    return;
end

tobiiState = logGazeEvent(tobiiState, trialNumber, 0, 'fixation_on');

dwellStart = NaN;
invalidStart = NaN;
lastValidWallTime = GetSecs;

while ~fixationAcquired
    Screen('FillRect', scr.window, visual.bgColor / 255);
    Screen('FillOval', scr.window, visual.fixColor, ...
        CenterRectOnPoint([0, 0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));

    if (GetSecs - lastValidWallTime) > fixCfg.noGazePromptSec
        DrawFormattedText(scr.window, 'Please look at the central fixation point.', 'center', scr.yCenter + visual.ppd, visual.black);
    end

    Screen('Flip', scr.window);
    tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 0, 'fixation_wait');

    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && keyCode(escapeKey)
        error('Experiment terminated by user.');
    end

    if all(isfinite(tobiiState.lastValidNormXY))
        gazeNorm = tobiiState.lastValidNormXY;
        distToFix = sqrt(sum((gazeNorm - fixCfg.centerNormXY) .^ 2));
        if distToFix <= fixCfg.radiusNorm
            lastValidWallTime = GetSecs;
            invalidStart = NaN;
            if isnan(dwellStart)
                dwellStart = GetSecs;
            elseif (GetSecs - dwellStart) >= fixCfg.dwellTimeSec
                fixationAcquired = true;
            end
        else
            dwellStart = NaN;
            invalidStart = NaN;
            lastValidWallTime = GetSecs;
        end
    else
        if isnan(invalidStart)
            invalidStart = GetSecs;
        elseif (GetSecs - invalidStart) > fixCfg.invalidGraceSec
            dwellStart = NaN;
        end
    end

    WaitSecs(fixCfg.pollIntervalSec);
end

tobiiState = logGazeEvent(tobiiState, trialNumber, 0, 'fixation_acquired');
tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, 0, 'fixation_acquired');
end

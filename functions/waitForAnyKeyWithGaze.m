function tobiiState = waitForAnyKeyWithGaze(tobiiState, trialNumber, decisionNumber, phaseLabel, escapeKey)
%WAITFORANYKEYWITHGAZE Keep draining the Tobii buffer while waiting for input.

while true
    tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, decisionNumber, phaseLabel);
    [keyisdown, ~, keycode] = KbCheck(-1);
    if keyisdown
        if keycode(escapeKey)
            error('Experiment terminated by user.');
        end
        KbReleaseWait;
        break;
    end
    WaitSecs(0.01);
end
end

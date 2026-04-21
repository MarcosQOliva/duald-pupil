function tobiiState = logGazeEvent(tobiiState, trialNumber, decisionNumber, eventLabel)
%LOGGAZEEVENT Store a precise event marker alongside the gaze samples.

if isempty(tobiiState) || ~isstruct(tobiiState)
    return;
end

timestamp = NaN;
if isfield(tobiiState, 'enabled') && tobiiState.enabled && isfield(tobiiState, 'Tobii')
    timestamp = tobiiState.Tobii.get_system_time_stamp();
end

tobiiState.currentEventLabel = eventLabel;
tobiiState.currentEventTimestamp = timestamp;
tobiiState.events(end + 1, :) = { ...
    tobiiState.subjectID, trialNumber, decisionNumber, eventLabel, timestamp, GetSecs};
end

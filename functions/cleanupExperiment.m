function cleanupExperiment(tobiiState)
%CLEANUPEXPERIMENT Safe shutdown for PTB and Tobii resources.

try
    if ~isempty(tobiiState) && isstruct(tobiiState) && ...
            isfield(tobiiState, 'enabled') && tobiiState.enabled && ...
            isfield(tobiiState, 'isCollecting') && tobiiState.isCollecting
        tobiiState.eyetracker.stop_gaze_data();
    end
catch
end

Priority(0);
ShowCursor;
sca;
end

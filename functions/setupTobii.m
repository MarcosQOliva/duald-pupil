function tobiiState = setupTobii(settings, scr, subjectID, gazeBasePath, visual)
%SETUPTOBII Connect to a Tobii tracker and start safe continuous collection.

tobiiState = struct();
tobiiState.enabled = false;
tobiiState.dummyMode = false;
tobiiState.isCollecting = false;
tobiiState.subjectID = subjectID;
tobiiState.gazeBasePath = gazeBasePath;
tobiiState.samples = cell(0, 23);
tobiiState.events = cell(0, 6);
tobiiState.currentEventLabel = '';
tobiiState.currentEventTimestamp = NaN;
tobiiState.lastValidNormXY = [NaN, NaN];
tobiiState.lastValidPixXY = [NaN, NaN];
tobiiState.lastValidSystemTimestamp = NaN;
tobiiState.lastFetchWallTime = NaN;
tobiiState.scr = scr;
tobiiState.settings = settings.tobii;

if ~settings.tobii.enable
    tobiiState.dummyMode = true;
    return;
end

Tobii = EyeTrackingOperations();
found_eyetrackers = Tobii.find_all_eyetrackers();

if isempty(found_eyetrackers)
    if settings.tobii.allowDummyMode
        warning('No eye tracker found. Running in explicit dummy mode.');
        tobiiState.dummyMode = true;
        return;
    end
    error('No Tobii eye tracker found.');
end

eyetracker_address = found_eyetrackers(1).Address;
eyetracker = Tobii.get_eyetracker(eyetracker_address);

if ~isa(eyetracker, 'EyeTracker')
    if settings.tobii.allowDummyMode
        warning('Eye tracker connection failed. Running in explicit dummy mode.');
        tobiiState.dummyMode = true;
        return;
    end
    error('Failed to connect to Tobii eye tracker.');
end

disp(['Address: ' eyetracker.Address]);
disp(['Name: ' eyetracker.Name]);
disp(['Serial Number: ' eyetracker.SerialNumber]);
disp(['Model: ' eyetracker.Model]);
disp(['Firmware Version: ' eyetracker.FirmwareVersion]);
disp(['Runtime Version: ' eyetracker.RuntimeVersion]);

tobiiState.enabled = true;
tobiiState.Tobii = Tobii;
tobiiState.eyetracker = eyetracker;

if settings.tobii.runCalibration
    tobiiState.eyetracker = calibrateTobiiHook(scr, tobiiState.eyetracker, visual);
end

% Start collection once. Subsequent calls to get_gaze_data() will be
% consumed immediately into tobiiState.samples by fetchAndAppendGaze().
tobiiState.eyetracker.get_gaze_data();
tobiiState.isCollecting = true;
end

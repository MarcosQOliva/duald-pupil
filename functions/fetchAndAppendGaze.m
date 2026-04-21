function tobiiState = fetchAndAppendGaze(tobiiState, trialNumber, decisionNumber, phaseLabel)
%FETCHANDAPPENDGAZE Fetch Tobii samples and immediately retain them in memory.
%
% This function is the key buffer-safe layer. Any samples consumed from the
% Tobii SDK buffer are appended to tobiiState.samples before being used for
% online fixation decisions or timing alignment.

if isempty(tobiiState) || ~isstruct(tobiiState)
    return;
end

if ~isfield(tobiiState, 'enabled') || ~tobiiState.enabled || ~tobiiState.isCollecting
    tobiiState.lastFetchWallTime = GetSecs;
    return;
end

gaze_data = tobiiState.eyetracker.get_gaze_data();
tobiiState.lastFetchWallTime = GetSecs;

if isempty(gaze_data)
    return;
end

for i = 1:length(gaze_data)
    sample = gaze_data(i);

    deviceTimestamp = getNestedValue(sample, {'DeviceTimeStamp'}, NaN);
    systemTimestamp = getNestedValue(sample, {'SystemTimeStamp'}, NaN);

    leftValid = getNestedValue(sample, {'LeftEye', 'GazePoint', 'Validity', 'value'}, NaN);
    rightValid = getNestedValue(sample, {'RightEye', 'GazePoint', 'Validity', 'value'}, NaN);
    leftPoint = getNestedValue(sample, {'LeftEye', 'GazePoint', 'OnDisplayArea'}, [NaN, NaN]);
    rightPoint = getNestedValue(sample, {'RightEye', 'GazePoint', 'OnDisplayArea'}, [NaN, NaN]);

    [leftXNorm, leftYNorm] = unpackPoint(leftPoint);
    [rightXNorm, rightYNorm] = unpackPoint(rightPoint);
    [avgXNorm, avgYNorm] = combineEyes([leftXNorm, leftYNorm], logicalOrZero(leftValid), [rightXNorm, rightYNorm], logicalOrZero(rightValid));

    avgXPix = avgXNorm * tobiiState.scr.xres;
    avgYPix = avgYNorm * tobiiState.scr.yres;

    leftPupilValid = getNestedValue(sample, {'LeftEye', 'Pupil', 'Validity', 'value'}, NaN);
    if isnan(leftPupilValid)
        leftPupilValid = getNestedValue(sample, {'LeftEye', 'Pupil', 'Validity'}, NaN);
    end
    rightPupilValid = getNestedValue(sample, {'RightEye', 'Pupil', 'Validity', 'value'}, NaN);
    if isnan(rightPupilValid)
        rightPupilValid = getNestedValue(sample, {'RightEye', 'Pupil', 'Validity'}, NaN);
    end
    leftPupilDiameter = getNestedValue(sample, {'LeftEye', 'Pupil', 'Diameter'}, NaN);
    rightPupilDiameter = getNestedValue(sample, {'RightEye', 'Pupil', 'Diameter'}, NaN);

    tobiiState.samples(end + 1, :) = { ...
        tobiiState.subjectID, trialNumber, decisionNumber, phaseLabel, ...
        tobiiState.currentEventLabel, tobiiState.currentEventTimestamp, ...
        deviceTimestamp, systemTimestamp, ...
        leftValid, leftXNorm, leftYNorm, ...
        rightValid, rightXNorm, rightYNorm, ...
        avgXNorm, avgYNorm, avgXPix, avgYPix, ...
        leftPupilValid, leftPupilDiameter, rightPupilValid, rightPupilDiameter, ...
        tobiiState.lastFetchWallTime};

    if isfinite(avgXNorm) && isfinite(avgYNorm)
        tobiiState.lastValidNormXY = [avgXNorm, avgYNorm];
        tobiiState.lastValidPixXY = [avgXPix, avgYPix];
        tobiiState.lastValidSystemTimestamp = systemTimestamp;
    end
end
end

function [x, y] = unpackPoint(point)
x = NaN;
y = NaN;
if isnumeric(point) && numel(point) >= 2
    x = double(point(1));
    y = double(point(2));
end
end

function [avgX, avgY] = combineEyes(leftXY, leftValid, rightXY, rightValid)
avgX = NaN;
avgY = NaN;

validPoints = [];
if leftValid && all(isfinite(leftXY))
    validPoints = [validPoints; leftXY];
end
if rightValid && all(isfinite(rightXY))
    validPoints = [validPoints; rightXY];
end

if ~isempty(validPoints)
    avgX = mean(validPoints(:, 1), 'omitnan');
    avgY = mean(validPoints(:, 2), 'omitnan');
end
end

function value = getNestedValue(container, fieldPath, defaultValue)
value = defaultValue;
try
    value = container;
    for i = 1:numel(fieldPath)
        value = value.(fieldPath{i});
    end
catch
    value = defaultValue;
end
end

function tf = logicalOrZero(value)
tf = false;
if isnumeric(value) && ~isempty(value) && isfinite(value)
    tf = value ~= 0;
elseif islogical(value)
    tf = value;
end
end

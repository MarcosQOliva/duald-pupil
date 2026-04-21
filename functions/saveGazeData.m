function saveGazeData(tobiiState)
%SAVEGAZEDATA Write retained gaze samples and event markers to disk.

if isempty(tobiiState) || ~isstruct(tobiiState) || ~isfield(tobiiState, 'gazeBasePath')
    return;
end

samplePath = [tobiiState.gazeBasePath '_gaze_samples.tsv'];
eventPath = [tobiiState.gazeBasePath '_gaze_events.tsv'];

fid = fopen(samplePath, 'w');
fprintf(fid, ['subject_id\ttrial\tdecision\tphase\tevent_label\tevent_system_timestamp\t' ...
    'device_timestamp\tsystem_timestamp\t' ...
    'left_valid\tleft_x_norm\tleft_y_norm\t' ...
    'right_valid\tright_x_norm\tright_y_norm\t' ...
    'avg_x_norm\tavg_y_norm\tavg_x_pix\tavg_y_pix\t' ...
    'left_pupil_valid\tleft_pupil_diameter\t' ...
    'right_pupil_valid\tright_pupil_diameter\tfetch_wall_time\n']);

for i = 1:size(tobiiState.samples, 1)
    row = tobiiState.samples(i, :);
    fprintf(fid, '%s\n', strjoin(cellfun(@formatField, row, 'UniformOutput', false), sprintf('\t')));
end
fclose(fid);

fid = fopen(eventPath, 'w');
fprintf(fid, 'subject_id\ttrial\tdecision\tevent_label\tevent_system_timestamp\tevent_wall_time\n');
for i = 1:size(tobiiState.events, 1)
    row = tobiiState.events(i, :);
    fprintf(fid, '%s\n', strjoin(cellfun(@formatField, row, 'UniformOutput', false), sprintf('\t')));
end
fclose(fid);
end

function out = formatField(value)
if ischar(value)
    out = value;
elseif isstring(value)
    out = char(value);
elseif isempty(value)
    out = '';
elseif isnumeric(value) || islogical(value)
    if isscalar(value)
        if isnan(value)
            out = 'NaN';
        elseif isinf(value)
            out = 'Inf';
        elseif abs(value - round(value)) < 1e-9
            out = sprintf('%.0f', value);
        else
            out = sprintf('%.10f', value);
        end
    else
        out = mat2str(value);
    end
else
    out = '';
end
end

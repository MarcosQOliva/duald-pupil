% launcher_duald_R_gaze.m
% Launcher for the Tobii-gated range-condition dual-decision numerosity task.
%
% Usage:
%   1) Ensure Psychtoolbox is installed and the Tobii Pro MATLAB SDK is on
%      the MATLAB path.
%   2) Open this repository in MATLAB.
%   3) Run:
%         launcher_duald_R_gaze
%
% Notes:
% - The launcher keeps the old participant dialog style from example_duald.
% - Hardware-related settings are centralized inside duald_R_gaze.m.

R_DEFAULT = 0.3528962;

prompt = {'Participant ID', 'Age', 'Gender', 'R upper bound (log-ratio, blank = default)'};
dlgtitle = 'Dual-Decision R Gaze Launcher';
dims = [1 60];
definput = {'', '', '', num2str(R_DEFAULT, '%.7f')};

answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Launcher cancelled.');
    return;
end

subjectID = strtrim(answer{1});
subjectAge = strtrim(answer{2});
subjectGender = strtrim(answer{3});
R_text = strtrim(answer{4});

if isempty(subjectID) || isempty(subjectAge) || isempty(subjectGender)
    error('Subject ID, age, and gender are required.');
end

if isempty(R_text)
    R = R_DEFAULT;
else
    R = str2double(R_text);
end

if ~isfinite(R)
    error('R must be numeric.');
end

duald_R_gaze(subjectID, subjectAge, subjectGender, R);

% launcher_pretest_noise.m
% Launcher for the standalone adaptive single-decision numerosity pre-test.
%
% Usage:
%   1) Ensure Psychtoolbox is installed.
%   2) Open the repository in MATLAB.
%   3) Run:
%         launcher_pretest_noise

prompt = {'Participant ID', 'Age', 'Gender'};
dlgtitle = 'Adaptive Noise Pre-Test Launcher';
dims = [1 60];
definput = {'', '', ''};

answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Launcher cancelled.');
    return;
end

subjectID = strtrim(answer{1});
subjectAge = strtrim(answer{2});
subjectGender = strtrim(answer{3});

if isempty(subjectID) || isempty(subjectAge) || isempty(subjectGender)
    error('Subject ID, age, and gender are required.');
end

duald_pretest_noise(subjectID, subjectAge, subjectGender);

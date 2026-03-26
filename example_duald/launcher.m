% launcher.m
% Simple GUI launcher to run fixed (F) and range (R) sessions sequentially.

% Defaults (can be adjusted later) -- log-ratio values
F_DEFAULT = 0.1618775;
R_DEFAULT =  0.3528962;

% Randomize default first condition (user can override in dialog)
if rand > 0.5
    defaultFirstCond = 'R';
else
    defaultFirstCond = 'F';
end

% Collect participant info and first condition via dialog
prompt = {'Participant ID', 'Age', 'Gender', 'First condition (F or R)'};
dlgtitle = 'Dual-Decision Experiment Launcher';
dims = [1 50];
definput = {'', '', '', defaultFirstCond};
fprintf('\nDialog fields are:\n\t1) Participant ID;\n\t2) Age\n\t3)Gender\n\t4)First condition (F or R)');
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Launcher cancelled.');
    return;
end

subjectID = strtrim(answer{1});
subjectAge = strtrim(answer{2});
subjectGender = strtrim(answer{3});
firstCond = upper(strtrim(answer{4}));

if isempty(subjectID) || isempty(subjectAge) || isempty(subjectGender)
    error('Subject ID, age, and gender are required.');
end

if ~ismember(firstCond, {'F','R'})
    error('First condition must be either F or R.');
end

% Determine run order
if strcmp(firstCond, 'F')
    order = {'F','R'};
else
    order = {'R','F'};
end

fprintf('Starting experiments for %s. Order: %s then %s.\n', subjectID, order{1}, order{2});

% Ensure helper functions are on path
addpath('functions');

% Run first condition with defaults
if strcmp(order{1}, 'F')
    duald_F(subjectID, subjectAge, subjectGender, F_DEFAULT);
else
    duald_R(subjectID, subjectAge, subjectGender, R_DEFAULT);
end

% Compute sigma and accuracy from first session to set second-session value
if strcmp(order{1}, 'F')
    firstFile = fullfile('data', sprintf('%s_fixed', subjectID));
else
    firstFile = fullfile('data', sprintf('%s_range', subjectID));
end

if ~isfile(firstFile)
    error('Could not find first-session data file: %s', firstFile);
end

[sigma_hat, ~] = computeNoise(firstFile);

T = readtable(firstFile, 'Delimiter', '\t', 'FileType', 'text');
if ismember('decision', T.Properties.VariableNames)
    mask = T.decision == 1;
else
    mask = true(height(T),1);
end
if ~any(mask)
    error('No valid trials found in first-session data');
end
alpha_hat = mean(T.accuracy(mask));

% Derive second-session parameter from alpha and sigma
if strcmp(order{2}, 'F')
    second_param = F_from_alpha(alpha_hat, sigma_hat);
else
    second_param = R_from_alpha(alpha_hat, sigma_hat);
end

fprintf('First session done. Estimated sigma=%.4f, alpha=%.4f. Next %s value set to %.5f.\n', sigma_hat, alpha_hat, order{2}, second_param);

% Run second condition with derived parameter
if strcmp(order{2}, 'F')
    duald_F(subjectID, subjectAge, subjectGender, second_param);
else
    duald_R(subjectID, subjectAge, subjectGender, second_param);
end

fprintf('All sessions completed for %s.\n', subjectID);

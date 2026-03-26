function duald_R(subjectID, subjectAge, subjectGender, R)
%DUALD_R Run dual decision task with uniformly random difficulty in +/-R.
%   duald_R(subjectID, subjectAge, subjectGender, R) runs the task drawing
%   the absolute numerosity difference uniformly from 0..R on every
%   decision (sign is randomized by the task).
%
%   The function collects the same participant info as the original script
%   (id/age/gender) but now receives them as inputs alongside the range R.
%
%   NB: all info except R is provided a char strings

if nargin < 4
    error('Usage: duald_R(subjectID, subjectAge, subjectGender, R)');
end

% Clear the workspace
close all;
sca;

% add custom functions 
addpath('functions');

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));

% Normalize difficulty (log-ratio scale)
logratio_min = log(51/49); % smallest non-zero symmetric split around 50/50
range_logratio = abs(R);
if range_logratio < logratio_min
    warning('Provided R is smaller than minimum log-ratio; using %.5f instead.', logratio_min);
    range_logratio = logratio_min;
end

%----------------------------------------------------------------------
%                 Prepare for saving data
%----------------------------------------------------------------------

% Make a directory for the results
if IsWin
    resultsDir = [pwd '\data\'];
    if exist(resultsDir, 'dir') < 1
        mkdir(resultsDir);
    end
else
    resultsDir = [pwd '/data/'];
    if exist(resultsDir, 'dir') < 1
        mkdir(resultsDir);
    end
end

% prep data header
datFid = fopen([resultsDir subjectID '_range'], 'w');
fprintf(datFid, ['id\tage\tgender\ttrial\tdecision\tn_left\tn_right\tside\tresponse\taccuracy\tRT\t' ...
    'conf\tconf_RT\tmode\tparam\n']);

% self-report file
selfRepFid = fopen([resultsDir subjectID '_range_selfreport'], 'w');
fprintf(selfRepFid, 'id\ttrial_start\ttrial_end\ttrue_first\ttrue_second\treported_first\treported_second\n');

% global self-report file
globalSelfRepFid = fopen([resultsDir subjectID '_range_globalselfreport'], 'w');
fprintf(globalSelfRepFid, 'id\tage\tgender\testimate_percent\tRT\n');
    
%----------------------------------------------------------------------
%                       Display settings
%----------------------------------------------------------------------

scr.subDist = 65;   % subject distance (cm)
scr.width   = 480; %310;  % monitor width (mm)

%----------------------------------------------------------------------
%                       Task settings
%----------------------------------------------------------------------

soa_range = [0.4, 0.6];
iti = 1; % inter trial interval
n_trials = 200; % it should be divisible by 5
n_trials_practice = 10;
block_query_interval = 10; % after this many trials ask for accuracy estimates

% if you want also self-report ratings after each decision [1, 2]
collect_confidence = [0, 0]; 

%----------------------------------------------------------------------
%                       Initialize PTB
%----------------------------------------------------------------------

% Setup PTB with some default values
PsychDefaultSetup(2);

% Skip sync tests for demo purposes only
Screen('Preference', 'SkipSyncTests', 2);

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
visual.white =255;%WhiteIndex(screenNumber);
visual.grey = floor(255/2);%visual.white / 2;
visual.black = 0; %BlackIndex(screenNumber);
visual.bgColor = visual.grey;
visual.fixColor = 170/255;

% Open the screen
%[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey/255, [0 0 1920 1200], 32, 2); % debug
%[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey/255, [1920 0 3840 1080], 32, 2); % debug
[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey/255, [], 32, 2);

% Flip to clear
Screen('Flip', scr.window);

% Query the frame duration
ifi = Screen('GetFlipInterval', scr.window);
scr.ifi = ifi;

% Set the text size
Screen('TextSize', scr.window, 60);

% Query the maximum priority level
topPriorityLevel = MaxPriority(scr.window);

% Get the centre coordinate of the scr.window
[scr.xCenter, scr.yCenter] = RectCenter(scr.windowRect);

% Get the heigth and width of screen [pix]
[scr.xres, scr.yres] = Screen('WindowSize', scr.window); 

% Set the blend funciton for the screen
Screen('BlendFunction', scr.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%----------------------------------------------------------------------
%                       Stimuli
%----------------------------------------------------------------------
ppd = va2pix(1,scr); % pixel per degree
visual.ppd  = ppd;

visual.textSize = round(0.5*ppd);

% fixation
visual.fix_size = 0.1*ppd;

% stimulus size and ececntricity
visual.stim_size = 4*ppd;
visual.stim_ecc = 4*ppd; %2.25*ppd;
visual.stim_rects = [CenterRectOnPoint([0,0, visual.stim_size, visual.stim_size], scr.xCenter-visual.stim_ecc, scr.yCenter)', ...
    CenterRectOnPoint([0,0, visual.stim_size, visual.stim_size], scr.xCenter+visual.stim_ecc, scr.yCenter)'];

% stimulus duration
visual.stim_dur = 0.5;

% placeholder locations
visual.dots_dy = (visual.stim_size/2)*1.5;
visual.dots_xy = [scr.xCenter-visual.stim_ecc, scr.xCenter+visual.stim_ecc; ...
    scr.yCenter-visual.dots_dy, scr.yCenter-visual.dots_dy];

visual.dots_col_1 =(visual.white/255)/3;
visual.dots_col_2 = ([246, 14,0; 0 160 0]'/255);
visual.dots_size = 20;

% stim dots parameters
visual.stim_pen_width = 1;
visual.inner_circle = round(visual.stim_size * 0.95);
visual.stim_dotsize = 0.08;
visual.stim_dotcolor = [visual.black, visual.black, visual.black, 0.65];
visual.stim_centers = [scr.xCenter-visual.stim_ecc, scr.yCenter;...
    scr.xCenter+visual.stim_ecc, scr.yCenter];

visual.ndots_ref = 50;
logratio_to_diff = @(lr) round(visual.ndots_ref*2*tanh(lr/2));
visual.ndots_dif_range = [logratio_to_diff(logratio_min), logratio_to_diff(range_logratio)];

%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
KbName('UnifyKeyNames')
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

%----------------------------------------------------------------------
%                       Practice trials
%----------------------------------------------------------------------

DrawFormattedText(scr.window, 'Welcome to our experiment \n\n \n\n Press any key to start the practice',...
    'center', 'center', visual.black);
Screen('Flip', scr.window);
WaitSecs(0.2);
KbStrokeWait;

HideCursor; % hide mouse cursor

% practice_min = logratio_min;
% practice_max = range_logratio;
practice_min = log(60/40); 
practice_max = log(90/10);

for t = 1:n_trials_practice
    
    % run trials (sample log-ratio uniformly, convert inside runSingleTrial)
    d_i = practice_min + rand(1,2) * (practice_max - practice_min);
    [~, ~, first_correct, second_correct] = runSingleTrial(scr, visual, leftKey, rightKey, soa_range, d_i , collect_confidence, true);
    
    Screen('Flip', scr.window);
    
    % feedback
    if first_correct==1 && second_correct==1
        DrawFormattedText(scr.window, 'Well done! both answers were correct. \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
        
    elseif first_correct==1 && second_correct==0
        
        DrawFormattedText(scr.window, 'The 1st answer was correct, but you made an error in the 2nd. \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
        
    elseif first_correct==0 && second_correct==1
        
        DrawFormattedText(scr.window, 'The 2nd answer was correct, but you made an error in the 1st. \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
    
    elseif first_correct==0 && second_correct==0
        
        DrawFormattedText(scr.window, 'Both answers were wrong... \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
        
    end
        
end

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

DrawFormattedText(scr.window, 'Practice finished! \n\n Press any key to begin the experiment \n\n From now on giving correct answers will increase your chance of winning the prize.',...
    'center', 'center', visual.black);
Screen('Flip', scr.window);
KbStrokeWait;

HideCursor; % hide mouse cursor
ACC = [];
block_first_correct = 0;
block_second_correct = 0;

% Animation loop: we loop for the total number of trials
for t = 1:n_trials
    
    % draw log-ratio uniformly from [logratio_min, range_logratio] for each decision
    d_i = logratio_min + rand(1,2) * (range_logratio - logratio_min);
    [dataline1, dataline2, first_correct, second_correct] = runSingleTrial(scr, visual, leftKey, rightKey, soa_range, d_i, collect_confidence, true);
    ACC = [ACC, first_correct, second_correct];
    block_first_correct = block_first_correct + first_correct;
    block_second_correct = block_second_correct + second_correct;
    
    % save data
    dataline1 = sprintf('%s\t%s\t%s\t%i\t%s\t%s\t%.5f\n', subjectID, subjectAge, subjectGender, t, dataline1, 'range', range_logratio);
    fprintf(datFid, dataline1);

    dataline2 = sprintf('%s\t%s\t%s\t%i\t%s\t%s\t%.5f\n', subjectID, subjectAge, subjectGender, t, dataline2, 'range', range_logratio);
    fprintf(datFid, dataline2);
    
    % block accuracy query
    if mod(t, block_query_interval)==0
        % promptText = sprintf('For the last %d trials,\nindicate how many were correct.', block_query_interval);
        promptText = sprintf('For the last %d trials,\nestimate how many correct decisions you made:.', block_query_interval);
        [reported_first, reported_second] = collectBlockEstimates(scr, visual, promptText);
        
        trial_start = t - block_query_interval + 1;
        trial_end = t;
        selfReportLine = sprintf('%s\t%i\t%i\t%i\t%i\t%i\t%i\n', subjectID, trial_start, trial_end, block_first_correct, block_second_correct, reported_first, reported_second);
        fprintf(selfRepFid, selfReportLine);
        
        block_first_correct = 0;
        block_second_correct = 0;
    end
    
    if mod(t,50)==0
        
        break_message = sprintf('Need a break? \n\n\n You have completed %i out of %i total trials. \n\n\n\n\n Press any key to continue.', t, n_trials);
        
        DrawFormattedText(scr.window, break_message,'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
    else
        Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
        Screen('Flip', scr.window);
        WaitSecs(iti);
    end
        
end

% close data file
fclose(datFid);

% final global self-evaluation (0-100% VAS)
promptText = 'Estimate the percentage of participants who you believe performed worse than you on this task.';
[global_estimate, global_rt] = collectGlobalSelfReport(scr, visual, promptText);
globalLine = sprintf('%s\t%s\t%s\t%i\t%.3f\n', subjectID, subjectAge, subjectGender, global_estimate, global_rt);
fprintf(globalSelfRepFid, globalLine);


% End of experiment screen. We clear the screen once they have made their
% response
message_string = ['Experiment Finished! \n\n Your score for this part is ', num2str(sum(ACC )), ' out of ', num2str(length(ACC )), '. \n\n Press Any Key To Exit'];
DrawFormattedText(scr.window, message_string,...
    'center', 'center', visual.black);
Screen('Flip', scr.window);

% -------------------------------------------------------------------------
% goodbye
KbStrokeWait;
sca;

% print score on command window
fprintf('%s\n',message_string);

% save also into a text file
total_score = sum(ACC);
file_name = sprintf('%s_range_score.txt', subjectID);
file_id = fopen(file_name, 'w');
fprintf(file_id, '%i\n', total_score);
fclose(file_id);
fclose(selfRepFid);
fclose(globalSelfRepFid);
end

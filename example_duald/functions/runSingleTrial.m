function [dataline1, dataline2, first_correct, second_correct] = runSingleTrial(scr, visual, leftKey, rightKey, soa_range, n_diff, collect_confidence, n_diff_is_logratio)

% note that here n_diff is a vector with 2 levels [decision1, decision2]
% if n_diff_is_logratio is true, values are interpreted as log-ratios and
% converted to differences assuming total dots = 2*visual.ndots_ref.

if nargin < 7
    error('runSingleTrial requires at least 7 arguments.');
end
if nargin < 8
    n_diff_is_logratio = false;
end

if isscalar(n_diff)
    n_diff = [n_diff, n_diff];
elseif ~isvector(n_diff) || numel(n_diff) ~= 2
    error('n_diff must be either a scalar or a vector of length 2.');
end

% convert log-ratio to difference if needed
if n_diff_is_logratio
    totalDots = visual.ndots_ref * 2;
    conv_fun = @(lr) round(totalDots * tanh(lr/2));
    n_diff = arrayfun(conv_fun, n_diff);
end

% --------------------------------------------------------
% trial settings
soa = soa_range(1)+rand(1)*(soa_range(2)-soa_range(1));
soa2 = soa_range(1)+rand(1)*(soa_range(2)-soa_range(1));

side = round(rand(1,1)) + 1;
if side == 2
    n = [visual.ndots_ref-round(n_diff(1)/2), ...
        visual.ndots_ref-round(n_diff(1)/2) + n_diff(1)];
else
    n = [visual.ndots_ref-round(n_diff(1)/2) + n_diff(1),...
        visual.ndots_ref-round(n_diff(1)/2)];
end

%% DECISION 1 % --------------------------------------------------------

% --------------------------------------------------------
% fixation spot
Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
drawCenteredText(scr.window, '1', scr.xCenter, visual.dots_xy(2,1), visual.black, visual.textSize);
fix_on = Screen('Flip', scr.window);
t_flip = fix_on;

% --------------------------------------------------------
% stimulus sequence

% stimulus on
Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
drawDots(scr, visual, n);
drawCenteredText(scr.window, '1', scr.xCenter, visual.dots_xy(2,1), visual.black, visual.textSize);
t_on = Screen('Flip', scr.window, t_flip + soa);

% stimulus off
Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
drawCenteredText(scr.window, '1', scr.xCenter, visual.dots_xy(2,1), visual.black, visual.textSize);
t_off = Screen('Flip', scr.window, t_on + visual.stim_dur );

% --------------------------------------------------------
% wait for response
resp_right = NaN;
while isnan(resp_right)
    [keyisdown, secs, keycode] = KbCheck(-1);
    if keyisdown && (keycode(leftKey) || keycode(rightKey))
        tResp = secs - t_off;
        if keycode(rightKey)
            resp_right = 1;
        elseif keycode(leftKey)
            resp_right = 0;
        end
    end
end

if side==2
    if resp_right==1
        accuracy = 1;
    else
        accuracy = 0;
    end
else
    if resp_right==0
        accuracy = 1;
    else
        accuracy = 0;
    end
end

if accuracy == 1
    side2 = 2;
else
    side2 = 1;
end

first_correct = accuracy;

if collect_confidence(1)==1
    [conf, conf_RT]=collect_confidence_rating(scr, visual, 1);
else
    conf= NaN;
    conf_RT= NaN;
end

% write data line to file
dataline1 = sprintf('%i\t%i\t%i\t%i\t%i\t%i\t%2f\t%.2f\t%.2f', 1, n, side, resp_right, accuracy, tResp,conf,conf_RT);


%% DECISION 2 % --------------------------------------------------------

% set stimuli locations for decision 2
if side2 == 2
    n = [visual.ndots_ref-round(n_diff(2)/2), ...
        visual.ndots_ref-round(n_diff(2)/2) + n_diff(2)];
else
    n = [visual.ndots_ref-round(n_diff(2)/2) + n_diff(2),...
        visual.ndots_ref-round(n_diff(2)/2)];
end

% --------------------------------------------------------
% fixation spot
Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
drawCenteredText(scr.window, '2', scr.xCenter, visual.dots_xy(2,1), visual.black, visual.textSize);
fix_on = Screen('Flip', scr.window);
t_flip = fix_on;

% --------------------------------------------------------
% stimulus sequence

% stimulus on
Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
drawCenteredText(scr.window, '2', scr.xCenter, visual.dots_xy(2,1), visual.black, visual.textSize);
drawDots(scr, visual, n);
t_on = Screen('Flip', scr.window, t_flip + soa2);

% stimulus off
Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
drawCenteredText(scr.window, '2', scr.xCenter, visual.dots_xy(2,1), visual.black, visual.textSize);
t_off = Screen('Flip', scr.window, t_on + visual.stim_dur );


% --------------------------------------------------------
% wait for response
resp_right = NaN;
while isnan(resp_right)
    [keyisdown, secs, keycode] = KbCheck(-1);
    if keyisdown && (keycode(leftKey) || keycode(rightKey))
        tResp = secs - t_off;
        if keycode(rightKey)
            resp_right = 1;
        elseif keycode(leftKey)
            resp_right = 0;
        end
    end
end

if side2==2
    if resp_right==1
        accuracy = 1;
    else
        accuracy = 0;
    end
else
    if resp_right==0
        accuracy = 1;
    else
        accuracy = 0;
    end
end

second_correct = accuracy;

if collect_confidence(1)==1
    [conf, conf_RT]=collect_confidence_rating(scr, visual, 2);
else
    conf= NaN;
    conf_RT= NaN;
end

% write data line to file
dataline2 = sprintf('%i\t%i\t%i\t%i\t%i\t%i\t%2f\t%.2f\t%.2f', 2, n, side2, resp_right, accuracy, tResp,conf,conf_RT);

Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
Screen('Flip', scr.window);

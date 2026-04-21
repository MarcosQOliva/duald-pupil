function [percentEstimate, RT] = collectGlobalSelfReport(scr, visual, promptText)
%COLLECTGLOBALSELFREPORT Collect a single post-block self-assessment on a VAS.

center = [scr.xCenter, scr.yCenter];
VASwidth = round(8 * visual.ppd);
VASoffset = 0;
l = VASwidth / 2;
max_x = center(1) + l;
min_x = center(1) - l;
range_x = max_x - min_x;
knobRadius = max(6, round(0.15 * visual.ppd));
textSz = max(round(visual.textSize), 32);
spaceKey = KbName('space');

SetMouse(center(1), center(2) + VASoffset, scr.window);
[mx, ~, ~] = GetMouse(scr.window);
xpos = min(max(mx, min_x), max_x);

start_time = GetSecs;
RT = NaN;
confirmed = false;
prevButtons = [0 0 0];

ShowCursor('Arrow', scr.window);

while ~confirmed
    [mx, ~, buttons] = GetMouse(scr.window);
    xpos = min(max(mx, min_x), max_x);
    percentEstimate = round(((xpos - min_x) / range_x) * 100);

    Screen('FillRect', scr.window, visual.grey / 255);
    Screen('TextSize', scr.window, textSz);
    DrawFormattedText(scr.window, promptText, 'center', center(2) - 180, visual.black);
    DrawFormattedText(scr.window, 'Move the cursor, then click (or press SPACE) to confirm.', 'center', center(2) - 100, visual.black);
    Screen('DrawLine', scr.window, [255 255 255], min_x, center(2) + VASoffset, max_x, center(2) + VASoffset, 2);
    Screen('DrawLine', scr.window, [255 255 255], min_x, center(2) + VASoffset + 20, min_x, center(2) + VASoffset);
    Screen('DrawLine', scr.window, [255 255 255], max_x, center(2) + VASoffset + 20, max_x, center(2) + VASoffset);
    DrawFormattedText(scr.window, '0%', min_x - 15, center(2) + VASoffset + 40, visual.black);
    DrawFormattedText(scr.window, '100%', max_x - 30, center(2) + VASoffset + 40, visual.black);
    Screen('FillOval', scr.window, [255 255 255], CenterRectOnPoint([0 0 knobRadius * 2 knobRadius * 2], xpos, center(2) + VASoffset));
    DrawFormattedText(scr.window, sprintf('%i%%', percentEstimate), 'center', center(2) + VASoffset + 90, visual.black);
    Screen('Flip', scr.window);

    if (buttons(1) && ~prevButtons(1)) || KbCheckForKey(spaceKey)
        RT = GetSecs - start_time;
        confirmed = true;
    end

    prevButtons = buttons;
end

HideCursor;
end

function pressed = KbCheckForKey(key)
[keyIsDown, ~, keyCode] = KbCheck(-1);
pressed = keyIsDown && keyCode(key);
end

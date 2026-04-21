function [conf, RT] = collect_confidence_rating(scr, visual, decision)
% Modified from example_duald/functions/collect_confidence_rating.m

center = [scr.xCenter, scr.yCenter];
keys = [KbName('LeftArrow') KbName('RightArrow') KbName('Space')];

VASwidth = round(8 * visual.ppd);
VASoffset = 0;
arrowwidth = round(1 * visual.ppd);
arrowheight = arrowwidth;
l = VASwidth / 2;
deadline = 0;
vas_points = 7;

start_time = GetSecs;
max_x = center(1) + l;
min_x = center(1) - l;
steps_x = linspace(-l, l, vas_points);
range_x = max_x - min_x;
index = ceil(rand * vas_points);
xpos = center(1) + steps_x(index);

while (GetSecs - start_time) < 10
    WaitSecs(.07);
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown
        direction = find(keyCode(keys), 1);
        if isempty(direction)
            continue;
        elseif direction == 1
            xpos = xpos - (range_x / (length(steps_x) - 1));
        elseif direction == 2
            xpos = xpos + (range_x / (length(steps_x) - 1));
        elseif direction == 3
            deadline = 1;
            RT = GetSecs - start_time;
            break;
        end

        xpos = min(max(xpos, min_x), max_x);
    end

    Screen('DrawLine', scr.window, [255 255 255], center(1) - VASwidth / 2, center(2) + VASoffset, center(1) + VASwidth / 2, center(2) + VASoffset);
    Screen('DrawLine', scr.window, [255 255 255], center(1) - VASwidth / 2, center(2) + VASoffset + 20, center(1) - VASwidth / 2, center(2) + VASoffset);
    Screen('DrawLine', scr.window, [255 255 255], center(1) + VASwidth / 2, center(2) + VASoffset + 20, center(1) + VASwidth / 2, center(2) + VASoffset);

    if decision == 1
        Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
        drawCenteredText(scr.window, '1', scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
    else
        Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
        drawCenteredText(scr.window, '2', scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
    end

    tickMark = center(1) + linspace(-VASwidth / 2, VASwidth / 2, vas_points);
    Screen('TextSize', scr.window, 24);
    tickLabels = {'1', '2', '3', '4', '5', '6', '7'};
    for tick = 1:length(tickLabels)
        Screen('DrawLine', scr.window, [255 255 255], tickMark(tick), center(2) + VASoffset + 10, tickMark(tick), center(2) + VASoffset);
        DrawFormattedText(scr.window, tickLabels{tick}, tickMark(tick) - 10, center(2) + VASoffset - 30, [255 255 255]);
    end
    DrawFormattedText(scr.window, 'Confidence?', 'center', center(2) + VASoffset + 75, [255 255 255]);

    arrowPoints = [([-0.5 0 0.5]' .* arrowwidth) + xpos ([1 0 1]' .* arrowheight) + center(2) + VASoffset];
    Screen('FillPoly', scr.window, [255 255 255], arrowPoints);
    Screen('Flip', scr.window);
end

if deadline == 0
    conf = NaN;
    RT = NaN;
    DrawFormattedText(scr.window, 'Too late!', 'center', center(2) + VASoffset + 75, [255 255 255]);
    if decision == 1
        Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
        drawCenteredText(scr.window, '1', scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
    else
        Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
        drawCenteredText(scr.window, '2', scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
    end
    Screen('Flip', scr.window);
    WaitSecs(0.1);
else
    conf = ((xpos - (center(1) - l)) / range_x);

    Screen('DrawLine', scr.window, [255 255 255], center(1) - VASwidth / 2, center(2) + VASoffset, center(1) + VASwidth / 2, center(2) + VASoffset);
    Screen('DrawLine', scr.window, [255 255 255], center(1) - VASwidth / 2, center(2) + VASoffset + 20, center(1) - VASwidth / 2, center(2) + VASoffset);
    Screen('DrawLine', scr.window, [255 255 255], center(1) + VASwidth / 2, center(2) + VASoffset + 20, center(1) + VASwidth / 2, center(2) + VASoffset);

    tickMark = center(1) + linspace(-VASwidth / 2, VASwidth / 2, vas_points);
    Screen('TextSize', scr.window, 24);
    tickLabels = {'1', '2', '3', '4', '5', '6', '7'};
    for tick = 1:length(tickLabels)
        Screen('DrawLine', scr.window, [255 255 255], tickMark(tick), center(2) + VASoffset + 10, tickMark(tick), center(2) + VASoffset);
        DrawFormattedText(scr.window, tickLabels{tick}, tickMark(tick) - 10, center(2) + VASoffset - 30, [255 255 255]);
    end
    DrawFormattedText(scr.window, 'Confidence?', 'center', center(2) + VASoffset + 75, [255 255 255]);

    if decision == 1
        Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
        drawCenteredText(scr.window, '1', scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
    else
        Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_2, [], 2);
        drawCenteredText(scr.window, '2', scr.xCenter, visual.dots_xy(2, 1), visual.black, visual.textSize);
    end

    arrowPoints = [([-0.5 0 0.5]' .* arrowwidth) + xpos ([1 0 1]' .* arrowheight) + center(2) + VASoffset];
    Screen('FillPoly', scr.window, [255 0 0], arrowPoints);
    Screen('Flip', scr.window);

    while KbCheck(-1)
    end
    FlushEvents('KeyDown');
    WaitSecs(0.1);
end
end

function drawnXY = drawDots(scr, visual, n, XY)
% Subfunction for perceptual metacognition task
%
% SF 2012
% modified ML 2024

for side = 1:2
    if nargin > 3
        xy = XY{side};
        drawnXY{side} = xy;
    else
        xy = dotcloud(n(side), visual.stim_dotsize, 100);
        xy = xy * visual.inner_circle;
        xy = xy / 2 * eye(2);
        drawnXY{side} = xy;
    end
    z = visual.stim_dotsize * visual.inner_circle;

    for i = 1:n(side)
        wh = xy(i, [1 2 1 2]) + [-z/2 -z/2 z/2 z/2] + ...
            [visual.stim_centers(side, :) visual.stim_centers(side, :)];
        Screen('FillOval', scr.window, visual.stim_dotcolor, wh);
    end
end
end

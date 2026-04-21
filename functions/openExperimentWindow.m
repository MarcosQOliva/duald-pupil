function [scr, visual, keys] = openExperimentWindow(settings)
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', settings.display.skipSyncTests);

screenNumber = max(Screen('Screens'));

visual.white = 255;
visual.grey = floor(255 / 2);
visual.black = 0;
visual.bgColor = visual.grey;
visual.fixColor = 170 / 255;

[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey / 255, [], 32, 2);
%[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey / 255, [0 0 1920/2 1080/2], 32, 2);
Screen('Flip', scr.window);

scr.ifi = Screen('GetFlipInterval', scr.window);
Screen('TextSize', scr.window, 60);
scr.topPriorityLevel = MaxPriority(scr.window);
Priority(scr.topPriorityLevel);

[scr.xCenter, scr.yCenter] = RectCenter(scr.windowRect);
[scr.xres, scr.yres] = Screen('WindowSize', scr.window);
Screen('BlendFunction', scr.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

scr.subDist = settings.display.subDistCm;
scr.width = settings.display.monitorWidthMm;

ppd = va2pix(1, scr);
visual.ppd = ppd;
visual.textSize = round(0.5 * ppd);
visual.fix_size = 0.1 * ppd;
visual.stim_size = 4 * ppd;
visual.stim_ecc = 4 * ppd;
visual.stim_rects = [ ...
    CenterRectOnPoint([0, 0, visual.stim_size, visual.stim_size], scr.xCenter - visual.stim_ecc, scr.yCenter)', ...
    CenterRectOnPoint([0, 0, visual.stim_size, visual.stim_size], scr.xCenter + visual.stim_ecc, scr.yCenter)'];
visual.stim_dur = settings.task.stim_dur;
visual.dots_dy = (visual.stim_size / 2) * 1.5;
visual.dots_xy = [scr.xCenter - visual.stim_ecc, scr.xCenter + visual.stim_ecc; ...
    scr.yCenter - visual.dots_dy, scr.yCenter - visual.dots_dy];

% these were initial values
% visual.dots_col_1 = (visual.white / 255) / 3;
% visual.dots_col_2 = ([246, 14, 0; 0, 160, 0]' / 255);

% replaced with thes equiluminant 25cs/m2
visual.dots_col_1 = 109 / 255;
visual.dots_col_2 = ([222, 0, 0; 0, 126, 0]' / 255);

visual.dots_size = 34;
visual.stim_pen_width = 1;
visual.inner_circle = round(visual.stim_size * 0.95);
visual.stim_dotsize = 0.08;
visual.stim_dotcolor = [visual.black, visual.black, visual.black, 0.65];
visual.stim_centers = [scr.xCenter - visual.stim_ecc, scr.yCenter; ...
    scr.xCenter + visual.stim_ecc, scr.yCenter];
visual.ndots_ref = settings.task.ndots_ref;

KbName('UnifyKeyNames');
keys.escapeKey = KbName('ESCAPE');
keys.leftKey = KbName('LeftArrow');
keys.rightKey = KbName('RightArrow');
end
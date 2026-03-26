function eyetracker = calibrateTobiiHook(scr, eyetracker)
%CALIBRATETOBIIHOOK Minimal ScreenBasedCalibration flow adapted from example_pupil.

spaceKey = KbName('Space');
RKey = KbName('R');
screen_pixels = [scr.xres, scr.yres];
dotSizePix = 30;
dotColor = [[1 0 0]; [1 1 1]] * 255;
leftColor = [1 0 0] * 255;
rightColor = [0 0 1] * 255;

shrink_factor = 0.15;
lb = 0.1 + shrink_factor;
xc = 0.5;
rb = 0.9 - shrink_factor;
ub = 0.1 + shrink_factor;
yc = 0.5;
bb = 0.9 - shrink_factor;

points_to_calibrate = [[lb, ub]; [rb, ub]; [xc, yc]; [lb, bb]; [rb, bb]; [xc, bb]; [xc, ub]; [lb, yc]; [rb, yc]];
points_to_calibrate = points_to_calibrate(randperm(size(points_to_calibrate, 1)), :);

calib = ScreenBasedCalibration(eyetracker);

Screen('FillOval', scr.window, dotColor(1, :), CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 2, 0.5 * screen_pixels(1), 0.5 * screen_pixels(2)));
Screen('FillOval', scr.window, dotColor(2, :), CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 0.3, 0.5 * screen_pixels(1), 0.5 * screen_pixels(2)));
DrawFormattedText(scr.window, ...
    ['Focus on the white dot inside the red disk.\n' ...
     'Press any key to begin calibration.'], ...
    'center', scr.yres * 0.65, 255);
Screen('Flip', scr.window);
KbStrokeWait;

calibrating = true;
while calibrating
    calib.enter_calibration_mode();

    for i = 1:size(points_to_calibrate, 1)
        Screen('FillOval', scr.window, dotColor(1, :), ...
            CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 2, ...
            points_to_calibrate(i, 1) * screen_pixels(1), ...
            points_to_calibrate(i, 2) * screen_pixels(2)));
        Screen('FillOval', scr.window, dotColor(2, :), ...
            CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 0.3, ...
            points_to_calibrate(i, 1) * screen_pixels(1), ...
            points_to_calibrate(i, 2) * screen_pixels(2)));
        Screen('Flip', scr.window);
        pause(1);

        if calib.collect_data(points_to_calibrate(i, :)) ~= CalibrationStatus.Success
            calib.collect_data(points_to_calibrate(i, :));
        end
    end

    DrawFormattedText(scr.window, 'Calculating calibration result....', 'center', 'center', 255);
    Screen('Flip', scr.window);

    calibration_result = calib.compute_and_apply();
    calib.leave_calibration_mode();

    if calibration_result.Status ~= CalibrationStatus.Success
        break;
    end

    points = calibration_result.CalibrationPoints;
    for i = 1:length(points)
        Screen('FillOval', scr.window, dotColor(2, :), ...
            CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 0.5, ...
            points(i).PositionOnDisplayArea(1) * screen_pixels(1), ...
            points(i).PositionOnDisplayArea(2) * screen_pixels(2)));

        for j = 1:length(points(i).RightEye)
            if points(i).LeftEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                Screen('FillOval', scr.window, leftColor, ...
                    CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 0.2, ...
                    points(i).LeftEye(j).PositionOnDisplayArea(1) * screen_pixels(1), ...
                    points(i).LeftEye(j).PositionOnDisplayArea(2) * screen_pixels(2)));
                Screen('DrawLines', scr.window, ...
                    ([points(i).LeftEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea] .* repmat(screen_pixels, 2, 1))', ...
                    2, leftColor, [0, 0], 2);
            end
            if points(i).RightEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                Screen('FillOval', scr.window, rightColor, ...
                    CenterRectOnPoint([0, 0, dotSizePix, dotSizePix] * 0.2, ...
                    points(i).RightEye(j).PositionOnDisplayArea(1) * screen_pixels(1), ...
                    points(i).RightEye(j).PositionOnDisplayArea(2) * screen_pixels(2)));
                Screen('DrawLines', scr.window, ...
                    ([points(i).RightEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea] .* repmat(screen_pixels, 2, 1))', ...
                    2, rightColor, [0, 0], 2);
            end
        end
    end

    DrawFormattedText(scr.window, 'Press R to recalibrate or SPACE to continue.', 'center', scr.yres * 0.95, 255);
    Screen('Flip', scr.window);

    while true
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown
            if keyCode(spaceKey)
                calibrating = false;
                break;
            elseif keyCode(RKey)
                break;
            end
            KbReleaseWait;
        end
    end
end
end

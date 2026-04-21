function eyetracker = calibrateTobiiHook(scr, eyetracker, visual)
%CALIBRATETOBIIHOOK Minimal ScreenBasedCalibration flow adapted from example_pupil.

spaceKey = KbName('Space');
RKey = KbName('R');
screen_pixels = [scr.xres, scr.yres];
dotSizePix = 30;
dotColor = [[1 0 0]; [1 1 1]] * 255;
leftColor = [1 0 0] * 255;
rightColor = [0 0 1] * 255;

eyetracker.get_gaze_data();

% %% first check that participats is laced in the correct position 
% 
% % Start collecting data
% % The subsequent calls return the current values in the stream buffer.
% % If a flat structure is prefered just use an extra input 'flat'.
% % i.e. gaze_data = eyetracker.get_gaze_data('flat');
% eyetracker.get_gaze_data();
% 
% Screen('TextSize', scr.window, 20);
% 
% while ~KbCheck
% 
%     DrawFormattedText(scr.window, 'When correctly positioned press any key to start the calibration.', 'center', scr.yres * 0.1, visual.white);
% 
%     distance = [];
% 
%     gaze_data = eyetracker.get_gaze_data();
% 
%     if ~isempty(gaze_data)
%         last_gaze = gaze_data(end);
% 
%         validityColor = [1 0 0]*255;
% 
%         % Check if user has both eyes inside a reasonable tacking area.
%         if last_gaze.LeftEye.GazeOrigin.Validity.('value') && last_gaze.RightEye.GazeOrigin.Validity.('value')
%             % left_validity = all(last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(1:2) < 0.85) ...
%             %                      && all(last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(1:2) > 0.15);
%             % right_validity = all(last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(1:2) < 0.85) ...
%             %                      && all(last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(1:2) > 0.15);
%             left_validity = 1;
%             right_validity = 1;
%             if left_validity && right_validity
%                 validityColor = [0 1 0]*255;
%             end
%         end
% 
%         origin = [scr.xres/4 scr.yres/4];
%         size = [scr.xres/2 scr.yres/2];
% 
%         penWidthPixels = 3;
%         baseRect = [0 0 size(1) size(2)];
%         frame = CenterRectOnPointd(baseRect, scr.xres/2, scr.yCenter);
% 
%         Screen('FrameRect', scr.window, validityColor, frame, penWidthPixels);
% 
%         % Left Eye
%         if last_gaze.LeftEye.GazeOrigin.Validity.('value')
%             distance = [distance; round(last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(3)/10,1)];
%             left_eye_pos_x = double(1-last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(1))*size(1) + origin(1);
%             left_eye_pos_y = double(last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(2))*size(2) + origin(2);
%             %Screen('DrawDots', scr.window, [left_eye_pos_x left_eye_pos_y], dotSizePix, validityColor, [], 1);
%             Screen('FillOval', scr.window, validityColor, CenterRectOnPoint([0,0, dotSizePix, dotSizePix], left_eye_pos_x, left_eye_pos_y));
%         end
% 
%         % Right Eye
%         if last_gaze.RightEye.GazeOrigin.Validity.('value')
%             distance = [distance;round(last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(3)/10,1)];
%             right_eye_pos_x = double(1-last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(1))*size(1) + origin(1);
%             right_eye_pos_y = double(last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(2))*size(2) + origin(2);
%             %Screen('DrawDots', scr.window, [right_eye_pos_x right_eye_pos_y], dotSizePix, validityColor, [], 1);
%             Screen('FillOval', scr.window, validityColor, CenterRectOnPoint([0,0, dotSizePix, dotSizePix], right_eye_pos_x, right_eye_pos_y));
%         end
%         pause(0.05);
%     end
% 
%     % debug
%     % last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem % all NaN
% 
% 
%     DrawFormattedText(scr.window, sprintf('Current distance to the eye tracker: %.2f cm.',mean(distance)), 'center', scr.yres * 0.85, visual.white);
% 
% 
%     % Flip to the screen. This command basically draws all of our previous
%     % commands onto the screen.
%     % For help see: Screen Flip?
%     Screen('Flip', scr.window);
% 
% end
% 
% eyetracker.stop_gaze_data();



% actual calibration
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

    % debug
    % calibration_result.Status

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

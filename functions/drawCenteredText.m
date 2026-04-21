function drawCenteredText(window, textString, xCenter, yCenter, textColor, textSize)
if nargin < 5
    textColor = [255 255 255];
end

Screen('TextSize', window, textSize);
textBounds = Screen('TextBounds', window, textString);
xPosition = xCenter - textBounds(3) / 2;
yPosition = yCenter - textBounds(4) / 2;
Screen('DrawText', window, textString, xPosition, yPosition, textColor);
end

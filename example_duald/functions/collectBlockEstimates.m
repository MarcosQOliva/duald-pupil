function [value1, value2] = collectBlockEstimates(scr, visual, headerText)
%COLLECTBLOCKESTIMATES Ask for block accuracy estimates for decisions 1 and 2.
%   [value1, value2] = collectBlockEstimates(scr, visual, headerText)
%   displays a grey screen with two entry lines (1: and 2:) and returns the
%   numbers typed for each, confirmed with Enter. Backspace edits the
%   current line. Digits are shown as typed.

buffers = {'',''};
values = [NaN, NaN];
idx = 1;

% readable text size
textSz = max(round(visual.textSize), 32);

while idx <= 2
    % draw prompt with both lines visible
    Screen('FillRect', scr.window, visual.grey/255);
    Screen('TextSize', scr.window, textSz);
    DrawFormattedText(scr.window, headerText, 'center', scr.yCenter - 140, visual.black);
    
    % show current buffers so participants see what they typed
    lineText = sprintf('1st: %s\n\n2nd: %s', buffers{1}, buffers{2});
    DrawFormattedText(scr.window, lineText, 'center', scr.yCenter - 20, visual.black);
    
    DrawFormattedText(scr.window, sprintf('Now typing for %d (digits, backspace, ENTER).', idx), 'center', scr.yCenter + 140, visual.black);
    Screen('Flip', scr.window);
    
    % wait for key press
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if ~keyIsDown
        continue;
    end
    
    keyName = KbName(keyCode);
    if iscell(keyName)
        keyName = keyName{1};
    end
    
    if strcmpi(keyName, 'Return')
        if isempty(buffers{idx})
            values(idx) = 0;
            idx = idx + 1;
        else
            tmp = str2double(buffers{idx});
            if ~isnan(tmp)
                values(idx) = tmp;
                idx = idx + 1;
            else
                buffers{idx} = '';
            end
        end
    elseif strcmpi(keyName, 'BackSpace')
        if ~isempty(buffers{idx})
            buffers{idx}(end) = [];
        end
    elseif ischar(keyName) && ~isempty(keyName) && isstrprop(keyName(1), 'digit')
        buffers{idx} = [buffers{idx}, keyName(1)]; %#ok<AGROW>
    end
    
    KbReleaseWait;
end

value1 = values(1);
value2 = values(2);
end

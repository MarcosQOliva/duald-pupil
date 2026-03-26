function th_updated = updateStructureUniqueIndices(th, contrast_lvls)

    % Function to calculate mean squared distance with penalty for constraints
    function dist = penalizedMeanSquaredDistance(indices)
        % Ensure indices are integers
        roundedIndices = round(indices);

        % Compute the mean squared distance
        dist = sum((contrast_lvls(roundedIndices) - th.multi).^2);

        % Add penalty if constraints are violated
        penalty = 0;
        for i = 1:length(roundedIndices)-1
            if roundedIndices(i) >= roundedIndices(i+1)
                penalty = penalty + 1e6; % Large penalty
            end
        end
        dist = dist + penalty;
    end

    % Initialize the structure
    th_updated = th;

    % Find the closest value and index for th.single
    [~, singleIndex] = min(abs(contrast_lvls - th.single));
    th_updated.single_real = contrast_lvls(singleIndex);
    th_updated.single_index = singleIndex;

    % Find initial indices for th.multi
    initialIndices = arrayfun(@(x) find(min(abs(contrast_lvls - x)) == abs(contrast_lvls - x), 1), th.multi);

    % Optimization to find unique indices with minimum mean squared distance
    options = optimset('Display', 'none');
    uniqueIndices = fminsearch(@penalizedMeanSquaredDistance, initialIndices, options);

    % Update the structure with unique indices and corresponding values
    th_updated.multi_index = round(uniqueIndices); % Round indices to nearest integer
    th_updated.multi_real = contrast_lvls(th_updated.multi_index);
end
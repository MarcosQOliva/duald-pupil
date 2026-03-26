function R = R_from_alpha(alpha, sigma)
% R_FROM_ALPHA  Range R for uniform difficulty that yields accuracy alpha
%
%   R = R_from_alpha(alpha, sigma)
%
%   Solves alpha_from_R(R, sigma) = alpha using fzero.

    if nargin < 2
        sigma = 1;
    end

    % Function whose root we want: alpha_from_R(R) - alpha = 0
    fun = @(R) alpha_from_R(R, sigma) - alpha;

    % Bracket for the root; adjust if needed
    R_min = 1e-6;
    R_max = 20 * sigma;

    % Use fzero with an interval; assumes monotonicity in [R_min, R_max]
    R = fzero(fun, [R_min, R_max]);
end

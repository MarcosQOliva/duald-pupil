function F = F_from_alpha(alpha, sigma)
% F_FROM_ALPHA  Fixed difficulty F for a given accuracy alpha and noise sigma
%
%   F = F_from_alpha(alpha, sigma)
%
%   Implements: F = sigma * qnorm(alpha)
%
%   alpha : target accuracy (0 < alpha < 1)
%   sigma : noise parameter

    if nargin < 2
        sigma = 1;
    end

    F = sigma .* norminv(alpha);  % norminv is the Gaussian quantile in MATLAB
end

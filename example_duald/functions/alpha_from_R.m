function a = alpha_from_R(R, sigma)
% ALPHA_FROM_R  Expected accuracy for uniform difficulty in [0, R]
%
%   a = alpha_from_R(R, sigma)
%
%   Implements: alpha = Phi(u) + (phi(u) - phi(0)) ./ u
%   where u = R / sigma

    if nargin < 2
        sigma = 1;
    end

    u = R ./ sigma;

    % Standard normal CDF and PDF
    Phi_u  = normcdf(u);
    phi_u  = normpdf(u);
    phi_0  = normpdf(0);

    a = Phi_u + (phi_u - phi_0) ./ u;
end

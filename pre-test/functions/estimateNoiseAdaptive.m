function details = estimateNoiseAdaptive(logratio, response, prior)
%ESTIMATENOISEADAPTIVE MAP and posterior summary for sigma.
%
% Fits the zero-bias, zero-lapse psychometric function:
%   P(right) = Phi(logratio / sigma)
%
% The prior matches misc/computeNoise.m:
%   sigma ~ LogNormal(mu_log, sigma_log)

if nargin < 3 || isempty(prior)
    prior.mu_log = -1.519961;
    prior.sigma_log = 0.2855135;
end

logratio = double(logratio(:));
response = double(response(:));

valid = isfinite(logratio) & isfinite(response);
logratio = logratio(valid);
response = response(valid);

if isempty(logratio)
    error('estimateNoiseAdaptive requires at least one valid trial.');
end

neglogpost = @(log_sigma) computeNegLogPosterior(log_sigma, logratio, response, prior.mu_log, prior.sigma_log);

options = optimset('Display', 'off');
[log_sigma_hat, fval, exitflag] = fminsearch(neglogpost, prior.mu_log, options);

grid = linspace(log_sigma_hat - 5, log_sigma_hat + 5, 2000);
logpost = -arrayfun(@(ls) computeNegLogPosterior(ls, logratio, response, prior.mu_log, prior.sigma_log), grid);
logpost_max = max(logpost);
weights = exp(logpost - logpost_max);
weights = weights / sum(weights);

sigma_vals = exp(grid);
sigma_mean = sum(sigma_vals .* weights);
sigma_var = sum(((sigma_vals - sigma_mean) .^ 2) .* weights);

details = struct();
details.log_sigma_hat = log_sigma_hat;
details.sigma_map = exp(log_sigma_hat);
details.sigma_mean = sigma_mean;
details.sigma_sd = sqrt(max(sigma_var, 0));
details.logposterior = -fval;
details.exitflag = exitflag;
details.grid = grid;
details.posterior_weights = weights;
details.n_trials = numel(logratio);
end

function nlp = computeNegLogPosterior(log_sigma, x, r, mu_log, sigma_log)
sigma = exp(log_sigma);
z = x ./ max(sigma, realmin);
p = normcdf(z);
eps_val = realmin;
loglik = sum(r .* log(p + eps_val) + (1 - r) .* log(1 - p + eps_val));
logprior = -((log_sigma - mu_log) .^ 2) ./ (2 * sigma_log ^ 2) ...
    - log(sigma * sigma_log * sqrt(2 * pi));
nlp = -(loglik + logprior);
end

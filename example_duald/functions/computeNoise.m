function [sigma_map, details] = computeNoise(dataFile)
%COMPUTENOISE Estimate noise (sigma) from decision==1 trials via MAP.
%   [sigma_map, details] = computeNoise(dataFile)
%   Loads a task output file (tab-delimited), extracts decision==1 trials,
%   computes log-ratios from n_right/n_left, and fits sigma in
%   P(resp==1) = Phi(logratio / sigma) with a lognormal prior on sigma.
%
%   Prior: sigma ~ LogNormal(mu_log=-2.834, sigma_log=1.646).
%
%   Returns the MAP estimate sigma_map and a details struct with fields:
%     logratio, response, logposterior, exitflag, fval.

mu_log = -1.519961;
sigma_log = 0.2855135;

if nargin < 1
    error('Usage: [sigma_map, details] = computeNoise(dataFile)');
end

if ~isfile(dataFile)
    error('Data file not found: %s', dataFile);
end

opts = detectImportOptions(dataFile, 'Delimiter', '\t', 'FileType', 'text');
T = readtable(dataFile, opts);

requiredVars = {'decision','n_left','n_right','response'};
missing = setdiff(requiredVars, T.Properties.VariableNames);
if ~isempty(missing)
    error('Missing required columns in data: %s', strjoin(missing, ', '));
end

% keep only decision 1 trials
mask = T.decision == 1;
logratio = log(double(T.n_right(mask)) ./ double(T.n_left(mask)));
resp = double(T.response(mask));

if isempty(logratio)
    error('No decision==1 trials found in data.');
end

% negative log-posterior in terms of log_sigma
neglogpost = @(log_sigma) computeNegLogPosterior(log_sigma, logratio, resp, mu_log, sigma_log);

% initialize log_sigma around prior mean
init_log_sigma = mu_log;
options = optimset('Display','off');
[log_sigma_hat, fval, exitflag] = fminsearch(neglogpost, init_log_sigma, options);

sigma_map = exp(log_sigma_hat);

details.logratio = logratio;
details.response = resp;
details.logposterior = -fval;
details.exitflag = exitflag;
details.log_sigma_hat = log_sigma_hat;

% after finding log_sigma_hat, fval, exitflag

grid = linspace(log_sigma_hat - 5, log_sigma_hat + 5, 1000);
logpost = -arrayfun(@(ls) computeNegLogPosterior(ls, logratio, resp, mu_log, sigma_log), grid);
logpost_max = max(logpost);
w = exp(logpost - logpost_max);

sigma_vals = exp(grid);
sigma_mean = sum(sigma_vals .* w) / sum(w);

sigma_map  = exp(log_sigma_hat);
details.sigma_mean = sigma_mean;

end


function nlp = computeNegLogPosterior(log_sigma, x, r, mu_log, sigma_log)
sigma = exp(log_sigma);
z = x ./ max(sigma, realmin);
p = normcdf(z);
eps_val = realmin;
loglik = sum(r .* log(p + eps_val) + (1 - r) .* log(1 - p + eps_val));
logprior = -((log_sigma - mu_log).^2) ./ (2 * sigma_log^2) - log(sigma * sigma_log * sqrt(2*pi));
nlp = -(loglik + logprior);
end

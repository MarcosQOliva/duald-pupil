function sweetpoint = computeSweetpointZeroLapse(sigma, minLogratio, maxLogratio)
%COMPUTESWEETPOINTZEROLAPSE Sweet-point for sigma with zero lapse.
%
% Uses the same expected-variance objective as misc/Evar_sigma.m but solves
% the one-dimensional zero-lapse case directly with fminbnd.

if nargin < 2 || isempty(minLogratio)
    minLogratio = log(51 / 49);
end
if nargin < 3 || isempty(maxLogratio)
    maxLogratio = log(95 / 5);
end

sigma = max(double(sigma), realmin);
minLogratio = max(double(minLogratio), sqrt(eps));
maxLogratio = max(double(maxLogratio), minLogratio);

searchUpper = min(maxLogratio, max(minLogratio * 2, sigma * 4));
objective = @(x) Evar_sigma(x, 0, sigma, 0);

if searchUpper <= minLogratio
    sweetpoint = minLogratio;
    return;
end

sweetpoint = fminbnd(objective, minLogratio, searchUpper);
sweetpoint = min(max(sweetpoint, minLogratio), maxLogratio);
end

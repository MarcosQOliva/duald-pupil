function logRatios = sampleRangeDifficulty(rangeLogratio, minLogratio, nSamples)
%SAMPLERANGEDIFFICULTY Sample independent R-condition log-ratios.

if nargin < 3
    nSamples = 2;
end

logRatios = minLogratio + rand(1, nSamples) * (rangeLogratio - minLogratio);
end

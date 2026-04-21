function n = buildRangePairFromLogRatio(logratio, ndots_ref, side)
%BUILDRANGEPAIRFROMLOGRATIO Convert log-ratio to the old 100-dot split.

totalDots = ndots_ref * 2;
n_diff = round(totalDots * tanh(logratio / 2));

if side == 2
    n = [ndots_ref - round(n_diff / 2), ...
        ndots_ref - round(n_diff / 2) + n_diff];
else
    n = [ndots_ref - round(n_diff / 2) + n_diff, ...
        ndots_ref - round(n_diff / 2)];
end
end

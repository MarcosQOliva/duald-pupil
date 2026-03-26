function [N] = calculate_numbers(mu, LR)
    % Calculate the exponent of the log-ratio
    expLR = exp(LR);
    
    % Use the conditions to solve for N1 and N2
    % (N1 + N2)/2 = mu  =>  N1 + N2 = 2*mu
    % log(N1/N2) = LR   =>  N1/N2 = exp(LR)
    
    % Let N2 = x, then N1 = exp(LR) * x
    % So, exp(LR) * x + x = 2 * mu
    % x * (exp(LR) + 1) = 2 * mu
    % x = 2 * mu / (exp(LR) + 1)
    
    N2 = 2 * mu / (expLR + 1);
    N1 = expLR * N2;
    
    N = round([N1, N2]);
end
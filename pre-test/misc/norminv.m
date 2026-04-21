function x = norminv(p, mu, sigma)
    % NORMINV Inverse of the normal cumulative distribution function
    % X = NORMINV(P) returns the inverse CDF of the standard normal
    % distribution at the values in P.
    %
    % X = NORMINV(P, MU, SIGMA) returns the inverse CDF for a normal
    % distribution with mean MU and standard deviation SIGMA.
    
    if nargin < 2
        mu = 0;
    end
    if nargin < 3
        sigma = 1;
    end
    
    % Check for valid probabilities
    if any(p(:) < 0) || any(p(:) > 1)
        error('P must be between 0 and 1');
    end
    
    % Use the inverse error function to compute the inverse CDF
    % If CDF = 0.5 * (1 + erf(z/sqrt(2))), then
    % z = sqrt(2) * erfinv(2*p - 1)
    z = sqrt(2) * erfinv(2*p - 1);
    
    % Transform from standard normal to specified mean and std
    x = mu + sigma * z;
end
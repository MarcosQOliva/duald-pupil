function p = normcdf(x, mu, sigma)
    % NORMCDF Normal cumulative distribution function
    % P = NORMCDF(X) returns the cumulative distribution function of the
    % standard normal distribution at the values in X.
    %
    % P = NORMCDF(X, MU, SIGMA) returns the CDF for a normal distribution
    % with mean MU and standard deviation SIGMA.
    
    if nargin < 2
        mu = 0;
    end
    if nargin < 3
        sigma = 1;
    end
    
    % Standardize
    z = (x - mu) ./ sigma;
    
    % Use the error function to compute the CDF
    % CDF = 0.5 * (1 + erf(z/sqrt(2)))
    p = 0.5 * (1 + erf(z / sqrt(2)));
end
function y = normpdf(x, mu, sigma)
    % NORMPDF Normal probability density function
    % Y = NORMPDF(X) returns the probability density function of the
    % standard normal distribution at the values in X.
    %
    % Y = NORMPDF(X, MU, SIGMA) returns the PDF for a normal distribution
    % with mean MU and standard deviation SIGMA.
    
    if nargin < 2
        mu = 0;
    end
    if nargin < 3
        sigma = 1;
    end
    
    % Standardize
    z = (x - mu) ./ sigma;
    
    % Compute PDF: (1/(sigma*sqrt(2*pi))) * exp(-0.5*z^2)
    y = (1 ./ (sigma * sqrt(2*pi))) .* exp(-0.5 * z.^2);
end
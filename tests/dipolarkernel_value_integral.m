function [err,data,maxerr] = test(opt,olddata)

% Test whether kernel matrix element (calculated using grid average)
% is correct.

% Generate kernel numerically
t = 1; % us
r = 1; % nm
K = dipolarkernel(t,r,'Method','integral');

% Kernel value for 1us and 1nm computed using Mathematica (FresnelC and
% FresnelS) and CODATA 2018 values for ge, muB, mu0, and h.
Kref = 0.024697819895260188;

% Compare
err = abs(K-Kref)>1e-6;
maxerr = err;
data = [];

end

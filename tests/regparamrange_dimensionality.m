function [err,data,maxerr] = test(opt,olddata)

t = linspace(0,5,80);
r = time2dist(t);

K = dipolarkernel(t,r);
L = regoperator(r,2);

alphas = regparamrange(K,sparse(L));

err = ~iscolumn(alphas);
maxerr = NaN;
data = [];

end
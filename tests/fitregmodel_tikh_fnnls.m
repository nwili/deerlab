function [pass,maxerr] = test(opt)

% Test Tikhonov regularization with the fnnls solver (free)

rng(1)
t = linspace(0,3,200);
r = linspace(2,4,200);
P = rd_onegaussian(r,[3,0.5]);
K = dipolarkernel(t,r);
S = K*P + whitegaussnoise(t,0.01);
alpha = 0.2615;

Pfit = fitregmodel(S,K,r,'tikhonov',alpha,'Solver','fnnls');

%Pass : fnnls manages to fit the distribution
pass = all(abs(Pfit - P) < 3e-1);

maxerr = max(abs(Pfit - P));

if opt.Display
   plot(r,P,'k',r,Pfit)
   legend('truth','fit')
   xlabel('r [nm]')
   ylabel('P(r) [nm^{-1}]')
   grid on, axis tight, box on
end

end
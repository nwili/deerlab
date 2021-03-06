function [pass,maxerr] = test(opt)

% Check that longpass() works with negative times
t = linspace(-3,0,200);
r = linspace(0,8,200);
P = rd_twogaussian(r,[1.5,0.3,4.5,0.3,0.5]);
Ptrue = rd_onegaussian(r,[4.5,0.3]);
K = dipolarkernel(t,r);
S = K*P;
Sfilt = longpass(t,S,2);
Pfilt = fitregmodel(Sfilt,K,r,'tikhonov','aic','Solver','fnnls');
Praw = fitregmodel(S,K,r,'tikhonov','aic','Solver','fnnls');

error = abs(Pfilt - Ptrue);
%Pass: the short-component is properly suppressed
pass = all(error < 5e-1);

maxerr = max(error);

if opt.Display
    
    subplot(131)
    plot(t,S,t,Sfilt)
    legend('raw','filtered')
    xlabel('t [\mus]')
    ylabel('V(t)')
    grid on, axis tight, box on
    
    subplot(132)
    plot(r,Ptrue,r,Praw,r,Pfilt)
    legend('truth','raw','filtered')
    xlabel('r [nm]')
    ylabel('P(r) [nm^{-1}]')
    grid on, axis tight, box on

    subplot(133)
    [nu,specraw] = fftspec(t(t>=0),S(t>=0));
    specfilt = fftspec(t(t>=0),Sfilt(t>=0));
    plot(nu,specraw,nu,specfilt)
    legend('raw','filtered')
    xlabel('\nu [MHz]')
    ylabel('V(t)')
    grid on, axis tight, box on
    
end

end
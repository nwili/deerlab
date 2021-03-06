function [pass,maxerr] = test(opt)

% Check that overtones are accurately generated

r = 4; % nm
t = linspace(-1,4,401); % us
Tmix = 50; % us
T1 = 88; % us
c = overtones(5,Tmix,T1);
K = dipolarkernel(t,r,'OvertoneCoeffs',c);

Kref = 0;
for n = 1:numel(c)
  Kref = Kref + c(n)*dipolarkernel(n*t,r);
end

error = abs(K - Kref);

% Pass 1: kernel returned by function equal to reference
pass = all(error < 1e-13);
maxerr = max(error);

end
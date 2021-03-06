function [pass,maxerr] = test(opt)

% Check that fitbackground() works with different solvers

t = linspace(0,10,100);
lam0 = 0.25;
k = 0.05;
V = dipolarsignal(t,3,'Background',td_exp(t,k),'moddepth',lam0);
tstart = 4.2424;
tend = 10.0000;

B1 = fitbackground(V,t,@td_exp,[tstart tend],'Solver','lsqnonlin');
B2 = fitbackground(V,t,@td_exp,[tstart tend],'Solver','fminsearchcon');
if ispc
B3 = fitbackground(V,t,@td_exp,[tstart tend],'Solver','nlsqbnd');
end

% Pass 1: lsqnonlin and fminsearchcon give same background fit
pass(1) = all(abs(B1 - B2) < 1e-6);

if ispc
% Pass 2: nlsqbnd and fminsearchcon give same background fit
pass(2) = all(abs(B3 - B2) < 1e-6);
end

pass = all(pass);
maxerr = max(abs(B1 - B2));
 

if opt.Display
  plot(t,B1,t,B2,t,B3)
  legend('lsqnonlin','fminsearchcon','nlsqbnd')
  legend('truth','fit')
  xlabel('t [\mus]')
  ylabel('B(t)')
end

end
%
% FITBACKGROUND Fit the background function in a signal
%
%   [B,lambda,param,tstart] = FITBACKGROUND(V,t,@model)
%   Fits the background (B) and the modulation depth (lambda) to a
%   time-domain signal (V) and time-axis (t) based on a given time-domain
%   parametric model (@model). The fitted parameters of the model are
%   returned as a last output argument. The optimal fitting start time (tstart)
%   is computed automatically using the backgroundstart() function.
%
%   [B,lambda,param] = FITBACKGROUND(V,t,@model,tstart)
%   The time at which the background starts to be fitted can be passed as a
%   an additional argument.
%
%   [B,lambda,param] = FITBACKGROUND(V,t,@model,[tstart tend])
%   The start and end times of the fitting can be specified by passing a
%   two-element array as the argument. If tend is not specified, the end of
%   the signal is selected as the default.
%
%   [B,lambda,param] = FITBACKGROUND(...,'Property',Value)
%   Additional (optional) arguments can be passed as property-value pairs.
%
% The properties to be passed as options can be set in any order.
%
%   'ModDepth' - Fixes the modulation depth to a user-defined value instead
%                of fitting it along the background.
%
%   'LogFit' - Specifies whether to fit the log of the signal (default: false)
%
%   'InitialGuess' - Array of initial values for the fit parameters
%
%   'Solver' - Optimization solver used for the fitting
%             'lsqnonlin' - Non-linear constrained least-squares (toolbox)
%             'nlsqbnd'   - Non-linear constrained least-squares (free)
%

% This file is a part of DeerLab. License is MIT (see LICENSE.md).
% Copyright(c) 2019: Luis Fabregas, Stefan Stoll, Gunnar Jeschke and other contributors.

function [B,ModDepth,FitParam,FitDelimiter] = fitbackground(V,t,BckgModel,FitDelimiter,varargin)


if ~license('test','optimization_toolbox')
    error('DeerLab could not find a valid licence for the Optimization Toolbox. Please install the add-on to use fitbackground.')
end

if nargin<3
    error('Not enough input arguments. At least three are needed: V, t, and background model.');
end

if nargin<4
    tstart = backgroundstart(V,t,BckgModel);
    tend = t(end);
    FitDelimiter = [tstart tend];
elseif ischar(FitDelimiter)
    varargin = [{FitDelimiter} varargin];
    tstart = backgroundstart(V,t,BckgModel);
    tend = t(end);
    FitDelimiter = [tstart tend];
    
elseif length(FitDelimiter) == 1
    FitDelimiter(2) = t(end);
elseif length(FitDelimiter) > 2
    error('The 4th argument cannot exceed two elements.')
end

if FitDelimiter(2)<FitDelimiter(1)
    error('The fit start time cannot exceed the fit end time.')
end

tstart = FitDelimiter(1);

if ~isa(BckgModel,'function_handle')
    error('The background model must be a valid function handle.')
end

%Parse optiona inputs
[LogFit,InitialGuess,ModDepth,Solver] = parseoptional({'LogFit','InitialGuess','ModDepth','Solver'},varargin);

if isempty(LogFit)
    LogFit = false;
end
if length(ModDepth)>1
    error('FixLambda must be a scalar.')
end
if ~isempty(ModDepth)
    if ModDepth>1 || ModDepth<0
        error('Fixed modulation depth must be in the range 0 to 1.')
    end
end

if isempty(Solver) && ~license('test','optimization_toolbox')
    Solver = 'fminsearchcon';
elseif isempty(Solver) && license('test','optimization_toolbox')
    Solver = 'lsqnonlin';
else
    validateattributes(Solver,{'char'},{'nonempty'},mfilename,'Solver')
    SolverList = {'lsqnonlin','nlsqbnd','fminsearchcon'};
    validatestring(Solver,SolverList);
end

if ~ispc && strcmp(Solver,'nlsqbnd')
   error('The ''nlsqbnd'' solver is only available for Windows systems.') 
end

if strcmp(Solver,'lsqnonlin') && ~license('test','optimization_toolbox')
    error('The ''lsqnonlin'' solver requires the Optimization Toolbox.')
end
%Ensure real part is used
V = real(V);
%Validate inputs
validateattributes(InitialGuess,{'numeric'},{'2d'},mfilename,'InitialGuess')
validateattributes(FitDelimiter,{'numeric'},{'2d','nonempty'},mfilename,'FitDelimiter')
validateattributes(V,{'numeric'},{'2d','nonempty'},mfilename,'Data')
validateattributes(t,{'numeric'},{'2d','nonempty','increasing'},mfilename,'t')
%Use column vectors
t = t(:);
V = V(:);

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%Find the position to limit fit
FitStartTime = FitDelimiter(1);
FitEndTime = FitDelimiter(2);
[~,FitStartPos] = min(abs(t - FitStartTime));
[~,FitEndPos] = min(abs(t - FitEndTime));

%Limit the time axis and the data to fit
Fitt = t(FitStartPos:FitEndPos);
FitData = V(FitStartPos:FitEndPos);

%Use absolute time scale to ensure proper fitting of negative-time data
Fitt = abs(Fitt);

%Construct cost functional for minimization
if LogFit
    %Fit in log-space
    if isempty(ModDepth)
        %Fit modulation depth...
        CostFcnVec = @(param)(sqrt(1/2)*(log((1 - param(1) + eps)*BckgModel(Fitt,param(2:end))) - log(FitData)));
        CostFcn = @(param)(sqrt(1/2)*(log((1 - param(1) + eps)*BckgModel(Fitt,param(2:end))) - log(FitData)))^2;
    else
        %Use user-given modulation depth...
        CostFcnVec = @(param)(sqrt(1/2)*(log((1 - ModDepth + eps)*BckgModel(Fitt,param(1:end))) - log(FitData)));
        CostFcn = @(param) norm(sqrt(1/2)*(log((1 - ModDepth + eps)*BckgModel(Fitt,param(1:end))) - log(FitData)))^2;
    end
else
    %Fit in linear space
    if isempty(ModDepth)
        %Fit modulation depth...
        CostFcnVec = @(param) (sqrt(1/2)*((1 - param(1))*BckgModel(Fitt,param(2:end)) - FitData));
        CostFcn = @(param) norm(sqrt(1/2)*((1 - param(1))*BckgModel(Fitt,param(2:end)) - FitData))^2;
    else
        %Use user-given modulation depth...
        CostFcnVec = @(param) (sqrt(1/2)*((1 - ModDepth)*BckgModel(Fitt,param(1:end)) - FitData));
        CostFcn = @(param) norm(sqrt(1/2)*((1 - ModDepth)*BckgModel(Fitt,param(1:end)) - FitData))^2;
    end
end

if isempty(ModDepth)
    %Initiallize StartParameters (1st element is modulation depth)
    LowerBounds(1) = 0;
    UpperBounds(1) = 1;
end
pos = 1 - length(ModDepth);
%Get information about the time-domain parametric model
Info = BckgModel();
Ranges =  [Info.parameters(:).range];
LowerBounds(1+pos:pos + Info.nparam) = Ranges(1:2:end-1);
UpperBounds(1+pos:pos + Info.nparam) = Ranges(2:2:end);
if ~isempty(InitialGuess)
    StartParameters = InitialGuess;
else
    if isempty(ModDepth)
        StartParameters(1) = 0.5;
    end
    StartParameters(1+pos:pos + Info.nparam) =  [Info.parameters(:).default];
end

%Solve the constrained nonlinear minimization problem
switch lower(Solver)
    case 'lsqnonlin'
        %Prepare minimization problem solver
        solveropts = optimoptions(@lsqnonlin,'Algorithm','trust-region-reflective','Display','off',...
            'MaxIter',8000,'MaxFunEvals',8000,...
            'TolFun',1e-10,'DiffMinChange',1e-8,'DiffMaxChange',0.1);
        %Run solver
        FitParam = lsqnonlin(CostFcnVec,StartParameters,LowerBounds,UpperBounds,solveropts);
    case 'nlsqbnd'
        %Prepare minimization problem solver
        solveropts = optimset('Algorithm','trust-region-reflective','Display','off',...
            'MaxIter',8000,'MaxFunEvals',8000,...
            'TolFun',1e-20,'TolCon',1e-20,...
            'DiffMinChange',1e-8,'DiffMaxChange',0.1);
        %Run solver
        FitParam = nlsqbnd(CostFcnVec,StartParameters,LowerBounds,UpperBounds,solveropts);
        %nlsqbnd returns a column, transpose to adapt to row-style of MATLAB solvers
        FitParam = FitParam.';
    case 'fminsearchcon'
        %Prepare minimization problem solver
        solverOpts = optimset('Algorithm','trust-region-reflective','Display','off',...
            'MaxIter',8000,'MaxFunEvals',8000,...
            'TolFun',1e-20,'TolCon',1e-20,...
            'DiffMinChange',1e-8,'DiffMaxChange',0.1);
        %Run solver
        FitParam = fminsearchcon(CostFcn,StartParameters,LowerBounds,UpperBounds,[],[],[],solverOpts);
end

if isempty(ModDepth)
    %Get the fitted modulation depth
    ModDepth = FitParam(1);
end
%Remove the modulation depth from the fit parameters
FitParam = FitParam(1+pos:end);

%Extrapolate fitted background to whole time axis
B = BckgModel(abs(t),FitParam);

%Ensure data is real
B = real(B);
B = B(:);

end

function [simParams,appParams,phyParams,outParams] = initiateParameters(simVersion, varargin)
% Function to initialize simulator parameters

nArgs = length(varargin{1});

%%%%%%%%%
% Check file config and read parameters
if nArgs < 1 || strcmp(varargin{1}{1},'0') || strcmp(varargin{1}{1},'default')
    fileCfg = 'WiLabV2Xsim.cfg';
elseif mod(nArgs-1,2)~=0
    error('Error in the number or value of input parameters. Simulation aborted.');
elseif nArgs == 1 && strcmp(varargin{1}{1},'help')
    fileCfg = '';
else
    fileCfg = char(varargin{1}{1});
end
fid = fopen(fileCfg);
if fid==-1
    if ~strcmp(varargin{1}{1},'help')
        error('File config "%s" not found!\n\n',fileCfg);
    end
else
    fclose(fid);
end
%%%%%%%%%
varargin{1}(1) = [];
if mod(length(varargin{1}),2)==1
    error('Error in the command line: an even number of inputs is needed after the config file');
end

% Initialize Simulation parameters
[simParams,varargin] = initiateMainSimulationParameters(fileCfg,simVersion,varargin{1});
simParams.fileCfg = fileCfg;

% Initialize Application parameters
[appParams,simParams,varargin] = initiateApplicationParameters(simParams,fileCfg,varargin{1});

% Initialize PHY layer parameters
[phyParams,varargin] = initiatePhyParameters(simParams,appParams,fileCfg,varargin{1});

% Initialize Output parameters
[outParams,varargin] = initiateOutParameters(simParams,phyParams,fileCfg,varargin{1});
    
% C-V2X derived parameters
if simParams.technology ~= 2 % not only 11p
    
    % Initialize CV2X resource assignement algorithm parameters
    [simParams,phyParams,varargin] = initiateBRAssignmentAlgorithm(simParams,phyParams,appParams.allocationPeriod,fileCfg,varargin{1});
    
    % Derive CV2X resources available for beaconing (Beacon Resources)
    [appParams,phyParams,varargin] = deriveBeaconResources(simParams,appParams,phyParams,fileCfg,varargin{1});    
end

% Additional parameters (currently only RSUs with DENM)
[simParams,appParams,phyParams,varargin] = initiateSpecificCasesParameters(simParams,appParams,phyParams,fileCfg,varargin{1});

if ~isempty(varargin{1})
    sError = sprintf('Error in the command line: ');
    for i=1:length(varargin{1})/2
        sErrorToCat = sprintf('Parameter [%s] not accepted. ',char(varargin{1}(i*2-1)));
        sError = strcat(sError,sErrorToCat);
    end
    error(sError);
end

end

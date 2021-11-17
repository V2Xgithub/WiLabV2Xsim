function [simParams,appParams,phyParams,varargin] = initiateSpecificCasesParameters(simParams,appParams,phyParams,fileCfg,varargin)
%
% Settings of specific cases

fprintf('Additional settings\n');

% Packet types: normally only CAMs, which are Type 1
appParams.nPckTypes = 1;

% [RSUcfg]
[appParams,varargin]= addNewParam(appParams,'RSUcfg','null','Config file for RSUs - Null if no RSUs','string',fileCfg,varargin{1});
if ~strcmpi(appParams.RSUcfg,'null')
    if ~exist(appParams.RSUcfg, 'file')
       error('File cfg of RSUs ("%s") does not exist. Set "Null" if no RSUs are to be used.',appParams.RSUcfg);
    end
    appParams = readRSUconfig(appParams.RSUcfg,appParams);
else
    appParams.nRSUs = 0;
end
appParams = rmfield( appParams , 'RSUcfg' );

% [MCOcfg]
[phyParams,varargin]= addNewParam(phyParams,'nChannels',1,'Number of channels','integer',fileCfg,varargin{1});
if phyParams.nChannels==-1
    error('Missing field in MCO config file %s: "NumberOfChannels"',fileName);
end
if phyParams.nChannels<1
    error('Number of channels must be positive');
end
if phyParams.nChannels>1
    [appParams,phyParams,varargin] = mco_initiateParameters(fileCfg,appParams,phyParams,varargin{1});    
end

fprintf('\n');
%
%%%%%%%%%

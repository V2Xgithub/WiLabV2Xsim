function [appParams] = readRSUconfig(fileName,appParams)

appParams.nRSUs = searchParamInCfgFile(fileName,'NumberOfRSUs','integer');
if appParams.nRSUs==-1
    error('Missing field in RSU config file %s: "NumberOfRSUs"',fileName);
end
if appParams.nRSUs==0
    return;
end

appParams.RSU_technology = searchParamInCfgFile(fileName,'Technology','string');
if appParams.RSU_technology==-1
    error('Missing field in RSU config file %s: "Technology"',fileName);
end
if ~strcmpi(appParams.RSU_technology,'11p') && ~strcmpi(appParams.RSU_technology,'LTE')
    error('Technology must be "11p" or "LTE"');
end

appParams.RSU_pckTypeString = searchParamInCfgFile(fileName,'PacketType','string');
if appParams.RSU_pckTypeString==-1
    error('Missing field in RSU config file %s: "PacketType"',fileName);
end
if strcmpi(appParams.RSU_pckTypeString,'CAM')
    % nothing to do
elseif strcmpi(appParams.RSU_pckTypeString,'DENM') || strcmpi(appParams.RSU_pckTypeString,'hpDENM')
    if ~strcmpi(appParams.RSU_technology,'11p')
        error('DENM and high priority DENM implemented only in "11p"');
    end
    appParams.nPckTypes = 2;
else
    error('RSU packet type %s invalid: only CAM, DENM, or hpDENM',appParams.RSU_pckTypeString);
end

appParams.RSU_xLocation = searchParamInCfgFile(fileName,'xLocation','integerOrArrayString');
if appParams.RSU_xLocation==-1
    error('Missing field in RSU config file %s: "xLocation"',fileName);
end
if length(appParams.RSU_xLocation)~=appParams.nRSUs
    error('The list of x positions in the RSU config %s is not correct for %s RSUs',fileName,appParams.nRSUs);
end

appParams.RSU_yLocation = searchParamInCfgFile(fileName,'yLocation','integerOrArrayString');
if appParams.RSU_yLocation==-1
    error('Missing field in RSU config file %s: "yLocation"',fileName);
end
if length(appParams.RSU_yLocation)~=appParams.nRSUs
    error('The list of y positions in the RSU config %s is not correct for %s RSUs',fileName,appParams.nRSUs);
end

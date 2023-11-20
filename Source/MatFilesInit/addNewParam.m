function [structureChanged,varargin] = addNewParam(structureToChange,field,defaultValue,paramDescription,paramType,fileCfg,varargin)
% Function to create a new parameter

sourceForValue = 0; % 0: default
value = defaultValue;
valueInCfg = searchParamInCfgFile(fileCfg,field,paramType);
if ~isnan(valueInCfg)
    value = valueInCfg;
    sourceForValue = 1; % 1: file config
end
for i=1:(length(varargin{1}))/2
    if strcmpi(varargin{1,1}{2*i-1},field)
        value = varargin{1,1}{2*i};
        sourceForValue = 2; % 2: command line
        % I remove this parameter and value from varargin
        % This allows to check that all parameters are correctly given in
        % input
        varargin{1}(2*i-1) = [];
        varargin{1}(2*i-1) = [];
        break;
    end
end

% Print to command window
fprintf('%s:\t',paramDescription);
fprintf('[%s] = ',field);
if strcmpi(paramType,'integer')
    if ~isnumeric(value) || mod(value,1)~=0
        error('Error: parameter %s must be an integer.',field);
    end
    fprintf('%.0f ',value);
elseif strcmpi(paramType,'double')
    if ~isnumeric(value)
        error('Error: parameter %s must be a number.',field);
    end
    fprintf('%f ',value);
elseif strcmpi(paramType,'string')
    if ~isstring(value) && ~ischar(value)
        error('Error: parameter %s must be a string.',field);
    end
    fprintf('%s ',value);
elseif strcmpi(paramType,'bool')    
    if ~islogical(value)
        error('Error: parameter %s must be a boolean.',field);
    end
    if value == true
        fprintf('true ');
    else
        fprintf('false ');
    end
elseif strcmpi(paramType,'integerOrArrayString') 
    if ischar(value)
        value = str2num(value);
    end    
    for iValue=1:length(value)
        if ~isnumeric(value(iValue)) || mod(value(iValue),1)~=0
            error('Error: parameter %s must be an integer or a string with integers.',field);
        end
        if iValue>1
            fprintf(',');
        end
        fprintf('%.0f',value(iValue));
    end
    fprintf(' ');
else
    error('Error in addNewParam: paramType can be only integer, double, string, or bool.');
end
if sourceForValue==0
    fprintf('(default)\n');
elseif sourceForValue==1
    fprintf('(file %s)\n',fileCfg);
else
    fprintf('(command line)\n');
end
structureChanged = setfield(structureToChange,field,value);
    


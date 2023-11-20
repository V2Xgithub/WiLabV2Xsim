function [simParams,varargin] = initiateCoexistenceParameters(simParams,fileCfg,varargin)

%% [coexMethod]
[simParams,varargin] = addNewParam(simParams,'coexMethod','0','Select the coexistence method. "0" means standard solution','string',fileCfg,varargin{1});
% The letter, used for compliance with ETSI specifications, is
% converted into a number for efficiency
coexMethods = ['0', 'A', 'B', 'C', 'D', 'E', 'F'];
[~, simParams.coexMethod] = ismember(simParams.coexMethod, coexMethods);
simParams.coexMethod = simParams.coexMethod - 1;

if simParams.coexMethod == constants.COEX_METHOD_NON
    %default: standard protocols
elseif ismember(simParams.coexMethod, constants.COEX_METHODS_IMPLEMENTED)
    %% Methods "A", "B", "C", "F"
    % Method "A": superframe, with a portion dedicated to LTE and the other to 11p
    % Method "B": similar superframe, but energy signals used from LTE
    % Method "F": similar superframe, but with NAV setting nodes
    %% Additional Parameters for coexistence Methods A, B, C, F
    % Superframe duration
    [simParams,varargin] = addNewParam(simParams,'coex_superFlength',0.01,'Coexistence, superframe length [s]','double',fileCfg,varargin{1});
    if simParams.coex_superFlength<=0 
        error('simParams.coex_superFlength cannot be lower than or equal to 0');
    end
    
    %% Parameters for fixed/dynamic superframe
    %% [coex_slotManagement]
    [simParams,varargin] = addNewParam(simParams,'coex_slotManagement','static','coex: static or dynamic management of slots','string',fileCfg,varargin{1});
    if strcmpi(simParams.coex_slotManagement,'static')
        simParams.coex_slotManagement = constants.COEX_SLOT_STATIC;
        % Portion dedicated to LTE
        [simParams,varargin] = addNewParam(simParams,'coex_endOfLTE',-1,'Coex: end of the LTE portion within the superframe [s] (-1 is automatic set)','double',fileCfg,varargin{1});
        if simParams.coex_endOfLTE==-1
            simParams.coex_endOfLTE = simParams.coex_superFlength * (simParams.numVehiclesLTE / (simParams.numVehiclesLTE + simParams.numVehicles11p));
        end
        if simParams.coex_endOfLTE<0 || simParams.coex_endOfLTE>simParams.coex_superFlength
            error('simParams.coex_endOfLTE must be within 0 and simParams.coex_superFlength');
        end
    elseif strcmpi(simParams.coex_slotManagement,'dynamic')
        simParams.coex_slotManagement = constants.COEX_SLOT_DYNAMIC;
        [simParams,varargin] = addNewParam(simParams,'coex_printTechPercentage',true,'Coex: print technology percentage to file','bool',fileCfg,varargin{1});
    else
        error('Coex: the slot management must be "static" or "dynamic" (not %s)',simParams.coex_slotManagement);
    end
  
    %% Additional Parameters
    switch simParams.coexMethod
        case constants.COEX_METHOD_A  % Additional Parameters for coexistence Method A only
            % Guard time configuration
            [simParams,varargin] = addNewParam(simParams,'coexA_guardTime',0,'Coex A: guard time between portions [s]','double',fileCfg,varargin{1});
            if simParams.coexA_guardTime~=-1 && (simParams.coexA_guardTime<0 || simParams.coexA_guardTime>simParams.coex_endOfLTE || ...
                    simParams.coexA_guardTime>(simParams.coex_superFlength-simParams.coex_endOfLTE))
                error('simParams.coexA_guardTime must be >=0 and lower than the duration of both portions');
                % Note: "-1" is acceptable. It means automatically set to the
                % duration of an IEEE 802.11p packet
            end
            
            [simParams,varargin] = addNewParam(simParams,'coexA_improvements',0,'Coex A: improvements outside ETSI doc','integer',fileCfg,varargin{1});
            if simParams.coexA_improvements<0 || simParams.coexA_improvements>3
                error('Error in simParams.coexA_improvements: only 0, 1, 2, 3 allowed');
            end
 
            [simParams,varargin] = addNewParam(simParams,'coexA_desynchError',0,'Coex A: error in ITS-G5 synch','double',fileCfg,varargin{1});
            if simParams.coexA_desynchError<0
                error('Error: negative simParams.coexA_desynchError');
            end
            
            [simParams,varargin] = addNewParam(simParams,'coexA_withLegacyITSG5',false,'Assume ITS-G5 legacy nodes','bool',fileCfg,varargin{1});
            if simParams.coexA_withLegacyITSG5 && (simParams.coexA_improvements>0 || simParams.coexA_desynchError>0)
                error('coexA_withLegacyITSG5 can be set to true only if coexA_improvements and coexA_desynchError are set to zero');
            end 
            
            [simParams,varargin] = addNewParam(simParams,'coexA_endOfLteKnownBy11p',-1,'Coex A: end of LTE slot by ITS-G5 (-1 is coex_endOfLTE)','double',fileCfg,varargin{1});
            if (simParams.coexA_endOfLteKnownBy11p~=-1 && simParams.coexA_endOfLteKnownBy11p<0) || simParams.coexA_endOfLteKnownBy11p>simParams.coex_superFlength
                error('Error: simParams.coexA_endOfLteKnownBy11p=%f not acceptable',simParams.coexA_endOfLteKnownBy11p);
            end     

        case constants.COEX_METHOD_B  % Additional Parameters for coexistence Method B only
            simParams.coexA_desynchError=0;  

            % Interval before first siubframe
            [simParams,varargin] = addNewParam(simParams,'coexB_timeBeforeLTEstarts',-1,'Coex B: beginning of energy symbol (Type 1) before LTE part starts [s]','double',fileCfg,varargin{1});
            if simParams.coexB_timeBeforeLTEstarts~=-1 && (simParams.coexB_timeBeforeLTEstarts<0 || ...
                    simParams.coexB_timeBeforeLTEstarts>(simParams.coex_superFlength-simParams.coex_endOfLTE))
                error('simParams.coexB_timeBeforeLTEstarts must be larger than 0 and lower than the duration of 11p portion');
                % Note: "-1" is acceptable. It means automatically set to the
                % duration of an IEEE 802.11p packet
            end
            %% Could be added in case
            % % TX power level
            %[simParams,varargin] = addNewParam(simParams,'coexB_portionOfPower',1,'Coex B: ERP of energy signals referred to other LTE signals (1 means the same)','double',fileCfg,varargin{1});
            %if simParams.coexB_portionOfPower<=0
            %    error('simParams.coexB_portionOfPower must be higher than 0');
            %    % Note: in prinicple, it can be higher than 1
            %end

            % If all LTE nodes should transmit the energy signal in empty
            % SF (true) or only those with something to transmit in the
            % future (false)
            [simParams,varargin] = addNewParam(simParams,'coexB_allToTransmitInEmptySF',true,'Coex B: if all nodes should transmit ES in empty SF or only selected','bool',fileCfg,varargin{1});

        case constants.COEX_METHOD_C  % Additional Parameters for coexistence Method C only
            simParams.coexA_desynchError=0;

            [simParams,varargin] = addNewParam(simParams,'coexC_timegapVariant',1,'Coex C: variant of the time gap before LTE slot','integer',fileCfg,varargin{1});
            if simParams.coexC_timegapVariant~=1 && simParams.coexC_timegapVariant~=2
                error('simParams.coexC_timegapVariant must be set to 1 or 2');
            end   
            
            [simParams,varargin] = addNewParam(simParams,'coexC_11pDetection',false,'Coex C: variant where 11p is detected and its interference removed','bool',fileCfg,varargin{1});        
            [simParams,varargin] = addNewParam(simParams,'coexCmodifiedCW',false,'Coex C: variant where 11p has a modified CW calculation','bool',fileCfg,varargin{1});        
            [simParams,varargin] = addNewParam(simParams,'coexC_moreThanOneSubframe',false,'Coex C: variant where more than 1 subframe is indicated','bool',fileCfg,varargin{1});

        case constants.COEX_METHOD_F  % Additional Parameters for coexistence Method F only
            simParams.coexA_desynchError=0;
            [simParams,varargin] = addNewParam(simParams,'coexF_guardTime',true,'Coex F: guard interval added in ITS-G5 before superframe','bool',fileCfg,varargin{1});
    end
else
    error('Coexistence: only "0", "A", "B", "C", "F" are implemented');
end

[simParams,varargin] = addNewParam(simParams,'coex_cbrLteVariant',3,'Coex: variant of the cbr-lte calculation','integer',fileCfg,varargin{1});
if simParams.coex_cbrLteVariant<1 || simParams.coex_cbrLteVariant>5
    error('simParams.coex_cbrLteVariant must be set between 1 and 5');
end
%
[simParams,varargin] = addNewParam(simParams,'coex_cbrTotVariant',1,'Coex: variant of the cbr-tot calculation','integer',fileCfg,varargin{1});
if simParams.coex_cbrTotVariant~=1 && simParams.coex_cbrTotVariant~=2 && simParams.coex_cbrTotVariant~=9
    error('simParams.coex_cbrTotVariant must be set to 1 or 2');
end
%%



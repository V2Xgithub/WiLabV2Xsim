function [simParams,phyParams,varargin] = initiateBRAssignmentAlgorithm(simParams,phyParams,Tbeacon,fileCfg,varargin)
% function [simParams,varargin]= initiateBRAssignmentAlgorithm(simParams,fileCfg,varargin)
%
% Main settings of the simulation
% It takes in input the structure simParams, the name of the (possible) file config and the inputs
% of the main function
% It returns the structure "simParams"

fprintf('Settings of resource assignement algorithm\n');

% [BRAlgorithm]
% Selects the BR reassignment algorithm:
% 2 -> CONTROLLED with REUSE DISTANCE and scheduled vehicles
% 7 -> CONTROLLED with MAXIMUM REUSE DISTANCE (MRD)
% 8 -> AUTONOMOUS with SENSING (3GPP STANDARD MODE 4) - ON A BEACON PERIOD
% BASIS
% 18 -> AUTONOMOUS with SENSING (3GPP STANDARD MODE 4) - ON A SUBFRAME
% BASIS
% 9 -> CONTROLLED with POWER CONTROL
% 10 -> CONTROLLED with MINIMUM REUSE POWER (MRP)

% [BENCHMARKS Algorithms]
% Algorithms used as benchmarks
% 101 -> RANDOM ALLOCATION
% 102 -> ORDERED ALLOCATION (following X coordinate)

[simParams,varargin] = addNewParam(simParams,'BRAlgorithm',18,'Assignment algorithm','integer',fileCfg,varargin{1});
if simParams.BRAlgorithm~=2 && ...
        simParams.BRAlgorithm~=7 && simParams.BRAlgorithm~=18 && ...
        simParams.BRAlgorithm~=10 && ...
        simParams.BRAlgorithm~=101 && simParams.BRAlgorithm~=102
    error('Error: "simParams.BRAlgorithm" not valid. Algorithm not implemented.');
end

if simParams.BRAlgorithm==2
    % [posError95]
    % LTE Positioning Accuracy (Gaussian model): 95th percentile of the error (m)
    [simParams,varargin] = addNewParam(simParams,'posError95',0,'LTE positioning error - 95th percentile (only controlled) (m)','double',fileCfg,varargin{1});
    simParams.sigmaPosError = simParams.posError95/1.96;   % Standard deviation of the error (m)

    % [Tupdate]
    % Time interval between each position update at the eNodeBs (s)
    [simParams,varargin]= addNewParam(simParams,'Tupdate',Tbeacon,'Time interval between position updates at the eNodeBs (s)','double',fileCfg,varargin{1});
    if simParams.Tupdate<=0
        error('Error: "simParams.Tupdate" cannot <= 0');
    end

    % [Mreuse]
    % Reuse margin (m) (only valid for controlled LTE-V2V with reuse distance [BRAlgorithm 2])
    [simParams,varargin]= addNewParam(simParams,'Mreuse',0,'Reuse margin (m)','integer',fileCfg,varargin{1});
else
    simParams.posError95 = 0;
    simParams.sigmaPosError = 0;
    simParams.Tupdate = Tbeacon;
    simParams.Mreuse=0;
end
    
if  simParams.BRAlgorithm==2 || simParams.BRAlgorithm==7 || simParams.BRAlgorithm==9  || simParams.BRAlgorithm==10
    % [Treassign]
    % Time interval between each scheduled BR reassignment (BRAlgorithm 2,7,9,10) (s)
    % By default it is set equal to the beacon period
    [simParams,varargin]= addNewParam(simParams,'Treassign',Tbeacon,'Interval of scheduled reassignment (BRAlgorithm 2,7,9,10) (s)','double',fileCfg,varargin{1});
    if simParams.Treassign<=0
        error('Error: "simParams.Treassign" cannot be <= 0.');
    end
end

% if simParams.BRAlgorithm == 9
%     % [blockTarget]
%     % Target blocking rate
%     [simParams,varargin]= addNewParam(simParams,'blockTarget',0.01,'Target blocking rate','double',fileCfg,varargin{1});
% end

if simParams.BRAlgorithm == 10
    % [knownShadowing]
    % Selects if shadowing is estimated at the eNB side
    [simParams,varargin]= addNewParam(simParams,'knownShadowing',false,'if shadowing is estimated at the eNB side','bool',fileCfg,varargin{1});
end

if simParams.BRAlgorithm == 18 || simParams.BRAlgorithm == 101
    if simParams.BRAlgorithm == 18
        % [probResKeep]
        % Probability to keep the previously selected BR
        [simParams,varargin]= addNewParam(simParams,'probResKeep',0.8,'Probability to keep the previously selected BR','double',fileCfg,varargin{1});
        if simParams.probResKeep<0 || simParams.probResKeep>0.8
            error('Error: "simParams.probResKeep" must be within 0 and 0.8');
        end

        % [ratioSelectedMode4]
        % Percentage of resources to be considered for random selection
        [simParams,varargin]= addNewParam(simParams,'ratioSelectedMode4',0.2,'Percentage of resources to be considered for random selection','double',fileCfg,varargin{1});
        if simParams.ratioSelectedMode4<=0 || simParams.ratioSelectedMode4>1
            error('Error: "simParams.ratioSelectedMode4" must be more than 0 and not more than 1 (specs: 0.2)');
        end

        % [testMBest_5G]
        % Parameter used for reintroduce L2 in mode2
        [simParams,varargin]= addNewParam(simParams,'testMBest_5G',1,'Percentage of resources to be considered for random selection','double',fileCfg,varargin{1});
        if simParams.testMBest_5G<=0 || simParams.testMBest_5G>1
            error('Error: "simParams.testMBest_5G" must be more than 0 and not more than 1 (specs: 0.2)');
        end


    %     % [NsensingPeriod]
    %     % Number of beacon periods during which performing sensing
    %     [simParams,varargin{1}{1}]= addNewParam(simParams,'NsensingPeriod',10,'Number of beacon periods during which performing sensing','integer',fileCfg,varargin{1}{1});
    %     if simParams.NsensingPeriod<=0
    %         error('Error: "simParams.NsensingPeriod" must be larger than 0');
    %     end

        % [TsensingPeriod]
        % Duration of the sensing period, in seconds
        [simParams,varargin]= addNewParam(simParams,'TsensingPeriod',1,'Duration of the sensing period, in seconds','double',fileCfg,varargin{1});
        if simParams.TsensingPeriod<=0
            error('Error: "simParams.TsensingPeriod" must be larger than 0');
        end

        % [minRandValueMode4]
        % Minimum duration keeping the same allocation
        [simParams,varargin]= addNewParam(simParams,'minRandValueMode4',-1,'Minimum duration keeping the same allocation','integer',fileCfg,varargin{1});
        if simParams.minRandValueMode4~=-1 && simParams.minRandValueMode4<=0
            error('Error: "simParams.minRandValueMode4" must be more than 0');
        end

        % [maxRandValueMode4]
        % Maximum duration keeping the same allocation
        [simParams,varargin]= addNewParam(simParams,'maxRandValueMode4',-1,'Maximum duration keeping the same allocation','integer',fileCfg,varargin{1});
        if simParams.maxRandValueMode4~=-1 && simParams.maxRandValueMode4<=simParams.minRandValueMode4
            error('Error: "simParams.maxRandValueMode4" must be larger than "simParams.minRandValueMode4"');
        end
        
        
        % [powerThresholdAutonomous]
        % Minimum power threshold to consider a BR as occupied in dBm
        [simParams,varargin]= addNewParam(simParams,'powerThresholdAutonomous',-110,'Minimum power threshold to consider a BR as occupied in Mode 4, in dBm','double',fileCfg,varargin{1});
        if simParams.powerThresholdAutonomous/2<-64 || simParams.powerThresholdAutonomous/2>-1 || mod(simParams.powerThresholdAutonomous,2)~=0
            error('Error: "simParams.powerThresholdAutonomous" must be between -128 and -2, step 2 dB');
        end
        % From dBm to linear
        simParams.powerThresholdAutonomous = 10^((simParams.powerThresholdAutonomous-30)/10);

        % [minSCIsinr]
        % Minimum SINR for a SCI to be correctly decoded
        [phyParams,varargin] = addNewParam(phyParams,'minSCIsinr',0,'Minimum SINR for a SCI to be correctly decoded, in dB','double',fileCfg,varargin{1});
        phyParams.minSCIsinr = 10^((phyParams.minSCIsinr)/10);
        
        % [asynMode]
        % Enables Asynchronous transmitters
        [simParams,varargin]= addNewParam(simParams,'asynMode',0,'Enables/Desable Asynchronous transmitters','integer',fileCfg,varargin{1});
        if (simParams.asynMode ~=0 && simParams.asynMode ~= 1)
            error('Error: "simParams.asynMode" cannot different from 0 or 1');
        end
        
        % [percAsynUser]
        % if Asynchronous transmitters is active -> sets the percentage of
        % Asynchronous users
        if simParams.asynMode == 1
            [simParams,varargin]= addNewParam(simParams,'percAsynUser',0.2,'Percentage of asynchronous users','double',fileCfg,varargin{1});
            if simParams.percAsynUser<0 || simParams.percAsynUser>1
                error('Error: "simParams.percAsynUser" must be within 0 and 1');
            end
        end
        
    end
    
    
%     % [subframeT1Mode4]
%     % Minimum subframe for the next allocation
%     [simParams,varargin]= addNewParam(simParams,'subframeT1Mode4',1,'Minimum subframe for the next allocation in Mode 4','integer',fileCfg,varargin{1});
%     if simParams.subframeT1Mode4<1 || simParams.subframeT1Mode4>4
%         error('Error: "simParams.subframeT1Mode4" must be between 1 and 4');
%     end
%     
%     % [subframeT2Mode4]
%     % Maximum subframe for the next allocation
%     [simParams,varargin]= addNewParam(simParams,'subframeT2Mode4',100,'Maximum subframe for the next allocation in Mode 4','integer',fileCfg,varargin{1});
%     if simParams.subframeT2Mode4<20 || simParams.subframeT2Mode4>100
%         error('Error: "simParams.subframeT2Mode4" must be between 20 and 100');
%     end
    

    % [T1autonomousMode]
    % Minimum time for the next allocation in ms
    % For 5G, T1 is modelled as the sum of Tproc,0 and Tproc,1
    % Tproc,1 must be smaller to 3, 2.5, or 2.25 ms for a SCS of 15, 30, 60 kHz, respectively.
    % Tproc,0 is equivalent to 1 ms for a SCS of 15 kHz and 0.50 ms for the rest of SCS configurations. 
    
    if phyParams.muNumerology==0    % 4G and 5G SCS=15
    [simParams,varargin]= addNewParam(simParams,'T1autonomousMode',1,'Minimum time for the next allocation in Autonomous Mode','integer',fileCfg,varargin{1});
        if simParams.T1autonomousMode<1 || simParams.T1autonomousMode>4
            error('Error: "simParams.T1autonomousMode" must be between 1 and 4 in LTE and 5G SCS=15');
        end
    elseif phyParams.muNumerology==1 || phyParams.muNumerology==2 % 5G SCS=30 and 5G SCS=60
        [simParams,varargin]= addNewParam(simParams,'T1autonomousMode',0.5,'Minimum time for the next allocation in Autonomous Mode','double',fileCfg,varargin{1});
        if (simParams.T1autonomousMode<0.5 || simParams.T1autonomousMode>3)&&(phyParams.muNumerology==1)
            error('Error: "simParams.T1autonomousMode" must be between 0.5 and 3 in 5G with SCS=30');
        elseif (simParams.T1autonomousMode<0.5 || simParams.T1autonomousMode>2.75)&&(phyParams.muNumerology==2)
            error('Error: "simParams.T1autonomousMode" must be between 0.5 and 2.75 in 5G with SCS=60');
        end
    end
                
    % [T2autonomousMode]
    % Maximum time for the next allocation in ms
    [simParams,varargin]= addNewParam(simParams,'T2autonomousMode',100,'Maximum time for the next allocation in autonomous mode','integer',fileCfg,varargin{1});
        if simParams.T2autonomousMode<20 || simParams.T2autonomousMode>100
            error('Error: "simParams.T2autonomousMode" must be between 20 and 100 ms in LTE and 5G');
        end
    
    simParams.T1autonomousModeTTIs = simParams.T1autonomousMode*(2^phyParams.muNumerology);    % T1 in terms of TTIs
    simParams.T2autonomousModeTTIs = simParams.T2autonomousMode*(2^phyParams.muNumerology);    % T2 in terms of TTIs
   

        
end

if phyParams.BRoverlapAllowed && simParams.BRAlgorithm ~= 18 && simParams.BRAlgorithm ~= 101
    error('Partial overlap in the frequency domain implemented only for Mode 4 (alg. 18) or Random (101)');
end

if phyParams.cv2xNumberOfReplicasMax>1 && simParams.BRAlgorithm ~= 18 && simParams.BRAlgorithm ~= 101
    error('HHARQ implemented only for Mode 4 (alg. 18 and alg. 101)');
end

fprintf('\n');

end

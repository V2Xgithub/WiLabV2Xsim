function [IBEmatrixData, IBEmatrixControl] =...
    IBEcalculation(simParams,phyParams,appParams)
% This function computes the In-Band Emission Matrix, following 
% the model reported in 3GPP TS 36.101 V15.0.0 for LTE and 
% the model reported in 3GPP TS 38.101-1 V17.0.0 (2020-12) for 5G

if ~phyParams.haveIBE
    IBEmatrixData = eye(appParams.NbeaconsF,appParams.NbeaconsF);
    IBEmatrixControl = eye(appParams.NbeaconsF,appParams.NbeaconsF);
    return
end


%% START PLOT1 AND PLOT2
%activePlots = false;
%% STOP PLOT1 AND PLOT2

%% Inizialization of variables from phyParams and appParams
%
% N_RB_tot is the total bandwidth in terms of RBs
if simParams.mode5G == constants.MODE_LTE
    N_RB_tot = phyParams.RBsSubframe/2;
elseif simParams.mode5G == constants.MODE_5G
    N_RB_tot = phyParams.RBsSubframe/(phyParams.Tsf/phyParams.Tslot_NR);
else
    error("wrong selection of mode5G")
end

% N_RB_beacon is the bandwidth of a beacon in terms of RBs
%N_RB_beacon = appParams.RBsBeacon/2;

% Number of beacons in a subframe
nBeaconPerSubframe = appParams.NbeaconsF;

% Number of RBs of the channel(s) (might be more than one) that allocate
% one beacon
%nRBofSubchAllocatingOneBeacon = phyParams.RBsBeaconSubchannel;

% Number of subchannles, adopted MCS, adjacent/non-adjacent
% allocation
nSubchannels = phyParams.NsubchannelsFrequency;
if simParams.mode5G == constants.MODE_LTE
    MCS = phyParams.MCS_LTE;
    ifAdjacent = phyParams.ifAdjacent;
else	%5G, local variables for easier reading
    MCS = phyParams.MCS_NR;
    SCS = phyParams.SCS_NR;
end
%% 

%%
% Setting of the parameters
% Parameters W,X,Y,Z
if simParams.mode5G == constants.MODE_LTE
    % Parameters W,X,Y,Z
	W = 3;
	X = 6;
	Y = 3;
	Z = 3;
	% EVM
	if MCS >= 0 && MCS <= 10
	    % BPSK-QPSK
	    EVM = 0.175;
	elseif MCS <= 20
	    % 16-QAM
	    EVM = 0.125;
	else
	    error('MCS in IBEcalculation() not valid. MCS must be in 0-20');
	end
else %5G
   % settings 5G
   	W = 0;
	X = 0;
	Y = 0;
	Z = 0;
   % EVM
    if MCS >= 0 && MCS <= 9
        % BPSK-QPSK
        EVM = 0.175;
    elseif MCS <= 16
        % 16-QAM
        EVM = 0.125;
    elseif MCS <= 28
        % 64 Q-AM
        EVM = 0.08;
    else
        error('MCS in IBEcalculation() not valid. MCS must be in 0-28');
    end
end

% If nBeaconPerSubframe is 1, there cannot be IBE and the IBEmatrix is set to 1
% If nBeaconPerSubframe is 0, it means that more than one subbrframe
% is needed to allocate a beacon; also in such case, IBEmatrix must be set to 1
if nBeaconPerSubframe==1 || nBeaconPerSubframe==0
    IBEmatrixData = 1;
    IBEmatrixControl = 1;
    return
end
%%

%% DATA %%
% Initialization
IBEmatrixData = ones(nBeaconPerSubframe,nBeaconPerSubframe);
startRB = -1*ones(1,nBeaconPerSubframe);
stopRB = -1*ones(1,nBeaconPerSubframe);

% Gap between beacon allocations removed in version 5.2.1
%rbPerGap = (nRBofSubchAllocatingOneBeacon-N_RB_beacon)*ones(1,nBeaconPerSubframe-1);
%%

% Setting the start and end of each beacon resource
%%%% START PLOT1
% if activePlots
%     figure(101);
%     plot([1 N_RB_tot],[1 1],'--r');
%     hold on
% end
%%%% END PLOT1
if simParams.mode5G == constants.MODE_LTE
    startRB(1) = nSubchannels*2*(1-(ifAdjacent))+2*(ifAdjacent)+1;
    %stopRB(1) = nSubchannels*2*(1-(ifAdjacent))+2*(ifAdjacent)+N_RB_beacon;
    stopRB(1) = startRB(1)+(phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel)-(2*ifAdjacent)-1;
else %5G
    startRB(1) = 1;
	stopRB(1) = startRB(1)+(phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel)-1;
end	
%%%% START PLOT1
% if activePlots
%     plot(startRB(1):stopRB(1),ones(1,N_RB_beacon),'ok');
% end
%%%% STOP PLOT1
for i=2:nBeaconPerSubframe
    if phyParams.BRoverlapAllowed
        startRB(i) = startRB(i-1)+phyParams.sizeSubchannel;
    else
        if simParams.mode5G==0
                startRB(i) = stopRB(i-1)+(2*ifAdjacent)+1;
        else %5g
            startRB(i) = stopRB(i-1) +1;
        end
    end
    if simParams.mode5G == constants.MODE_LTE
	    stopRB(i) = startRB(i)+(phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel)-(2*ifAdjacent)-1;
    else %5G
	    stopRB(i) = startRB(i)+(phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel) -1;
    end
    %%%% START PLOT1
%     if activePlots
%         plot(stopRB(i-1)+1:startRB(i)-1,zeros(1,rbPerGap(i-1)),'pb');
%         plot(startRB(i):stopRB(i),ones(1,N_RB_beacon),'ob');
%     end
    %%%% STOP PLOT1
end
if stopRB(end) > appParams.RBsFrequencyV2V
    error('Something wrong in IBEcalculation. Last RB is %d, but there are %d in total.\n',stopRB(end),appParams.RBsFrequencyV2V);
end
%%

%%
% Calculating the IBE
%%%% START PLOT2
% if activePlots
%     int1Plot = -50*ones(1,N_RB_tot);
%     int2Plot = -50*ones(1,N_RB_tot);
% end
%%%% STOP PLOT2
for iBeacon1 = 1:nBeaconPerSubframe
    for iBeacon2 = 1:nBeaconPerSubframe
        % From interferer iBeacon2 to useful iBeacon1
        if iBeacon1~=iBeacon2
            % Setting the bandwidth of the interfering signal
            L_CRB = stopRB(iBeacon2)-startRB(iBeacon2)+1;            
            interference = 0;
            for rbIndex=startRB(iBeacon1):stopRB(iBeacon1) % in the interfered window
                %
                % 1) GENERAL PART
                % Setting the gap Delta_RB betweeen interfering and useful signals
                % if iBeacon2>iBeacon1:     Delta_RB = startRB(iBeacon2)-rbIndex
                % else:                     Delta_RB = rbIndex-stopRB(iBeacon2))
                % The same is obtained using a max() function
                Delta_RB = max(startRB(iBeacon2)-rbIndex, rbIndex-stopRB(iBeacon2));                
                % if rbIndex is within start-stop, then Delta_RB<=0 and
                % interference is set to 1
                if Delta_RB<=0
                    interference = interference + 1;
                else
                    % Interference calculation
                    % P_RB_dBm is fixed to the maximum, -30 dB, as per the
                    % NOTE 1 of 3GPP 36.101 (Table 6.5.2A.3.1-1)
                    P_RB_dBm = 0;
                    if simParams.mode5G == 0
                        interferenceG_dB = max(max( -25-10*log10(N_RB_tot/L_CRB)-X,20*log10(EVM)-3-5*(abs(Delta_RB)-1)/L_CRB-W),(-57/180e3-P_RB_dBm-X)-30);
                    else %5G
                        interferenceG_dB = max(max( -25-10*log10(N_RB_tot/L_CRB)-X,20*log10(EVM)-3-5*(abs(Delta_RB)-1)/L_CRB-W),(-57+10*log10(SCS/15)-P_RB_dBm)-30);
                    end                
                    interferenceG = 10^( interferenceG_dB/10 );
                    %
                    % 2) IQ IMAGE
                    % Find the image of the rbIndex, looking at nRBperSubframeTot
                    rbImage = (N_RB_tot-(rbIndex)+1); 
                    if rbImage>=startRB(iBeacon2) && rbImage<=stopRB(iBeacon2)
                        interferenceIQ = 10^( (-25-Y)/10 ); 
                    else
                        interferenceIQ = 0;
                    end
                    %
                    % 3) CARRIER LEACKAGE
                    interferenceCL = 0;
                    if mod(N_RB_tot,2)==1 % ODD (TOT): one RB
                        if rbIndex==ceil(N_RB_tot/2)
                           interferenceCL = 10^( (-25-Z)/10 ); 
                        end  
                    else % EVEN (TOT): two RBs
                        if rbIndex==ceil(N_RB_tot/2)-1 || rbIndex==ceil(N_RB_tot/2)
                           interferenceCL = 10^( (-25-Z)/10 ); 
                        end  
                    end
                    % OPTION1: Maximum between the sum and P_RB_dBm-30
                    %interference = interference + max(10^((P_RB_dBm-30)/10),interferenceG+interferenceIQ+interferenceCL);
                    % OPTION2: Directly the sum
                    interference = interference + interferenceG+interferenceIQ+interferenceCL;
                    %%%% START PLOT2
    %                 if activePlots
    %                     if iBeacon2==1
    %                        int1Plot(rbIndex) = 10 * log10(interferenceG+interferenceIQ+interferenceCL);
    %                     end
    %                     if iBeacon2==2
    %                        int2Plot(rbIndex) = 10 * log10(interferenceG+interferenceIQ+interferenceCL);
    %                     end
    %                 end
                    %%%% STOP PLOT2
                end
            end    
            % Average over the allocated bandwidth
            interference = interference/(stopRB(iBeacon1)-startRB(iBeacon1)+1);
            IBEmatrixData(iBeacon1,iBeacon2) = interference;
        end
    end
end
%%

%%%% START PLOT2
% if activePlots
%     figure(102);
%     %plot(1:nRBperSubframeToAlloc,int1Plot,'ok');
%     plot(1:length(int1Plot),int1Plot,'ok-');
%     hold on
%     grid on
%     %plot(1:nRBperSubframeToAlloc,int2Plot,'pr');
%     plot(1:length(int2Plot),int2Plot,'pr-');
% end
%%%% STOP PLOT1

if simParams.mode5G == constants.MODE_5G
    % The IBE for the control of 5G is approximated with the one for Data
	IBEmatrixControl = IBEmatrixData;
	return;
end

%% CONTROL %%
% Initialization
IBEmatrixControl = ones(nBeaconPerSubframe,nBeaconPerSubframe);
startRB = -1*ones(1,nBeaconPerSubframe);
stopRB = -1*ones(1,nBeaconPerSubframe);

% Gap between beacon allocations removed in version 5.2.1
%rbPerGap = (nRBofSubchAllocatingOneBeacon-N_RB_beacon)*ones(1,nBeaconPerSubframe-1);
%%

% Setting the start and end of each SCI resource
startRBcontrol = startRB;
stopRBcontrol = startRBcontrol+1;

for iBeacon1 = 1:nBeaconPerSubframe
    for iBeacon2 = 1:nBeaconPerSubframe
        % From interferer iBeacon2 to useful iBeacon1
        if iBeacon1~=iBeacon2
            % Setting the bandwidth of the interfering signal
            L_CRB = stopRB(iBeacon2)-startRB(iBeacon2)+1;            
            interference = 0;
            for rbIndex=startRBcontrol(iBeacon1):stopRBcontrol(iBeacon1) % in the interfered window
                %
                % 1) GENERAL PART
                % Setting the gap Delta_RB betweeen interfering and useful signals
                % if iBeacon2>iBeacon1:     Delta_RB = startRB(iBeacon2)-rbIndex
                % else:                     Delta_RB = rbIndex-stopRB(iBeacon2))
                % The same is obtained using a max() function
                Delta_RB = max(startRB(iBeacon2)-rbIndex, rbIndex-stopRB(iBeacon2));                
                % if rbIndex is within start-stop, then Delta_RB<=0 and
                % interference is set to 1
                if Delta_RB<=0
                    interference = interference + 1;
                else
                    % Interference calculation
                    % P_RB_dBm is fixed to the maximum, -30 dB, as per the
                    % NOTE 1 of 3GPP 36.101 (Table 6.5.2A.3.1-1)
                    P_RB_dBm = 0;
                    interferenceG_dB = max(max( -25-10*log10(N_RB_tot/L_CRB)-X,20*log10(EVM)-3-5*(abs(Delta_RB)-1)/L_CRB-W),(-57/180e3-P_RB_dBm-X)-30);
                    interferenceG = 10^( interferenceG_dB/10 );
                    %
                    % 2) IQ IMAGE
                    % Find the image of the rbIndex, looking at nRBperSubframeTot
                    rbImage = (N_RB_tot-(rbIndex)+1); 
                    if rbImage>=startRB(iBeacon2) && rbImage<=stopRB(iBeacon2)
                        interferenceIQ = 10^( (-25-Y)/10 ); 
                    else
                        interferenceIQ = 0;
                    end
                    %
                    % 3) CARRIER LEACKAGE
                    interferenceCL = 0;
                    if mod(N_RB_tot,2)==1 % ODD (TOT): one RB
                        if rbIndex==ceil(N_RB_tot/2)
                           interferenceCL = 10^( (-25-Z)/10 ); 
                        end  
                    else % EVEN (TOT): two RBs
                        if rbIndex==ceil(N_RB_tot/2)-1 || rbIndex==ceil(N_RB_tot/2)
                           interferenceCL = 10^( (-25-Z)/10 ); 
                        end  
                    end
                    % OPTION1: Maximum between the sum and P_RB_dBm-30
                    %interference = interference + max(10^((P_RB_dBm-30)/10),interferenceG+interferenceIQ+interferenceCL);
                    % OPTION2: Directly the sum
                    interference = interference + interferenceG+interferenceIQ+interferenceCL;
                    %%%% START PLOT2
    %                 if activePlots
    %                     if iBeacon2==1
    %                        int1Plot(rbIndex) = 10 * log10(interferenceG+interferenceIQ+interferenceCL);
    %                     end
    %                     if iBeacon2==2
    %                        int2Plot(rbIndex) = 10 * log10(interferenceG+interferenceIQ+interferenceCL);
    %                     end
    %                 end
                    %%%% STOP PLOT2
                end
            end    
            % Average over the allocated bandwidth
            %interference = interference/2; % the SCI occupies 2 RBs
            interference = interference/(stopRBcontrol(iBeacon1)-startRBcontrol(iBeacon1)+1);
            IBEmatrixControl(iBeacon1,iBeacon2) = interference;
        end
    end
end
%%

%%%% START PLOT2
% if activePlots
%     figure(102);
%     %plot(1:nRBperSubframeToAlloc,int1Plot,'ok');
%     plot(1:length(int1Plot),int1Plot,'ok-');
%     hold on
%     grid on
%     %plot(1:nRBperSubframeToAlloc,int2Plot,'pr');
%     plot(1:length(int2Plot),int2Plot,'pr-');
% end
%%%% STOP PLOT1

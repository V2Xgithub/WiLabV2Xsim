function [sinrManagement,X,Y,LOS] = computeChannelGain(sinrManagement,stationManagement,positionManagement,phyParams,simParams,dUpdate)
% Compute received power and create RXpower matrix

%% Initialization
distance = positionManagement.distanceReal;
Nvehicles = length(distance(:,1));   % Number of vehicles
LOS = ones(Nvehicles,Nvehicles);
if phyParams.channelModel>0 %~phyParams.winnerModel
    A = ones(Nvehicles,Nvehicles);  
end

%% Calculation of NLOSv
PNLOSv=10.^(0.69); %6.9 dB are assumed for each vehicle, following ETSI TR 103 257
if phyParams.channelModel==constants.CH_5G_NLOSV % 5G
    NLOSv = calculateNLOSv(positionManagement.XvehicleReal, positionManagement.YvehicleReal);
else
    NLOSv = zeros(Nvehicles,Nvehicles);  
end

%% Supplementary attenuation in the case of NLOS conditions
% If the MAP is not present, highway scenario is assumed; only LOS
% If the MAP is present, urban scenario is assumed and NLOS is calculated
if (~simParams.fileObstaclesMap)
    D_corr = 25;         % Decorrelation distance for the shadowing calculation
    [X,Y] = convertToGrid(positionManagement.XvehicleReal,positionManagement.YvehicleReal,positionManagement.XminMap,positionManagement.YmaxMap,positionManagement.StepMap);
    
    if simParams.typeOfScenario==constants.SCENARIO_URBAN  % ETSI-Urban
        D1 = zeros(Nvehicles,Nvehicles);
        C = zeros(Nvehicles,Nvehicles);
        horizontal=abs(real(positionManagement.direction));
        vertical=abs(imag(positionManagement.direction));
        D_corr = 10;         % Decorrelation distance for the shadowing calculation
        for i = 1:Nvehicles
            if positionManagement.XvehicleReal(i)~=Inf
                for j = i+1:Nvehicles
                    if positionManagement.XvehicleReal(j)~=Inf
                        
                        LOS(i,j)=horizontal(i)*horizontal(j)*(abs(positionManagement.YvehicleReal(i)-positionManagement.YvehicleReal(j))<20)+...
                            vertical(i)*vertical(j)*(abs(positionManagement.XvehicleReal(i)-positionManagement.XvehicleReal(j))<20)+...
                            horizontal(i)*vertical(j)*((abs(positionManagement.XvehicleReal(i)-positionManagement.XvehicleReal(j)))<10)*...
                            ((abs(positionManagement.YvehicleReal(j)-positionManagement.YvehicleReal(i)))<10)+...
                            vertical(i)*horizontal(j)*((abs(positionManagement.XvehicleReal(i)-positionManagement.XvehicleReal(j)))<10)*...
                            ((abs(positionManagement.YvehicleReal(j)-positionManagement.YvehicleReal(i)))<10);
                        LOS(j,i)=LOS(i,j);
                        D1(i,j)=horizontal(i)*(abs(positionManagement.XvehicleReal(i)-positionManagement.XvehicleReal(j)))+...
                            vertical(i)*(abs(positionManagement.YvehicleReal(i)-positionManagement.YvehicleReal(j)));
                        C(i,j)=vertical(i)*horizontal(j)+vertical(j)*horizontal(i); %crossing between i and j
                        
                    end
                end
            end
        end
        
    end
    
else
    D_corr = 10;           % Decorrelation distance for the shadowing calculation
    
    % Convert coordinates to grid
    [X,Y] = convertToGrid(positionManagement.XvehicleReal,positionManagement.YvehicleReal,positionManagement.XminMap,positionManagement.YmaxMap,positionManagement.StepMap);
    
    % Compute attenuation due to walls and buildings
    for i = 1:Nvehicles
        if positionManagement.XvehicleReal(i)~=Inf
            for j = i+1:Nvehicles
                if positionManagement.XvehicleReal(j)~=Inf
                    [Nwalls,Nsteps,granularity] = computeGrid(X(i),Y(i),X(j),Y(j),positionManagement.StepMap,positionManagement.GridMap,phyParams.channelModel);
                    if phyParams.channelModel==0 %phyParams.winnerModel
                        LOS(i,j) = 1-(Nwalls>0);
                        LOS(j,i) = LOS(i,j);
                    else
                        % in non-winner, the supplementary attenuation is
                        % calculated
                        A(i,j) = (phyParams.Awall^Nwalls)*(phyParams.Abuild^(Nsteps*granularity));
                        A(j,i) = A(i,j);
                    end
                end
            end
        end
    end
end

%% Path loss calculation
PLOS=( ...
    (distance<=phyParams.d_threshold1).*(phyParams.L0_near * (distance.^phyParams.b_near))+...
    (distance>phyParams.d_threshold1 & distance<=phyParams.d_threshold2).*(phyParams.L0_mid * (distance.^phyParams.b_mid))+...
    (distance>phyParams.d_threshold2) .*(phyParams.L0_far * (distance.^phyParams.b_far)) ...
    );

if simParams.typeOfScenario==constants.SCENARIO_URBAN % ETSI_Urban
    
    %% Path loss calculation for the Winner+ model
    k1=(phyParams.b_nj0.*max(phyParams.n_j0-phyParams.a_bj0*distance,phyParams.n_threshold))/10;
    q1=10.^(k1);
    Q1=PLOS.*phyParams.L0_NLOS_0.*q1.*...
        (distance'.^(max(phyParams.n_j0-phyParams.a_bj0*distance,phyParams.n_threshold)));
    Q2= PLOS.*phyParams.L0_NLOS_0.*10.^((phyParams.b_nj0.*max(phyParams.n_j0-phyParams.a_bj0*distance',phyParams.n_threshold))/10)*...%...
        (distance.^(max(phyParams.n_j0-phyParams.a_bj0*distance',phyParams.n_threshold)));
    PNLOS = min(Q1,Q2);
    
else
    
    PNLOS = phyParams.L0_NLOS * (distance.^phyParams.b_NLOS);
    
end

if phyParams.channelModel==constants.CH_WINNER_PLUS_B1 %phyParams.winnerModel
    PL = (LOS>0).*PLOS+(LOS==0).*PNLOS;
else
    % PL and LOS derivation in case of non-winner model
    %if phyParams.channelModel>0 %~phyParams.winnerModel
    PL = (PLOS./A).*(PNLOSv.^NLOSv);
    % In non-winner model, LOS was set to 1 not to modify the PL
    % Now LOS needs to be correctly set for the shadowing calculation
    % The values of the matrix A are 1 if LOS and higher than 1 if NLOS
    LOS = (A<=1);
end

%plot(distance,NLOSv,'p');

%% Compuatiomn of the channel gain
if phyParams.stdDevShadowLOS_dB ~= 0
    
    % Call function to calculate shadowing
    %Shadowing_dB = computeShadowing(sinrManagement.Shadowing_dB,LOS,dUpdate,phyParams.stdDevShadowLOS_dB,phyParams.stdDevShadowNLOS_dB,D_corr);
    %function [Shadowing_dB] = computeShadowing(Shadowing_dB,LOS,dUpdate,stdDevShadowLOS_dB,stdDevShadowNLOS_dB,D_corr)
    % Function that computes correlated shadowing samples w.r.t. the previous
    % time instant
    %Nv = length(dUpdate(:,1));                           % Number of vehicles
    
    % Generation of new samples of shadowing
    newShadowing_dB = randn(Nvehicles,Nvehicles).*(LOS*phyParams.stdDevShadowLOS_dB + (~LOS)*(phyParams.stdDevShadowNLOS_dB));
    
    % Calculation of correlated shadowing matrix
    newShadowingMatrix = exp(-dUpdate/D_corr).*sinrManagement.Shadowing_dB + sqrt( 1-exp(-2*dUpdate/D_corr) ).*newShadowing_dB;
    Shadowing_dB = triu(newShadowingMatrix,1)+triu(newShadowingMatrix)';
    
    Shadowing = 10.^(Shadowing_dB/10);
    
    % Compute channel gain with shadowing
    CHgain = Shadowing./PL;
    
else
    
    % Compute channel gain without shadowing
    CHgain = 1./PL;
    Shadowing_dB = zeros(Nvehicles,Nvehicles);
    
end

sinrManagement.Shadowing_dB = Shadowing_dB;

% Compute RXpower
% NOTE: sinrManagement.P_RX_MHz( RECEIVER, TRANSMITTER) 
sinrManagement.P_RX_MHz = ( (phyParams.P_ERP_MHz_CV2X(stationManagement.activeIDs).*(stationManagement.vehicleState(stationManagement.activeIDs)==100))' + ...
    (phyParams.P_ERP_MHz_11p(stationManagement.activeIDs).*(stationManagement.vehicleState(stationManagement.activeIDs)~=100) )' )...
    * phyParams.Gr .* (min(1,CHgain) .* sinrManagement.mcoCoefficient(stationManagement.activeIDs,stationManagement.activeIDs));

sinrManagement.P_RX_MHz_no_fading = sinrManagement.P_RX_MHz;

end
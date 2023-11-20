function [TBS,nRE,R,Qm] = findTBS_5G(RBperTBS,nDMRS,indexMCS,SCIsymbols,nRB_SCI,sizeSubchannel)
% Given the number of RB in total in the channel subChannelSize [#PRB], number of DMRS per RB, and index of MCS, returns the TBS in bits
% Admitted values for Channel Bandwidth are {5,10,15,20,25,30,40,50,60,70,80,90,100}
% Admitted values for SCS are {15,30,60}
% Admitted values for #DMRS are {12,15,18,21,24}
% Admitted values for the number of RB dedicated to the SCI-1 are [10,12,15,20,25]
% Admitted values for the number of symbols for the SCI-1 are [2,3]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%             TBS determination         %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%     Parameter initialization

% Fixed parameters
% From last specification (January 2021) the SCI-1 occupies a configurable
% amount of RB and symbols
% The SCI-2 has 2 formats, here format 2b
% TODO: Introduce possibility to choose SCI-2a and SCI-2b

% SCI1a = 64;                     % SCI-1A size in bits
% SCI2b = 72;                     % SCI-2B size in bits
% nResourceReservableSCI1 = 3;    % Number of reservable resources {2,3}, now only 3

nSubcarriersRB = 12;            % Number of subcarriers per RB

%%%%

% Possibly variable parameters
slLengthSLsymbols = 14;       % sl-lengthSLsymbols is the number of sidelink symbols within the slot provided by higher layers
nSymPSFCH = 0;                % Number of symbols for the PSFCH
nOverheadRB = 0;              % Number of symbols for the overhead per RB
nPRB=RBperTBS;                % Number of PRB considered for the PSSCH for which the TBS is evaluated
%nRB_SCI = 10;                % Number of PRB dedicated to the SCI-1
%%%%
 

%% IN-PUT checks
% input check on number of DMRS per resource block
if ~ismember(nDMRS, [12, 15, 18, 21, 24])
    error("wrong DMRS selection")
end

% input check on number of SCI symbols per Beacon Resource
if ~ismember(SCIsymbols, [2,3])
    error("wrong selection of number of SCI-1 symbols")
end

% input check on number of RBs per SCI-1
if ~ismember(nRB_SCI, [10, 12, 15, 20, 25])
    error("Error: wrong selection of nRB_SCI")
end

if nRB_SCI > sizeSubchannel
    error("Error: nRB_SCI must be smaller than the subchannel size")
end

%% Parameters that follow
nShSymbols = slLengthSLsymbols-2;        % Number of symbols dedicated to the shared channel

nRE1 = nSubcarriersRB*(nShSymbols-nSymPSFCH)-nOverheadRB-nDMRS;   % first step for the calculation of n RE for the shared channel
nRE2 = nRE1*nPRB;   % second step, in third step the RE used for SCI1 and SCI2 are subtracted

[Qm,R1024] = getMCS(indexMCS);      % Given the MCS index, gets the Modultion order, Coding Ratex1024

%

%% Rate Matching and SCI1 and SCI2 size determination

% Fixed parameters
OSci2 = 48;                 % Number of the 2nd-stage SCI bits
LSci2 = 24;                 % Number of CRC bits for the 2nd-stage SCI 
betaOffsetSci2 = 1.125;     % Parameter indicated in the corresponding 1st-stage SCI here we consider it 1.125
gamma = 0;                  % Number of vacant resource elements in the RB to which the last coded symbol of the 2nd-stage SCI belongs. It is set to 0 since we imagine to maximize the amount of information in the Subchannel
R =  R1024/1024;            % Coding rate as indicated by MCS field in SCI format 1-A.
alpha = 0.5;                % Parameter configured by higher layer parameter sl-Scaling.
QmSCI2 = Qm;                % Modulation order for SCI2 (as specified by Huawei in R1-2003871, meeting R1-101)


% Parameters that follow
MscPSSCH = nRE2;            % Scheduled bandwidth of PSSCH transmission, expressed as a number of subcarriers
MscDMRS = nDMRS*nPRB;       % Number of subcarriers that carry DMRS, in the PSSCH transmission
MscPTRS = 0;                % Number of subcarriers that carry PT-RS, in the PSSCH transmission

MscSCI2 = MscPSSCH-MscDMRS-MscPTRS; %number of RE that can be used for transmission of the 2nd-stage SCI 


% Rate Matching
QSCI2=min (ceil(((OSci2+LSci2)*betaOffsetSci2)/(QmSCI2*R)), ceil(alpha*MscSCI2))+gamma; % Number of coded modulation symbols generated for 2nd-stage SCI

nReSCI2b = QSCI2;       % is the number of coded modulation symbols generated for 2nd-stage SCI transmission
%nReSCI1a = SCI1a/2;   	% is the total number of REs occupied by the PSCCH and PSCCH DMRS. 1st stage is modulated with QPSK
nReSCI1a = SCIsymbols*nRB_SCI*12; % The SCI-1 occupies a fixed configurable amount of REs

nRE = nRE1*nPRB-nReSCI1a-nReSCI2b;  %nRE is the total amount of RE available for PSSCH


%% Ninfo determination

u=1;            %% Number of layers. Is related to MIMO, we consider it only 1

Ninfo = nRE*Qm*R*u;

%% Ninfo' determination and TBS determination
% as specified in 3GPP 38.214-g20 in section 5.3.2.1
% if Ninfo<=3824, TBS is determined by a table
% if Ninfo>3824, TBS is determined by  a formula

[TBS,~] = fTBS_5G(Ninfo,R);

end
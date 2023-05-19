classdef constants
    %The WiLabV2Xsim constants

  properties (Constant = true)
    %% ****************************************
	%% SIMULATOR RELATED

    SIM_VERSION = 'V6.2';


    %% ****************************************
	%% COMMON PHY PARAMETERS

    % BOLTZMANN CONSTANT (J/K)
    BOLTZMANN_CONSTANT = 1.38e-23;

    % REFERENCE TEMPERATURE (K)
    REFERENCE_TEMPERATURE = 290;

    % SPEED OF LIGHT (m/s)
    SPEED_OF_LIGHT = 3e8;

    %% ****************************************
	%% SCENARIO TYPE

    % Random speed and direction on multiple parallel roads, all configurable
    SCENARIO_PPP = 1;

    % Traffic traces
    SCENARIO_TRACE = 2;

    % ETSI Highway high speed scenario
    SCENARIO_HIGHWAY = 3;

    % ETSI URBAN scenario
    SCENARIO_URBAN = 4;

    %% ****************************************
	%% RADIO ACCESS TECHNOLOGY AND MODE

    % only have C-V2X
    TECH_ONLY_CV2X = 1;
    
    % only have IEEE 802.11p
    TECH_ONLY_11P = 2;

    % C-V2X + IEEE 802.11p, not interfering to each other
    TECH_COEX_NO_INTERF = 3;

    % C-V2X + IEEE 802.11p, interfering with standard protocols
    TECH_COEX_STD_INTERF = 4;

    % LTE mode
    MODE_LTE = 0;

    % 5G mode
    MODE_5G = 1;


    %% ****************************************
	%% COEXISTENCE MITIGATION METHODS

    % NO METHOD: default, standard protocols
    COEX_METHOD_NON = 0;

    % METHOD A: superframe, with a portion dedicated to LTE and the other to 11p
    COEX_METHOD_A = 1;

    % METHOD B: similar superframe, but energy signals used from LTE
    COEX_METHOD_B = 2;

    % METHOD C
    COEX_METHOD_C = 3;

    % METHOD D
    COEX_METHOD_D = 4;

    % METHOD E
    COEX_METHOD_E = 5;

    % METHOD F: similar superframe, but with NAV setting nodes
    COEX_METHOD_F = 6;

    % METHOD HAVE BEEN IMPLEMENTED (COEX_METHOD_NON NOT INCLUDED HERE)
    COEX_METHODS_IMPLEMENTED = [constants.COEX_METHOD_A,...
    constants.COEX_METHOD_B, constants.COEX_METHOD_C,...
    constants.COEX_METHOD_F];

    % METHOD A IMPROVEMENT: TOBE NAMED
    
    % COEXISTENCE SLOT MANAGEMENT
    COEX_SLOT_STATIC = 1;
    COEX_SLOT_DYNAMIC = 2;


    %% ****************************************
	%% IEEE 802.11P PHY LAYER

    % SLOT TIME [s]
    TIME_11P_SLOT_SEC = 13e-6;

    % SIFS TIME [s]
    TIME_11P_SIFS_SEC = 32e-6;

    % IMPLEMENT LOSS FOR AUTO SINR CALCULATION
    IMPLEMENTLOSS_11P = 0.37;


    %% ****************************************
	%% C-V2X PHY LAYER
    % To state simulator considering the In-Band Emission (IBE) or not
    % 1. have IBE
    IBE_TRUE = 1;

    % 2. only considering IBE during sensing mechanism
    IBE_ONLY_DURING_SENSING = 2;

    % 3. do not have IBE
    IBE_FALSE = 3;

    % IMPLEMENT LOSS FOR AUTO SINR CALCULATION
    IMPLEMENTLOSS_CV2X = 0.37;
    
    
    % BEACON RESOURCE ID, NEED TO CHECK THE MEANING OF -1, -2, AND -3
    BRID_ACTV_LTE_NO_RSRC = -1;

    BRID_NOT_LTE = -3;

    %% ****************************************
	%% LTE BR reassignment algorithm
    
    % CONTROLLED with REUSE DISTANCE and scheduled vehicles
    REASSIGN_BR_REUSE_DIS_SCHEDULED_VEH = 2;

    % CONTROLLED with MAXIMUM REUSE DISTANCE (MRD)
    REASSIGN_BR_MAX_REUSE_DIS = 7;

    % CONTROLLED with POWER CONTROL
    REASSIGN_BR_POW_CONTROL = 9;

    % CONTROLLED with MINIMUM REUSE POWER (MRP)
    REASSIGN_BR_MIN_REUSE_POW = 10;

    % AUTONOMOUS with SENSING (3GPP STANDARD MODE 4) - ON A SUBFRAME BASIS
    REASSIGN_BR_STD_MODE_4 = 18;
    
    % ***** this two Algorithms used as benchmarks *****
    % RANDOM ALLOCATION
    REASSIGN_BR_RAND_ALLOCATION = 101;

    % ORDERED ALLOCATION (following X coordinate)
    REASSIGN_BR_ORDERED_ALLOCATION = 102;
    % ***** this two Algorithms used as benchmarks *****
    

    %% ****************************************
	%% CHANNEL MODEL

    % WINNER+ B1 (3GPP specifications)
    CH_WINNER_PLUS_B1 = 0;

    % single slope model
    CH_SINGLE_SLOPE = 1;

    % two slopes model
    CH_TWO_SLOPES = 2;

    % three slopes model
    CH_THREE_SLOPES = 3;

    % 5G model which uses NLOSv model
    CH_5G_NLOSV = 4;


    %% ****************************************
	%% VEHICLE STATE

    % All vehicles in C-V2X (lte or 5g) are currently in the same state
    V_STATE_LTE_TXRX = 100;

    % the node has no packet and senses the medium as free
    V_STATE_11P_IDLE = 1;

    % the node has a packet to transmit and senses the medium as free;
    % it is thus performing the backoff
    V_STATE_11P_BACKOFF = 2;

    % the node is transmitting
    V_STATE_11P_TX = 3;

    % the node is sensing the medium as busy and possibly receiving
    % a packet (the sender it firstly sensed is saved in idFromWhichRx)
    V_STATE_11P_RX = 9;
   
    %% ****************************************
	%% PACKET

    % CAM
    PACKET_TYPE_CAM = 1;

    % DENM
    PACKET_TYPE_DENM = 2;

    % periodically generation interval
    PACKET_GENERATION_PERIODICALLY = 0;

    % ACCORDING TO ETSI CAM
    PACKET_GENERATION_ETSI_CAM = -1;


    %% ****************************************
	%% RETRANSMISSION TYPE
    % static: retransmit with a fix number of times
    RETRANS_STATIC = 0;

    % deterministic: retransmission times defined by a step function
    RETRANS_DETERMINISTIC = 1;

    % probabilistic: retransmission times defined by probability
    RETRANS_PROBABILISTIC = 2;

    %% ****************************************
	%% DEFAULT PARAMETERS



	end
end

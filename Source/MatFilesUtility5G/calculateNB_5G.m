function [appParams,phyParams] = calculateNB_5G(appParams,phyParams)
% compute NbeaconsF and NbeaconsT
% 5G doesn't have adjacent and non adjacent mode, since the SCI is carried along the transport block


% Find number of RBs per subchannel (or multiple)
phyParams.RBsBeaconSubchannel = phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel;

        
% Find number of beacons in the frequency domain (if subchannels can or cannot overlap)
    if phyParams.BRoverlapAllowed
        appParams.NbeaconsF = phyParams.NsubchannelsFrequency - phyParams.NsubchannelsBeacon + 1;
    else
        appParams.NbeaconsF = floor(appParams.RBsFrequencyV2V/(phyParams.RBsBeaconSubchannel));
    end

% Find number of beacons in the time domain
appParams.NbeaconsT = floor(appParams.allocationPeriod/phyParams.Tslot_NR);

end    
    
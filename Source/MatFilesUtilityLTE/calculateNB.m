function [appParams,phyParams] = calculateNB(appParams,phyParams)
% Compute NbeaconsF and NbeaconsT, subchannel sizes or multiples

% Depending on the subchannelization scheme: adjacent or non-adjacent PSCCH and PSSCH (TB + SCI)
if phyParams.ifAdjacent

    % Vector of supported subchannel sizes when adjacent (3GPP TS 36.331)
    phyParams.supportedSizeSubchannelAdjacent = [5 6 10 15 20 25 50 75 100];

    % Remove subchannel sizes exceeding the total number of RBs per Tslot
    phyParams.supportedSizeSubchannelAdjacent = phyParams.supportedSizeSubchannelAdjacent(phyParams.supportedSizeSubchannelAdjacent<=appParams.RBsFrequencyV2V);

    % Check whether the input sizeSubchannel is supported
    if isempty(find(phyParams.supportedSizeSubchannelAdjacent==phyParams.sizeSubchannel, 1)) && phyParams.sizeSubchannel~=-1
        error('Error: "phyParams.sizeSubchannel" must be -1 (best choice) or a supported value');
    end

    % Find RBs occupied by a beacon according to the subchannel size (adjacent case)
    % If a subchannel size is given by input
    if phyParams.sizeSubchannel ~= -1

        % Find number of subchannels in the frequency domain (Tslot)
        phyParams.NsubchannelsFrequency = floor(appParams.RBsFrequencyV2V/phyParams.sizeSubchannel);

        % Find number of subchannels in the frequency domain to carry a beacon + SCI (2 RBs)
        phyParams.NsubchannelsBeacon = -1;
        for i=1:phyParams.NsubchannelsFrequency
            multiple = i * phyParams.sizeSubchannel;
            while ~isValidForFFT(multiple - 2 * phyParams.ifAdjacent)
                multiple = multiple-1;
            end
            if multiple >= appParams.RBsBeacon/2+2
                phyParams.NsubchannelsBeacon = i;
                break;
            end
        end
        %phyParams.NsubchannelsBeacon = ceil((appParams.RBsBeacon/2+2)/phyParams.sizeSubchannel);

        % Find number of RBs per subchannel (or multiple)
        phyParams.RBsBeaconSubchannel = phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel;

    else

        % Call function to calculate all combinations of subchannels and multiples
        completeSizeSubchannelAdjacent = calculateSubchannelsCombinations(phyParams.supportedSizeSubchannelAdjacent,appParams.RBsFrequencyV2V,phyParams.ifAdjacent);

        % Find best combinations of subchannel size or multiple of the subchannel size
        % (must carry RBs per beacon per Tslot + 2 RB for adjacent SCI)
        suitableSizes = completeSizeSubchannelAdjacent(completeSizeSubchannelAdjacent(:,1)>=appParams.RBsBeacon/2+2,:);
        bestRBsValue = min(suitableSizes(:,1));

        % Find if there are multiple combinations
        combinations = suitableSizes(suitableSizes(:,1)==bestRBsValue,:);

        % Best choice when using adjacent SCI is the combination with the
        % smallest subchannel size (better discretization)
        [phyParams.sizeSubchannel, bestIndex] = min(combinations(:,2));
        phyParams.RBsBeaconSubchannel = combinations(bestIndex,1);
        phyParams.NsubchannelsBeacon = combinations(bestIndex,3);

         % Find number of subchannels in the frequency domain (Tslot)
        phyParams.NsubchannelsFrequency = floor(appParams.RBsFrequencyV2V/phyParams.sizeSubchannel);

    end

    % Find number of beacons in the frequency domain (adjacent case)
    if phyParams.BRoverlapAllowed
        appParams.NbeaconsF = phyParams.NsubchannelsFrequency - phyParams.NsubchannelsBeacon + 1;
    else
        appParams.NbeaconsF = floor(appParams.RBsFrequencyV2V/phyParams.RBsBeaconSubchannel);
    end
    
else

    % Vector of supported subchannel sizes when non-adjacent (3GPP TS 36.331)
    phyParams.supportedSizeSubchannelNonAdjacent = [4 5 6 8 9 10 12 15 16 18 20 30 48 72 96];

    % Remove subchannel sizes exceeding the total number of RBs per Tslot
    phyParams.supportedSizeSubchannelNonAdjacent = phyParams.supportedSizeSubchannelNonAdjacent(phyParams.supportedSizeSubchannelNonAdjacent<=appParams.RBsFrequencyV2V);

    % Check whether the input sizeSubchannel is supported
    if isempty(find(phyParams.supportedSizeSubchannelNonAdjacent==phyParams.sizeSubchannel, 1)) && phyParams.sizeSubchannel~=-1
        error('Error: "phyParams.sizeSubchannel" must be -1 (best choice) or a supported value');
    end

    % Find RBs occupied by a beacon according to the subchannel size (non-adjacent case)
    % If a subchannel size is given by input
    if phyParams.sizeSubchannel ~= -1

        % Find number of subchannels in the frequency domain (Tslot)
        phyParams.NsubchannelsFrequency = floor(appParams.RBsFrequencyV2V/(phyParams.sizeSubchannel+2));

        % Find number of subchannels in the frequency domain to carry a beacon
       phyParams.NsubchannelsBeacon = -1;
        for i=1:phyParams.NsubchannelsFrequency
            multiple = i * phyParams.sizeSubchannel;
            while ~isValidForFFT(multiple)
                multiple = multiple-1;
            end
            if multiple >= appParams.RBsBeacon/2
                phyParams.NsubchannelsBeacon = i;
                break;
            end
        end
        phyParams.NsubchannelsBeacon = ceil((appParams.RBsBeacon/2)/phyParams.sizeSubchannel);

        % Find number of RBs per subchannel (or multiple)
        phyParams.RBsBeaconSubchannel = phyParams.NsubchannelsBeacon*phyParams.sizeSubchannel;

    else

        % Call function to calculate all combinations of subchannels and multiples
        completeSizeSubchannelNonAdjacent = calculateSubchannelsCombinations(phyParams.supportedSizeSubchannelNonAdjacent,appParams.RBsFrequencyV2V,phyParams.ifAdjacent);

        % Find best combinations of subchannel size or multiple of the subchannel size
        % (must carry RBs per beacon per Tslot)
        suitableSizes = completeSizeSubchannelNonAdjacent(completeSizeSubchannelNonAdjacent(:,1)>=appParams.RBsBeacon/2,:);
        if isempty(suitableSizes)
            error('Error: "appParams.beaconSizeBytes" is too large for the selected MCS (packet cannot fit in a subframe)');
        end
        bestRBsValue = min(suitableSizes(:,1));

        % Find if there are multiple combinations (or even greater combinations with a margin of 2 RBs)
        combinations = suitableSizes(suitableSizes(:,1)<=bestRBsValue+2,:);

        % Best choice when using non-adjacent SCI is the combination with the
        % minimum number of subchannels per beacon (lower number of SCI)
        [phyParams.NsubchannelsBeacon, bestIndex] = min(combinations(:,3));
        phyParams.RBsBeaconSubchannel = combinations(bestIndex,1);
        phyParams.sizeSubchannel = combinations(bestIndex,2);

    end

    % Find number of subchannels in the frequency domain (Tslot)
    phyParams.NsubchannelsFrequency = floor(appParams.RBsFrequencyV2V/(phyParams.sizeSubchannel+2));

    % Find number of beacons in the frequency domain (non-adjacent case)
    if phyParams.BRoverlapAllowed
        appParams.NbeaconsF = phyParams.NsubchannelsFrequency - phyParams.NsubchannelsBeacon + 1;
    else
        appParams.NbeaconsF = floor(appParams.RBsFrequencyV2V/(phyParams.RBsBeaconSubchannel+2));
    end

end

% Find number of beacons in the time domain
appParams.NbeaconsT = floor(appParams.allocationPeriod/phyParams.Tsf);

end

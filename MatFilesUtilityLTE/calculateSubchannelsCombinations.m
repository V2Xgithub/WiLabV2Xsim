function completeSizeSubchannel = calculateSubchannelsCombinations(supportedSizeSubchannel,RBsFrequencyV2V,ifAdjacent)
% Function to calculate all combinations of subchannels

% Pre-allocate vector (better code performance)
% First column: RBs per subchannels or multiple
% Second column: subchannel size
% Third column: number of subchannels
completeSizeSubchannel = zeros(length(supportedSizeSubchannel)*(supportedSizeSubchannel(end)/supportedSizeSubchannel(1)),3);

% Complete vector of subchannel sizes with multiples up to the number of RBs per Tslot
k = 1;
for i = 1:length(supportedSizeSubchannel)
    n = 1;
    multiple = 0;
    while multiple<RBsFrequencyV2V
        multiple = supportedSizeSubchannel(i)*n;
        while ~isValidForFFT(multiple - 2 * ifAdjacent)
            multiple = multiple-1;
        end
        if ifAdjacent
            % If adjacent configuration is selected, SCI is included in the beacon size
            limit = RBsFrequencyV2V;
        else
            % If non-adjacent configuration is selected, SCI is always allocated in a separate pool
            limit = RBsFrequencyV2V - 2*n;
        end
        if multiple<=limit
            completeSizeSubchannel(k,1) = multiple;
            completeSizeSubchannel(k,2) = supportedSizeSubchannel(i);
            completeSizeSubchannel(k,3) = n;
            k = k+1;
        else
            break
        end
        n = n+1;
    end
end

% Delete zero values
delIndex = completeSizeSubchannel(:,1)==0;
completeSizeSubchannel(delIndex,:) = [];

end
function [phyParams] = deriveRanges(phyParams,simParams)
% Derive maximum awareness range and other ranges according to the selected algorithm

if simParams.technology ~= constants.TECH_ONLY_CV2X % not only C-V2X (lte or 5g) 
    phyParams.RawMaxLOS11p = ((phyParams.P_ERP_MHz_11p*phyParams.Gr)/(phyParams.sinrThreshold11p_LOS*phyParams.L0_far*phyParams.Pnoise_MHz))^(1/phyParams.b_far);
    phyParams.RawMaxNLOS11p = ((phyParams.P_ERP_MHz_11p*phyParams.Gr)/(phyParams.sinrThreshold11p_NLOS*phyParams.L0_NLOS*phyParams.Pnoise_MHz))^(1/phyParams.b_NLOS);
    % Compute maximum range with 2 times standard deviation of shadowing in LOS (m)
    phyParams.RawMax11p =  phyParams.RawMaxLOS11p * 10^((2*phyParams.stdDevShadowLOS_dB)/(10*phyParams.b_far));

%     %% =========
%     % Plot figs of related paper, could be commented in other case.
%     % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
%     % Only for IEEE 802.11p, highway scenario. 
%     if phyParams.RawMax11p < 1000
%         phyParams.RawMax11p = 1000;
%     end
%     %% =========

    if phyParams.Raw(end) > phyParams.RawMax11p
        error('Max Raw > RawMax11p not yet considered');
    %    fprintf('The awareness range exceeds the maximum possible one of 11p: ');
    %    phyParams.Raw = phyParams.RawMax11p;
    %    fprintf('set to %.0f m\n\n', phyParams.Raw);
    end
end

if simParams.technology ~= constants.TECH_ONLY_11P % not only 11p
    phyParams.RawMaxLOSCV2X = ((phyParams.P_ERP_MHz_CV2X*phyParams.Gr)/(phyParams.sinrThresholdCV2X_LOS*phyParams.L0_far*phyParams.Pnoise_MHz))^(1/phyParams.b_far);
    phyParams.RawMaxNLOSCV2X = ((phyParams.P_ERP_MHz_CV2X*phyParams.Gr)/(phyParams.sinrThresholdCV2X_NLOS*phyParams.L0_NLOS*phyParams.Pnoise_MHz))^(1/phyParams.b_NLOS);
    % Compute maximum range with 2 times standard deviation of shadowing in LOS (m)
    phyParams.RawMaxCV2X =  phyParams.RawMaxLOSCV2X * 10^((2*phyParams.stdDevShadowLOS_dB)/(10*phyParams.b_far));

    if phyParams.Raw(end) > phyParams.RawMaxCV2X
        error('Max Raw > RawMaxCV2X not yet considered');
    %    fprintf('The awareness range C-V2X exceeds the maximum possible one of C-V2X: ');
    %    phyParams.Raw = phyParams.RawMaxCV2X;
    %    fprintf('set to %.0f m\n\n', phyParams.Raw);
    end
    
    % R reuse for some allocation algorithms
    if simParams.BRAlgorithm==constants.REASSIGN_BR_REUSE_DIS_SCHEDULED_VEH
        % Compute minimum reuse distance (m)
        Rreuse1 = phyParams.Raw(end) + phyParams.Raw(end)/(((1/phyParams.sinrThresholdCV2X_LOS)-(phyParams.Pnoise_MHz/phyParams.P_ERP_MHz_CV2X)*(phyParams.L0_far*phyParams.Raw^phyParams.b_far)/phyParams.Gr)^(1/phyParams.b_far));
        RreuseMin = max([Rreuse1 2*phyParams.Raw(end)]);
        
        % Reuse distance (m)
        phyParams.Rreuse = RreuseMin + simParams.Mreuse;        
    end
    
end

end

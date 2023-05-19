function dis = getdis(d, prr, prr_thre)
%GETDIS get distance with prr > threshold
%   
i_prr = prr>prr_thre;
cross_points = [];
for i=1:length(i_prr)-1
    if i_prr(i) && ~i_prr(i+1)
        cross_points = [cross_points, i];
    end
end

switch length(cross_points)
    case 0      % no data larger than threshold
        dis = 0;
    case 1      % normal data
        dis = interp1(prr(cross_points:cross_points+1), d(cross_points:cross_points+1), prr_thre);
    otherwise   % fluctuation data
        dis = sum(d(cross_points))/length(cross_points);
end
        
    
    
end


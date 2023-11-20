function res = computeMinSegmentDistance(xA,yA,xB,yB,angA,angB,thresholdDistance,segmentLength)
% Function to compute if the minimum distance between two segments 
% is below a threshold
% Inputs: coordinates of one extreme of the first segment, coordinates of one 
% extreme of the second segment, angle of the first segment, angle of the
% second segment, threshold distance to check, length of the segments
% Output: boolean - true if below the threshold, false otherwise

% Position of A in the original reference axes
% Commented, since not used
%AXo = [xA xA+segmentLength*cos(angA)];
%AYo = [yA yA+segmentLength*sin(angA)];

% Position of A in the new reference axes
% Commented, since not used
%AXt = [thresholdDistance segmentLength+thresholdDistance];
%AYt = [thresholdDistance thresholdDistance];

% Position of B in the original reference axes
BXo = [xB xB+segmentLength*cos(angB)];
BYo = [yB yB+segmentLength*sin(angB)];

% Position of B in the new reference axes
BXt = ([cos(-angA) -sin(-angA)] * [(BXo-xA); (BYo-yA)]) + thresholdDistance;
BYt = ([sin(-angA) cos(-angA)] * [(BXo-xA); (BYo-yA)]) + thresholdDistance;
    
% Conditions:
% 1: Check if one of the two vertexes of the segment is inside the rectangle
if (BXt(1)>=thresholdDistance && BXt(1)<=segmentLength+2*thresholdDistance && BYt(1)>=0 && BYt(1)<=2*thresholdDistance) || ...
        (BXt(2)>=thresholdDistance && BXt(2)<=segmentLength+2*thresholdDistance && BYt(2)>=0 && BYt(2)<=2*thresholdDistance)
    % If the condition is true, the remaining code is skipped and true is returned
    res = true;
    return;
end

% 2: Check if the segment intersects one of the horizontal sides of the rectangle
% Angle coefficient
m = (BYt(2)-BYt(1))/(BXt(2)-BXt(1));
%intersH = [-q/m (2*M-q)/m];
intersH = [-BYt(1)/m+BXt(1) (2*thresholdDistance-BYt(1))/m+BXt(1) ];

if (BYt(1)*BYt(2)<0 && intersH(1)>=0 && intersH(1)<=segmentLength+2*thresholdDistance ) || ...
        ((BYt(1)-2*thresholdDistance)*(BYt(2)-2*thresholdDistance)<0 && intersH(2)>=0 && intersH(2)<=segmentLength+2*thresholdDistance)
    % If the condition is true, the remaining code is skipped and true is returned
    res = true;
    return;
end

% 3: Check if the segment intersects one of the vertical sides of the rectangle
%intersV = [q m*L+q];
intersV = [BYt(1)-m*BXt(1) m*(segmentLength+2*thresholdDistance)+BYt(1)-m*BXt(1)];

if ( BXt(1)*BXt(2)<0 && intersV(1)>=0 && intersV(1)<=2*thresholdDistance )  || ...
        ( (BXt(1)-(segmentLength+2*thresholdDistance))*(BXt(2)-(segmentLength+2*thresholdDistance))<0 && intersV(2)>=0 && intersV(2)<=2*thresholdDistance )
    % If the condition is true, the remaining code is skipped and true is returned
    res = true;
    return;
end

% If none of the three condition is true, the minimum distance between points 
% of the two segments is not below 'thresholdDistance'
res = false;

end




function NLOSv = calculateNLOSv(X, Y)
% function calculateNLOSv
%
% Inputs
% X: column vector with the x-position of the vehicles
% Y: column vector with the y-position of the vehicles
% (the number of vehicles is inferred from the length of X)
%
% Outputs
% NLOSv: squared matrix of size equal to the number of vehicels, indicating 
% how many vehicles obstruct the line of sight of the vehicles
% correpsonding to the given row and column
% (the matrix is always symmetric to the main diagonal, with zeros on the
% main diagonal)

%% INIT
% The number of vehicles is derived from the length of X
Nvehicles = length(X);

% % For debug
% figure
% plot(X,Y,'p');
% axis([min(X)-100 max(X)+100 min(Y)-100 max(Y)+100]);

% Parameter that defines the size of the obstructing vehicle
% The obstructing vehicle is approximated for this purpose as a circle of
% radius thresholdDistance
thresholdDistance = 1.5;

% X1,Y1 are the coordinates of the first vehicle and X2,Y2 those of the
% second vehicle which are communicating to each other
X1 = repmat(X',length(X),1);
X2 = repmat(X,1,length(X));
Y1 = repmat(Y',length(Y),1);
Y2 = repmat(Y,1,length(Y));

% m, q define the rect connecting the two vehicles that are communicating
m = (Y2-Y1)./(X2-X1);
q = Y2-m.*X2;

% m_perp defines the angle of the rect perpendicular to the one connecting
% the two vehciles that are communicating
m_perp = -1./m;

%% CALCULATION OF NLOSv
% Per each vehicle, if it obstructs the possible connection is calculated
% and then NLOSv updated accordingly
NLOSv = zeros(Nvehicles,Nvehicles); % initialization of NLOSv
for i = 1:Nvehicles    
    % X_obstructing,Y_obstructing are the coordinates of the possibly obstructing vehicle
    X_obstructing = X(i);
    Y_obstructing = Y(i);
    % q_perp defines the rect perpendicular to the segment that is possibly
    % obstructed and that goes through X_obstructing,Y_obstructing
    q_perp = Y_obstructing - m_perp * X_obstructing;
    % dist is the distance between the obstructing vehicle and the rect of
    % the obstructed segment
    dist = abs(Y_obstructing-(m.*X_obstructing+q))./sqrt(1+m.*m);
    % if m is infinite, it means the segment is vertical
    dist(isinf(m)) = abs(X_obstructing-X1(isinf(m)));
    % the distance from the obstracting point and any segment strating from
    % itself is set to infinite to mark that there is no obstruction
    dist(i,:)=inf;
    dist(:,i)=inf;
    % x_projected,y_projected are the coordinates of the projection of the point 
    % X_obstructing,Y_obstructing over the segment
    % They are needed to check that they are inside the segment
    x_projected = (q_perp-q)./(m+1./m);
    x_projected(m==0) = X_obstructing;
    y_projected = m.*x_projected + q;
    y_projected(isinf(m)) = Y_obstructing;
%     yp2 = mp.*xp + qp;
%     diff = yp-yp2;
%     if max(abs(yp-yp2))>1e-3
%         error('Noooo');
%     end
    % outOfSegment defines if the projection of X_obstructing,Y_obstructing
    % is out of the segment; in such a case, in fact, it will not obstruct
    % the communication, no matter dist
    outOfSegment = ((x_projected<X1 & x_projected<X2) | (x_projected>X1 & x_projected>X2)) | ...
        ((y_projected<Y1 & y_projected<Y2) | (y_projected>Y1 & y_projected>Y2));
    itObstructs = (dist < thresholdDistance) .* (1-outOfSegment);
    % NLOSv is updtaed to include all the cases when vehicle i obstructs the communication
    % Note that itObstructs is a matrix with the same size of NLOSv, with
    % values that are either 0 (it does not obstruct) or 1 (it obstructs)
    NLOSv = NLOSv + itObstructs;   
end

function matrix = counterTX(IDvehicleTX,indexVehicleTX,awarenessID,correctList)
% Count correctly transmitted beacons among neighbors within Raw
% Matrix = [#Correctly transmitted beacons, #Errors, #Neighbors]

Ntx = length(indexVehicleTX);
matrix = zeros(Ntx,3);
for i = 1:Ntx

    % #Neighbors of TX vehicle IDvehicleTX(i)
    Nneighbors = nnz(awarenessID(indexVehicleTX(i),:));
    matrix(i,3) = Nneighbors;
    
% From v 5.4.14
%     % #Neighbors that do not have correctly received the beacon
%     Nerrors = nnz(errorMatrix(:,1)==IDvehicleTX(i));
%     matrix(i,2) = Nerrors;
% 
%     % #Neighbors that have correctly received the beacon transmitted by IDvehicleTX(i)
%     matrix(i,1) = Nneighbors - Nerrors;
   
    % #Neighbors that have correctly received the beacon transmitted by IDvehicleTX(i)
    Ncorrect = nnz(correctList(:,1)==IDvehicleTX(i));
    matrix(i,1) = Ncorrect;

    % #Neighbors that do not have correctly received the beacon
    matrix(i,2) = Nneighbors - Ncorrect;

end


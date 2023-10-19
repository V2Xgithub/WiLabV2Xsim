function [BRGraphStruct] = BRGraphUpdate(args)
    arguments
        args.BRGraphStruct;
        args.br_to_vehicle_mapping;
    end
%BRGRAPHUPDATE Summary of this function goes here
%   Detailed explanation goes here
% reset everything to 0 first
colors = [[254 229 217]; [252 174 145]; [251 106 74]; [225 45 38]; [165 15 21]];
for BRid=1:numel(args.br_to_vehicle_mapping)
   i_T = mod(BRid, size(args.BRGraphStruct.brVehicleAssignmentLabels, 1));
   if i_T == 0
       i_T = 100;
   end
   j_F = floor(BRid / size(args.BRGraphStruct.brVehicleAssignmentLabels, 1)) + 1;
   vehicles_using_this_br = str2num(args.br_to_vehicle_mapping(BRid));
   vehicles_using_this_br = setdiff(vehicles_using_this_br, args.BRGraphStruct.hiddenVehicles);
   if isempty(vehicles_using_this_br)
       args.BRGraphStruct.brVehicleAssignmentLabels{i_T, j_F}.String = "";
       args.BRGraphStruct.brRectangles{i_T, j_F}.FaceColor = "none";
   else
       number_of_vehicles = length(vehicles_using_this_br);
       args.BRGraphStruct.brVehicleAssignmentLabels{i_T, j_F}.String = sprintf('%.0f\n' , vehicles_using_this_br);
       args.BRGraphStruct.brRectangles{i_T, j_F}.FaceColor = colors(min(number_of_vehicles, 5),:) ./ 255;
   end
end
BRGraphStruct = args.BRGraphStruct;
end


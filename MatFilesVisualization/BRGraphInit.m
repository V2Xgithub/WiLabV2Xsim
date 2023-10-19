function [BRGraphStruct] = BRGraphInit(args)
    arguments
        args.NbeaconsT (1, 1) double;
        args.NbeaconsF (1, 1) double;
        args.Tslot_NR (1, 1) double;
        args.RBsFrequencyV2V (1, 1) double;
        args.axes (1, 1) matlab.graphics.axis.Axes;
    end
%BRGRAPHINIT Summary of this function goes here
%   Detailed explanation goes here
BRGraphStruct = struct;
F_min = 0;
F_max = args.RBsFrequencyV2V;
T_min = 0;
T_max = args.NbeaconsT * args.Tslot_NR;
args.axes.XLim = [T_min,T_max];
args.axes.YLim = [F_min,F_max];
args.axes.Title.String = "BR Allocations";
args.axes.XLabel.String = "Time Domain (s)";
args.axes.YLabel.String = "Frequency Domain (MHz)";
BRGraphStruct.brRectangles = cell(args.NbeaconsT, args.NbeaconsF);
BRGraphStruct.brIdLabels = cell(args.NbeaconsT, args.NbeaconsF);
BRGraphStruct.brVehicleAssignmentLabels = cell(args.NbeaconsT, args.NbeaconsF);
BRGraphStruct.hiddenVehicles = [];
% Draw the boxes, and their corresponding labels
F_step = (F_max - F_min)/args.NbeaconsF;
T_step = args.Tslot_NR;
for i_T = 1:args.NbeaconsT
    for j_F = 1:args.NbeaconsF
        rect_x = T_min + (T_step * (i_T - 1));
        rect_y = F_min + (F_step * (j_F - 1));
        BRGraphStruct.brRectangles{i_T, j_F} = rectangle(args.axes, "Position", [rect_x rect_y T_step F_step]);
        BRGraphStruct.brIdLabels{i_T, j_F} = text(args.axes, rect_x, rect_y, string(((j_F - 1) * args.NbeaconsT) + i_T), "FontSize", 6, "Clipping", "on", "VerticalAlignment","bottom");
        BRGraphStruct.brVehicleAssignmentLabels{i_T, j_F} = text(args.axes, rect_x + (T_step/2), rect_y + (F_step/2), "", "Clipping", "on", "VerticalAlignment", "middle", "HorizontalAlignment", "center");
    end
end
% Label the boxes

end


function [indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,IDvehicleExit,positionManagement] = updatePosition(time,IDvehicle,v,direction,updateInterval,Xmax,positionManagement,appParams,simValues,outParams,simParams)
% Update vehicles position (when not using File Trace)
% (if a vehicle moves outside the scenario, enters by the other side)

Xvehicle = positionManagement.XvehicleReal;
Yvehicle = positionManagement.YvehicleReal;

if simParams.roadLength==0
    % When testing all vehicles co-located, no position update
    return
end


if ~isreal(Xmax)%ETSI-Urban
    directionX=real(direction);
    directionY=imag(direction);
    maxX=real(Xmax);
    maxY=imag(Xmax);
    
    
    vel=directionY.*v.*[0,1]+directionX.*v.*[1,0];
    directionN=directionX+directionY;
    pos_tot=[Xvehicle,Yvehicle];
    veh_speed_metsec=max(abs(vel(:)));  %absolute value of the speed in m/s
    speed_h=[veh_speed_metsec,0]; %speed of vehicles on horizontal lanes
    speed_v=[0,veh_speed_metsec]; %speed of vehicles on vertical lanes
    block_dim=[250, 433];
    horizontal=(vel(:,2)==0); % flags vehicles on horizontal lanes
    vertical=(vel(:,1)==0);   % flags vehicles on vertical lanes
    
    
    pos_totI=pos_tot+updateInterval.*vel;
    pos_tot2=pos_totI;
    
    
    delta=updateInterval.*veh_speed_metsec; % distance covered during an updateInterval
    
    crossx=block_dim(1).*(vel(:,1)>0).*ceil(pos_tot(:,1)/block_dim(1))+...
        block_dim(1).*(vel(:,1)<0).*floor(pos_tot(:,1)/block_dim(1))+...
        block_dim(2).*(vel(:,2)>0).*ceil(pos_tot(:,2)/block_dim(2))+...
        block_dim(2).*(vel(:,2)<0).*floor(pos_tot(:,2)/block_dim(2));
    crossx2=block_dim(1).*(vel(:,1)>0).*ceil(pos_tot2(:,1)/block_dim(1))+...
        block_dim(1).*(vel(:,1)<0).*floor(pos_tot2(:,1)/block_dim(1))+...
        block_dim(2).*(vel(:,2)>0).*ceil(pos_tot2(:,2)/block_dim(2))+...
        block_dim(2).*(vel(:,2)<0).*floor(pos_tot2(:,2)/block_dim(2));%Flag vehicles close to a crossing point
    flag_cross=find(crossx~=crossx2);
    change_dir=datasample([0,0,-1,1],length(flag_cross))';%datasample([0,0,-1,1],length(flag_cross))';% change of the direction at the crossing point: 1 left, -1 right, 0 straight
    F=flag_cross;
    changes=zeros(size(directionN));
    changes(F)=change_dir;
    
    
    %Update speed and direction based on any direction change of vehicles at
    %crossing points
    direction2=directionN(:);
    v2=vel;
    direction2(F)=(changes(F)==0).*directionN(F)+...
        horizontal(F).*(changes(F)~=0).*directionN(F).*change_dir...
        -vertical(F).*(change_dir~=0).*directionN(F).*change_dir;
    v2(F,:)=(change_dir==0).*vel(F,:)+(change_dir~=0).*(horizontal(F).*direction2(F).*speed_v+vertical(F).*direction2(F).*speed_h);
    
    %Update position of vehicles that changed direction
    x_cross_closest=round(pos_tot(:,1)/block_dim(1)).*block_dim(1);
    y_cross_closest=round(pos_tot(:,2)/block_dim(2)).*block_dim(2);
    
    pos_tot2=pos_totI;
    F=find(changes~=0);
    if (~isempty(F))
        
        F2=find((changes~=0).*horizontal);
        pos_tot2(F2,1)=(x_cross_closest(F2)+changes(F2).*(y_cross_closest(F2)-pos_totI(F2,2)));
        pos_tot2(F2,2)=(pos_totI(F2,2)+direction2(F2).*(delta-abs(x_cross_closest(F2)-pos_totI(F2,1))));
        
        F3=find((changes~=0).*vertical);
        pos_tot2(F3,1)=(pos_totI(F3,1)+direction2(F3).*(delta-(y_cross_closest(F3)-pos_totI(F3,2))));
        pos_tot2(F3,2)=(y_cross_closest(F3)-changes(F3).*(x_cross_closest(F3)-pos_totI(F3,1)));
        % %
        
        %
        %     pos_totI=pos_tot2;
    end
    horizontal(F)=(v2(F,2)==0); % flags vehicles on horizontal lanes
    vertical(F)=(v2(F,1)==0);   % flags vehicles on vertical lanes
    pos_totI=pos_tot2;
    
    %Checking what happens at the corners
    
    %No corners
    F1=find((pos_totI(:,2)>0).*(pos_totI(:,2)<=maxY).*(pos_totI(:,1)>0).*(pos_totI(:,1)<=maxX));
    pos_tot2(F1,:)=pos_totI(F1,:);
    
    %Left the admitted area
    F2=find(horizontal.*(direction2<0).*(pos_totI(:,1)<0));
    pos_tot2(F2,1)=(maxX-abs(pos_totI(F2,1)));
    
    %Below the admitted area
    F2=find(vertical.*(direction2<0).*(pos_totI(:,2)<0));
    pos_tot2(F2,2)=(maxY-abs(pos_totI(F2,2)));
    
    %Right of the admitted area
    F2=find(horizontal.*(direction2>0).*(pos_totI(:,1)>maxX));
    pos_tot2(F2,1)=pos_totI(F2,1)-maxX;
    
    %Above the admitted area
    F2=find(vertical.*(direction2>0).*(pos_totI(:,2)>maxY));
    pos_tot2(F2,2)=pos_totI(F2,2)-maxY;
    
    %Wrong corners
    F3=find(horizontal.*(direction2>0).*(pos_totI(:,2)<0));
    pos_tot2(F3,1)=max(pos_totI(F3,1)-maxX,0);
    pos_tot2(F3,2)=maxY+pos_totI(F3,2);
    
    F3=find(vertical.*(direction2<0).*(pos_totI(:,1)<0));
    pos_tot2(F3,1)=maxX+pos_totI(F3,1);
    pos_tot2(F3,2)=min(pos_totI(F3,2)+maxY,maxY);
    
    F3=find(horizontal.*(direction2<0).*(pos_totI(:,2)>maxY));
    pos_tot2(F3,1)=pos_totI(F3,1);%min(pos_totI(F3,1)+maxX,maxX);
    pos_tot2(F3,2)=pos_totI(F3,2)-maxY;
    
    F3=find(vertical.*(direction2>0).*(pos_totI(:,1)>maxX));
    pos_tot2(F3,1)=pos_totI(F3,1)-maxX;%max(pos_totI(F3,1)-maxX,0);
    pos_tot2(F3,2)=max(pos_totI(F3,2)-maxY,0);
    
    
    direction(horizontal)=direction2(horizontal);
    direction(vertical)=1i.*direction2(vertical);
    positionManagement.direction=direction;
    
    %Update  position for the output
    Xvehicle=pos_tot2(:,1);
    Yvehicle=pos_tot2(:,2);
    
    % Return indices
    indexNewVehicles = [];
    indexOldVehicles = IDvehicle;
    indexOldVehiclesToOld = IDvehicle;
    IDvehicleExit = [];
    
else
    
    
    
    Xvehicle = (~direction).*mod(Xvehicle + v*updateInterval,Xmax) + direction.*mod(Xvehicle - v*updateInterval,Xmax);
    % if simParams.mco_nVehInterf>0
    %     positionManagement.mco_interfXvehicle = (~positionManagement.mco_interfDirection).*mod(positionManagement.mco_interfXvehicle + positionManagement.mco_interfVvehicle * updateInterval,Xmax) + positionManagement.mco_interfDirection.*mod(positionManagement.mco_interfXvehicle - positionManagement.mco_interfVvehicle*updateInterval,Xmax);
    % end
    
    
    % Return indices
    indexNewVehicles = [];
    indexOldVehicles = IDvehicle;
    indexOldVehiclesToOld = IDvehicle;
    IDvehicleExit = [];
    
    
end
positionManagement.XvehicleReal = Xvehicle;
positionManagement.YvehicleReal = Yvehicle;

% Print speed (if enabled)
if outParams.printSpeed
    printSpeedToFile(time,IDvehicle,v,simValues.maxID,outParams);
end
end
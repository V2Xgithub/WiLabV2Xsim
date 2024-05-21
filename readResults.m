% read packet status data

% get database path
dbFilePath = fullfile(fileparts(mfilename('fullpath')), "Output", "NRV2X", "rho100_v_km", "resuts_1.db");
tableName = 'PacketStatusDetail';
% table fields
% [time, TxID, RxID, BRID, distance, packet_status(1:correct, 0:error)]

% link to the database
conn = sqlite(dbFilePath,"readonly");

% read data between 0 and 1 seconds
startTime = 0;
endTime = 0.1;

% example1
sqlquery = sprintf("select * from %s where time > %f and time < %f", tableName, startTime, endTime);
partData1 = fetch(conn,sqlquery);

% example2
sqlquery = sprintf("select * from PacketStatusDetail where time < 0.1 and TxID = 206 and packet_status = 1");
partData2 = fetch(conn, sqlquery);

close(conn);

function outParams = connectLiteSQL(outParams)
%CONNECTLITESQL connect to LiteSQL for logging results

%% Setup dbfile
dbfile = fullfile(outParams.outputFolder, sprintf("resuts_%d.db", outParams.simID));
if isfile(dbfile)
    % delete if the old database exist
    delete(dbfile);
end
outParams.conn = sqlite(dbfile,"create");


%% Create tables

% Table PacketStatusDetail
% [time, TxID, RxID, BRID, distance, packet_status(1:correct, 0:error)]
sqlquery = strcat("CREATE TABLE PacketStatusDetail(time numeric, ", ...
    "TxID INT, RxID INT, BRID INT, distance numeric, packet_status INT)");
execute(outParams.conn,sqlquery)

end


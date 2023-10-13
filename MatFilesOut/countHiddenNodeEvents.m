function hiddenNodeEvents = countHiddenNodeEvents(args)
    arguments
        args.errorRxList (:, 5) double
        args.awarenessIDLTE (:, :) double {mustBeInteger}
        args.BRid (1, :) double {mustBeInteger}
        args.NbeaconsT double {mustBeInteger}
        args.duplexCV2X string
    end
    errorRxList = args.errorRxList;
    hiddenNodeEvents = 0;
    for error_rx_list_i = 1:size(errorRxList, 1)
        tx = errorRxList(error_rx_list_i, 1);
        rx = errorRxList(error_rx_list_i, 2);
        tx_brid = errorRxList(error_rx_list_i, 3);
        % Find who else is within rx's awareness range
        rx_neighbors = setdiff(nonzeros(args.awarenessIDLTE(rx,:)), tx);
        if args.duplexCV2X == "HD"
            % If half duplex, the interferers are the rx's neighbors
            % using the same BRT
            tx_bridT = mod(tx_brid, args.NbeaconsT);
            ix = rx_neighbors(mod(args.BRid(rx_neighbors), args.NbeaconsT) == tx_bridT);
        else
            % If full duplex, the interferers are the rx's neighbors
            % using the exact same BR
            ix = rx_neighbors(args.BRid(rx_neighbors) == tx_brid);
        end
        % If the ix is not within tx's awareness range, is hidden node
        hiddenNodeEvents = hiddenNodeEvents + nnz(~ismember(ix, args.awarenessIDLTE(tx, :)));
    end
end

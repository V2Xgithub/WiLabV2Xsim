function tests = test_countHiddenNodeEvents
tests = functiontests(localfunctions);
end

function testSimpleCaseHDSameBRF(testCase)
% test the simple case in HD mode where there is only one BRF
% let 1 be tx, 2 be rx, 3 be interferer
% let the BRid in contention be 9
errorRxList = [1 2 9 100 0];
% 1 can see 2, cannot see 3
% 2 can see 1 and 3
% 3 can only see 2
awarenessIDLTE = [
    2 0 0;
    1 3 0;
    2 0 0;
    ];
% 1 and 3 share the same BR, don't care about 2
BRid = [9 -1 9];
actual = countHiddenNodeEvents(errorRxList=errorRxList, awarenessIDLTE=awarenessIDLTE, BRid=BRid, NbeaconsT=100, duplexCV2X="HD");
expected = 1;
verifyEqual(testCase, actual, expected);
end

function testCaseHDSameBRTDiffBRF(testCase)
% a slightly more complex case, test if the tx and ix are in the same BRT,
% even if diff BRF, in HD mode we consider this hidden node
% let 1 be tx, 2 be rx, 3 be interferer
% let the BRid in contention be 9
errorRxList = [1 2 9 100 0];
% 1 can see 2, cannot see 3
% 2 can see 1 and 3
% 3 can only see 2
awarenessIDLTE = [
    2 0 0;
    1 3 0;
    2 0 0;
    ];
% 1 and 3 share the same BRT but diff BRF, don't care about 2
BRid = [3 -1 9];
NbeaconsT = 3;
actual = countHiddenNodeEvents(errorRxList=errorRxList, awarenessIDLTE=awarenessIDLTE, BRid=BRid, NbeaconsT=NbeaconsT, duplexCV2X="HD");
expected = 1;
verifyEqual(testCase, actual, expected);
end

function testCaseFDSameBRTSameBRF(testCase)
% in FD mode, tx and ix must be sharing the same BRT and BRF
% let 1 be tx, 2 be rx, 3 be interferer
% let the BRid in contention be 9
errorRxList = [1 2 9 100 0];
% 1 can see 2, cannot see 3
% 2 can see 1 and 3
% 3 can only see 2
awarenessIDLTE = [
    2 0 0;
    1 3 0;
    2 0 0;
    ];
% 1 and 3 share the same BRT and same BRF, don't care about 2
BRid = [9 -1 9];
NbeaconsT = 3;
actual = countHiddenNodeEvents(errorRxList=errorRxList, awarenessIDLTE=awarenessIDLTE, BRid=BRid, NbeaconsT=NbeaconsT, duplexCV2X="FD");
expected = 1;
verifyEqual(testCase, actual, expected);
end


# Output File Format Description
## 1. printCBR

-> **CBRofGenericVehicle_*.xls**

The CBR values sensed by one (generic) vehicle during the whole simulation (excluding the time interval at beginning)
|Simulation time [s] | Channel Busy Ratio |
|---|---|
|1.1|0.21|
|1.2|0.23|

-> **CBRstatistic_*.xls**

The CDF of all CBRs values sensed by all vehicles during the whole simulation (excluding the time interval at beginning)

| Channel Busy Ratio | CDF |
|---|---|
|0.04|0.000469|
|0.05|0.000939|

## 2. printDataAge
e.g. awareness range (Raw) = [50, 150, 300 m]

-> **data_age_*.xls**
counting the data age

|data age [s] | #pkt (0~50) | CDF (0~50) |#pkt (50~150) | CDF (50~150) |#pkt (150~300) | CDF (150~300) |
|---|---|---|---|---|---|---|
|0.101|26|0.001343|78|0.001674|59|0.000945|163|0.00127|
|0.102|95|0.00625|300|0.008114|495|0.008878|890|0.008204|


## 3. printPacketDelay
e.g. awareness range (Raw) = [50, 150, 300 m]

-> **packet_delay_*.xls**
|packet delay [s] | #pkt (0~50) | CDF (0~50) |#pkt (50~150) | CDF (50~150) |#pkt (150~300) | CDF (150~300) |
|---|---|---|---|---|---|---|
|0.001|32|0.001506|89|0.001889|66|0.001046|187|0.001422|
|0.002|109|0.006635|306|0.008383|511|0.009142|926|0.008465|

## 4. printPacketReceptionRatio
e.g. awareness range (Raw) = [50, 150, 300 m]

-> **packet_reception_ratio_*.xls**

|distance [m] | (2) Num OK | (3) Num error | (4) Num blocked | (5) total packets (2)+(3)+(4)| PRR (2)/(5)|
|---|---|---|---|---|---|
|10|1625|0|0|1625|1|
|20|6135|20|1|6156|0.996589|
|30|4709|33|1|4743|0.992832|

## 5. printUpdateDelay
e.g. awareness range (Raw) = [50, 150, 300 m]

-> **update_delay_*.xls**
|update delay[s]| #pkt (0~50) | CDF (0~50) |#pkt (50~150) | CDF (50~150) |#pkt (150~300) | CDF (150~300) | #pkt [0~300 m] | CDF [0~300 m]|
|---|---|---|---|---|---|---|---|---|
|0.006|4|0.000207|3|0.000064|2|0.000032|9|0.00007|
|0.007|0|0.000207|0|0.000064|0|0.000032|0|0.00007|

## 6. printWirelessBlindSpotProb
e.g. awareness range (Raw) = [50, 150, 300 m]

-> **wireless_blind_spot_*.xls**

|time interval (TI) [s]|(2) #event, delay >= TI (0~50)|(3) #event, delay < TI (0~50)|ratio (2)/((2)+(3))|(5) #event, delay >= TI (50~150)|(6) #event, delay < TI (50~150)|ratio (5)/((5)+(6)) |(8) #event, delay >= TI (150~300)|(9) #event, delay < TI (150~300)|ratio (8)/((8)+(9))|
|---|---|---|---|---|---|---|---|---|---|
|0.1|279|20825|0.01322|1258|66982|0.018435|5730|128902|0.04256|
|0.2|55|21049|0.002606|450|67790|0.006594|3280|131352|0.024363|





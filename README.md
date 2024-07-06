# WiLabV2Xsim

We are uploading the simulator...some supporting documents could be found in the [Wiki Page](https://github.com/V2Xgithub/WiLabV2Xsim/wiki) and others may not be updated...
For Octave compatible version, please see branch ***Octave-version***

***WiLabV2Xsim*** is a dynamic simulator, written in MATLAB, overhauling LTEV2Vsim (see https://github.com/alessandrobazzi/LTEV2Vsim) to support sidelink 5G-V2X. 
It is designed for the investigation of resource allocation in networks based on ***sidelink C-V2X***, with focus on the cooperative awareness service, but it also allows to simulate ***IEEE 802.11p/ITS-G5***.

The simulator is shared under the GNU GPLv3. The software has been developed and shared by University of Bologna, CNR, and WiLab/CNIT - Italy. 

The first release of this simulator is version 6.1 to remark the continuity with LTEV2Xsim, of which the last shared version was 5.4.

From version 5.4 to version 6.1 the main modification is the addition of 5G-V2X, with NR and all the related settings (including numerology). A general refactoring was performed to generalize the parameters which are common for LTE and 5G, now indicated as CV2X. Minor corrections and improvements were also performed. 

NOTICE: The code runs correctly with Matlab versions from 2021b at least.
There are problems with version 2016b and earlier. With the versions in between, some minor corrections would be required (we haven't checked all the versions).
The Statistics and Machine Learning Toolbox™ is needed for the simulation and generation of 3GPP a-periodic traffic.

The main reference for the simulator is 

***V. Todisco, S. Bartoletti, C. Campolo, A. Molinaro, A. O. Berthet, andA.  Bazzi,  “Performance  analysis  of  sidelink  5G-V2X  mode  2  through an  open-source  simulator,” IEEE Access,  2021***, open access at https://ieeexplore.ieee.org/abstract/document/9579000 

The main references for the previous versions of the simulator are 

G. Cecchini, A. Bazzi, B. M. Masini, A. Zanella, “LTEV2Vsim: An LTE-V2V Simulator for the Investigation of Resource Allocation for Cooperative Awareness”, 5th IEEE International Conference on Models and Technologies for Intelligent Transportation Systems (MT-ITS 2017), Naples (Italy), 26-28 June 2017. (Results obtained with version 1.0)

A. Bazzi, G. Cecchini, M. Menarini, B. M. Masini, A. Zanella, “Survey and Perspectives of Vehicular Wi-Fi Versus Sidelink Cellular-V2X in the 5G Era,” invited paper in Future Internet, 29 May 2019, 11(6), 122. DOI: 10.3390/fi11060122 (Results obtained with version 3.5)

*****
Some references to papers where WiLabV2Xsim was used:

A. Bazzi, C. Campolo, V. Todisco, S. Bartoletti, N. De Carli, A. Molinaro, A.O. Berthet, R.A. Stirling-Gallacher, “Towards 6G-V2X Sidelink: Non-Orthogonal Multiple Access in the Autonomous Mode”, IEEE Vehicular Technology Magazine, vol. 18, n. 2, pp. 50-59, 2023.

V. Todisco, C. Campolo, A. Molinaro, A. Berthet, R.A. Stirling-Gallacher, A. Bazzi, “On the Performance of SIC-based NOMA in the C-V2X Sidelink Autonomous Mode”, IEEE CSCN 2023.

V. Todisco, C. Campolo, A. Molinaro, A. Berthet, R.A. Stirling-Gallacher, A. Bazzi, “Joint use of Self and Successive Interference Cancellation in V2X Sidelink with Autonomous Resource Allocation”, IEEE VTC-Spring 2023.

C. Campolo, A. Bazzi, V. Todisco, S. Bartoletti, N. De Carli, A. Molinaro, A. Berthet, R.A. Stirling-Gallacher, “Enhancing the 5G-V2X Sidelink Autonomous Mode through Full-Duplex capabilities”, IEEE VTC-Spring 2022.

C. Campolo, V. Todisco, S. Bartoletti, A. Molinaro, A. Berthet, A. Bazzi, “Improving Resource Allocation for beyond 5G V2X Sidelink Connectivity”, ASILOMAR Conference on Signals, Systems and Computers 2021

A. Bazzi, C. Campolo, A. Molinaro, A. Berthet, B. Masini, A. Zanella, “On Wireless Blind Spots in C-V2X Sidelink”. IEEE Transactions on Vehicular Technology, vol. 69, n. 8, pp. 9239-9243, 2020.
*****

*****
List of main current contributors (those to whom you can ask)

Alessandro Bazzi (alessandro.bazzi@unibo.it)

Vittorio Todisco (vittorio.todisco@unibo.it, vittorio.todisco@ieiit.cnr.it)

Wu Zhuofei, also called Felix (wu.zhuofei@unibo.it)
*****

*****
Also contributing or contributed, in alphabetic order (if you feel you should be in the list, just let us know...we apologize, we are sure we are missing someone)

Stefania Bartoletti

Claudia Campolo

Giammarco Cecchini

Michele Menarini

Francesco Romeo 
*****

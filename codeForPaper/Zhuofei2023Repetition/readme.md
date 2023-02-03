# Code Explanation
This folder is organized for plot figures mentioned in the following paper:

    W. Zhuofei, S. Bartoletti, V. Martinez and A. Bazzi, "Adaptive Repetition Strategies in IEEE 802.11bd V2X Networks," in IEEE Transactions on Vehicular Technology, doi: 10.1109/TVT.2023.3241865.

## 1. Plot figure 3
1. Uncomment following part in file "deriveRanges.m", which would extand the range upto 1000 meters
```matlab
%     %% =========
%     % Plot figs of related paper, could be commented in other case.
%     % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
%     % Only for IEEE 802.11p, highway scenario. 
%     if phyParams.RawMax11p < 1000
%         phyParams.RawMax11p = 1000;
%     end
%     %% =========
```
2. go into folder "fig3" and run the scripts step 1~3
3. simulation data could be found in the subfolder "data"
4. Two figures could be found in folder "fig3" after running the 3 steps

## 2. Plot figure 4
The original figures in the paper are plotted with lot of simulations. You could use our simulation results directly or rerun your own simulations.
### 2.1. Using our simulation results
    * Go into folder "fig4"
    * Run step 3 directly

### 2.2. Rerun your own simulations (**may cost lot of time**)
    * Go into folder "fig4"
    * Change the simulation times for each density, see line 32~38 in "fig4_step_1_simulation.m":
        ```matlab
            if dens_kms <= 10
                times = 1;          % 450
            elseif dens_kms <= 30
                times = 1;          % 250
            else
                times = 1;          % 20
            end
        ```
    * Change the line 8 in "fig4_step_3_plotFigure.m" as
        ```matlab
            mataData = load(fullfile(path_data, "two_ch_data.mat"));
        ```
    *  Run step 1~3

## 3. Plot figure 5
Same as figure 4, you could rerun your own results or use our results directly

### 3.1. Using our simulation results
* Go into folder "fig5"
* Run step 3 directly

### 3.2. Rerun your own simulations (**may cost lot of time**)
* Go into folder "fig5"
* Change the channel model you are interested in, see line 28 in "fig5_step_1_simulation.m". You could set it as 0, 3, or both:

    ```matlab
        ch_model = [0, 3];          % [winner+ B1, ECC rural]
    ```
* Change the simulation times for each density, see line 46~52 in "fig5_step_1_simulation.m":
    ```matlab
        if dens_km <= 10
            times = 1;          % 300
        elseif dens_km <= 30
            times = 1;          % 150
        else
            times = 1;          % 20
        end
    ```
* Read data. According your simulations, change the channel model at line 14 in "fig5_step_2_readData.m" and line 21 in "fig5_step_3_plotFigure.m" :
    ```matlab
        ch_model = [0, 3];          % [winner+ B1, ECC rural]
    ```
* Change the line 10 in "fig5_step_3_plotFigure.m" as
    ```matlab
        mataData = load(fullfile(path_data, "prr_data_two_ch.mat"));
    ```
*  Run step 1~3

## 4. Plot figure 6
### 4.1. Plot figure with original results
* Go into folder "fig5" and run step 3 directly.

### 4.2. Plot figure with your own simulation results
In order to plot this figure, 3 locations in the simulation should be uncommented, where contains:
```matlab
% %% =========
% % Plot figs of related paper, could be commented in other case.
% % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
% % Only for IEEE 802.11p, highway scenario. 
```
1. In file "mainInit.m", at the end part;
2. In file "mainV2X.m", within the following "if" branch:
```matlab
elseif timeEvent == timeManagement.timeNextCBRupdate
```
3. In file "WiLabV2Xsim.m", within "Print To Files" section
Please note that this part is only work for IEEE 802.11p, highway scenario. 

After modification, run step 1 and modify line 9 in step 2 as:
```matlab
dataFolder = "mataData";
```

## Parameters
"retransType": [0,1,2] -> [static, deterministic, probabilistic]

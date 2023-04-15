%% 电动汽车有序充电代码
EV_params=Parans_Init().EV_params;      %电动汽车参数
BCS_params=Parans_Init().BCS_params;    %充电站参数
Basic_params=Parans_Init().Basic_params;    %基础参数

%% 常规负荷计算
% run("ConvLoad_CALC.m");

%% 电动汽车MC模拟
% run("MC_SIM.m");

%% 电动汽车无序充电负荷计算
% run("V0G_CLoad_CALC.m");

%% 电动汽车有序充电模拟
% run("V1G_SIM.m");

%% 数据分析
run("Data_ANAL.m");

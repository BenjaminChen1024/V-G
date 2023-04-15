clc; close all; clear;
%% 定义全局变量
EV_params=Parans_Init().EV_params;      %电动汽车参数
BCS_params=Parans_Init().BCS_params;    %充电站参数
Basic_params=Parans_Init().Basic_params;  %基础参数
load('ConventionalLoad.mat');
load('nEVs_MC.mat');
load('V0G_CLoad.mat');
load('V1G_CLoad.mat');
global Result;      %结果分析

%% 数据分析
Result.xaxis=0:0.25:23.75;
Result.TOU_EPrice=BCS_params.TOU_EPrice_Min;                %分时电价
Result.EPrice=BCS_params.EPrice*Basic_params.B;                %充电电价
Result.ConventionalLoad=ConventionalLoad_Min;               %常规负荷
Result.nEVs_Count=nEVs_Count_Time;                %各时段接入车辆数
Result.nEVs_StartTime=nEVs_StartTime;             %起始充电时间
Result.nEVs_SOC=nEVs_SOC;                         %初始SOC
Result.nEVs_EChargeTime=nEVs_EChargeTime;         %预期停留时间
Result.DTF_Cap=BCS_params.DTF_Cap*Basic_params.B;              %配电变压器额定容量
Result.CP_max=CP_max;                             %实际最大充电负荷

Result.V0G_ChargeLoad=V0G_ChargeLoad;
Result.V0G_Load_ALL=V0G_Load_ALL;
Result.V0G_Income=V0G_Income;
Result.V0G_Income_ALL=V0G_Income_ALL;

Result.V1G_ChargeLoad=V1G_ChargeLoad;
Result.V1G_Load_ALL=V1G_Load_ALL;
Result.V1G_Income=V1G_Income;
Result.V1G_Income_ALL=V1G_Income_ALL;

figure(1)
tiledlayout(2,2)
% 变电站购电电价与充点电价曲线
nexttile
hold on
title("充电站购电电价与充电电价曲线")
stairs(Result.xaxis,Result.TOU_EPrice,'LineWidth',2,'Color',[0 0 0]);
stairs(Result.xaxis,Result.EPrice,'LineWidth',2,'Color',[1 0 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Price/￥');
legend('TOU Electricity Price','Charging Price');
hold off
% 各时段充电站接入电动汽车数量
nexttile
hold on
title("各时段充电站接入电动汽车数量")
stairs(Result.xaxis,Result.nEVs_Count,'LineWidth',2,'Color',[0 0 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Count');
legend('Count of EV');
hold off
% 有序充电与无序充电日收益
nexttile
hold on
title("有序充电与无序充电日收益")
plot(Result.xaxis,Result.V0G_Income_ALL,'LineWidth',2,'Color',[0 0 1]);
plot(Result.xaxis,Result.V1G_Income_ALL,'LineWidth',2,'Color',[0 1 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Income/￥');
legend('V0G Daily Income','V1G Daily Income');
hold off
% 有序充电与无序充电收益
nexttile
hold on
title("有序充电与无序充电各时段收益")
plot(Result.xaxis,Result.V0G_Income,'LineWidth',2,'Color',[0 0 1]);
plot(Result.xaxis,Result.V1G_Income,'LineWidth',2,'Color',[0 1 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Income/￥');
legend('V0G Income','V1G Income');
hold off

figure(2)
tiledlayout(2,2)
% 电动汽车初始SOC分布
nexttile
hold on
title("电动汽车初始SOC分布")
plot(Result.nEVs_SOC,'*','Color',[0 0 1]);
xlabel('No.');
ylabel('SOC');
xlim([0 250]);
ylim([0 1]);
hold off
% 电动汽车预期充电时间分布
nexttile
hold on
title("电动汽车预期充电时间分布")
plot(Result.nEVs_EChargeTime,'*','Color',[0 0 1]);
xlabel('No.');
ylabel('Time/15min');
xlim([0 250]);
ylim([0 50]);
hold off
% 有序充电与无序充电负荷曲线
nexttile
hold on
title("有序充电与无序充电负荷曲线")
plot(Result.xaxis,Result.CP_max,'LineWidth',2,'Color',[1 0 0]);
plot(Result.xaxis,Result.V0G_ChargeLoad,'LineWidth',2,'Color',[0 0 1]);
plot(Result.xaxis,Result.V1G_ChargeLoad,'LineWidth',2,'Color',[0 1 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Load/kW');
legend('Max Charge Load','V0G Charge Load','V1G Charge Load');
hold off
% 总负荷曲线
nexttile
hold on
title("总负荷曲线")
plot(Result.xaxis,Result.DTF_Cap,'LineWidth',2,'Color',[1 0 0]);
plot(Result.xaxis,Result.ConventionalLoad,'LineWidth',2,'Color',[0 0 0]);
plot(Result.xaxis,Result.V0G_Load_ALL,'LineWidth',2,'Color',[0 0 1]);
plot(Result.xaxis,Result.V1G_Load_ALL,'LineWidth',2,'Color',[0 1 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Load/kW');
legend('Capacity of DTF','Conventional Load','V0G Load','V1G Load');
hold off


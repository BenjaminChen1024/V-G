clc; close all; clear;

%% 定义全局变量
BCS_params=Parans_Init().BCS_params;        %充电站参数
Basic_params=Parans_Init().Basic_params;    %基础参数
load('ConventionalLoad.mat');
load('nEVs_MC');

V0G_ChargeLoad=zeros(1,Basic_params.periods_per_day*2);
ChargeLoad=zeros(1,Basic_params.periods_per_day*2);

%% 无序充电负荷曲线
nEVs_Consumption_Time=sum(nEVs_Consumption,2)';         %各时段总电动汽车耗电量
nEVs_ChargeTime=sum(nEVs_Consumption)./BCS_params.P;    %各电动汽车充电时间
nEVs_ChargeTime=ceil((nEVs_ChargeTime*60)/15);          %24小时转换成15分钟
for i=1:nEVs_No_Count
    if nEVs_StartTime(i)==0
        nEVs_StartTime(i)=Basic_params.periods_per_day;
    end
    ChargeLoad(nEVs_StartTime(i):nEVs_StartTime(i)+nEVs_ChargeTime(i))=BCS_params.RCP;
    V0G_ChargeLoad=V0G_ChargeLoad+ChargeLoad;
    ChargeLoad=zeros(1,Basic_params.periods_per_day*2);
end
for t=1:Basic_params.periods_per_day
    if V0G_ChargeLoad(t)>=BCS_params.nPiles*BCS_params.RCP
        V0G_ChargeLoad(t)=BCS_params.nPiles*BCS_params.RCP;
    end
end

V0G_ChargeLoad=V0G_ChargeLoad(1:96)+V0G_ChargeLoad(97:192);   %电动汽车无序充电负荷
V0G_Load_ALL=ConventionalLoad_Min+V0G_ChargeLoad;
V0G_Income=V0G_ChargeLoad.*(BCS_params.EPrice-BCS_params.TOU_EPrice_Min);
V0G_Income_ALL=Basic_params.B*sum(V0G_ChargeLoad.*(BCS_params.EPrice-BCS_params.TOU_EPrice_Min));

save('V0G_CLoad','V0G_ChargeLoad','V0G_Load_ALL','V0G_Income','V0G_Income_ALL');
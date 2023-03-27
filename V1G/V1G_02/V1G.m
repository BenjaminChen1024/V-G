clc; close all; clear;
%% 定义全局变量
global EV_params;   %电动汽车参数
global BCS_params;  %充电站参数
global MC_params;   %MC模拟参数
global Behavious;   %用户行为
global Algorithm;   %优化算法
global Result;      %结果分析

%% 初始化电动汽车参数（比亚迪 宋Pro DM-i 110KM）
EV_params.Cap=18.3;          %电池容量（kWh）
EV_params.NEDC=110;         %纯电续航里程（km）
EV_params.Consumption=0;    %耗电量
EV_params.minSOC=0.1;    %最小荷电状态
EV_params.Expected_Time=0;  %预期充电时间
EV_params.Expected_SOC=[];   %预期充电荷电状态

%% 初始化充电站参数（广州特来电充电站-盛大国际特惠充电站）
BCS_params.nPiles=10;                   %充电桩数量（个）
BCS_params.DTF_PowerFactor=0.8;         %常规负荷功率因数
BCS_params.DTF_Cap=350*4/0.8/0.85;      %配电变压器额定容量（kW）(户数*每户用电量/功率因数/负荷率）
BCS_params.RCP=7;                       %额定充电功率（kW）
BCS_params.PowerFactor=0.9;             %充电负荷功率因数
BCS_params.P=BCS_params.RCP*BCS_params.PowerFactor;   %实际充电功率（kW）
%% 电价计算（南方电网）
BCS_params.GPrice=[1.215 0.726 0.293];  %电网购电电价（峰平谷）
BCS_params.TOU_EPrice_Hour=[
    0.726 0.726 1.215 1.215 1.215 1.215 ...
    1.215 0.726 0.726 0.726 0.726 0.726 ...
    0.293 0.293 0.293 0.293 0.293 0.293 ...
    0.293 0.293 0.726 0.726 1.215 1.215
];  %分时电价（12点开始）（高峰时段为10-12点、14-19点；低谷时段为0-8点；其余时段为平段；峰平谷比价为1.7:1:0.38）
BCS_params.TOU_EPrice_Min=zeros(1,96);  %分时段电价
for i=1:95
    BCS_params.TOU_EPrice_Min(i)=BCS_params.TOU_EPrice_Hour(floor(i/4)+1);
    if floor((i-1)/4)<floor(i/4)
       BCS_params.TOU_EPrice_Min(i)=BCS_params.TOU_EPrice_Hour(floor(i/4));    
    end
end
BCS_params.TOU_EPrice_Min(96)=BCS_params.TOU_EPrice_Hour(24);
BCS_params.EPrice=1.72;  %充电电价（元）

%% 初始化MC模拟参数
MC_params.all_day=1;            %模拟天数
MC_params.periods_per_day=96;   %一天划分为若干时段数
MC_params.periods_Hour=0.25;
MC_params.periods_Min=15;
MC_params.nEVs=18;             %电动汽车数量
MC_params.nEVs_Count=0;
MC_params.nEVs_Count_ALL=0;
MC_params.nEVs_Count_Time=zeros(1,MC_params.periods_per_day);
MC_params.nEVs_StartTime=zeros(1,MC_params.nEVs);
MC_params.nEVs_SOC=zeros(1,MC_params.nEVs);
MC_params.nEVs_SOC_Time=zeros(MC_params.periods_per_day,MC_params.nEVs);
MC_params.nEVs_EndTime=zeros(1,MC_params.nEVs);
MC_params.J_max=0;              %最大时间段数
MC_params.nEVs_No=0;            %电动汽车编号
MC_params.nEVs_No_Count=0;      %电动汽车编号计数
MC_params.S=[];                 %充电站状态矩阵
MC_params.V0G_ChargeLoad=zeros(1,MC_params.periods_per_day*2);
MC_params.ChargeLoad=zeros(1,MC_params.periods_per_day*2);
MC_params.A=ones(MC_params.periods_per_day,1);
MC_params.B=ones(1,MC_params.periods_per_day);

%% 计算实际充电功率
Behavious.ConventionalLoad_Hour=[
    1426.39 1445.58 1426.39 1416.39 1426.39 1491.22 ...
    1512.84 1523.64 1512.84 1426.39 1399.37 1275.10 ...
    1188.66 1048.18 832.06 780.22 768.64 812.06 884.48 ...
    1069.70 1170.66 1275.10 1404.78 1426.39 1426.39
    ];  %从12点开始每小时常规负荷
Behavious.ConventionalLoad_Hour=BCS_params.DTF_PowerFactor*Behavious.ConventionalLoad_Hour; %实际常规负荷
BCS_params.CP_TFCap_ratio=zeros(1,96);  %充电功率占变压器容量的比例
for i=1:MC_params.periods_per_day   %24小时局部线性化为96个时段
    Behavious.FirstConventionalLoad=Behavious.ConventionalLoad_Hour(floor((i-1)/4)+1)/BCS_params.DTF_Cap;
    Behavious.SecondConventionalLoad=Behavious.ConventionalLoad_Hour(floor((i-1)/4)+2)/BCS_params.DTF_Cap;
    if(rem(i,4)==1)
    BCS_params.CP_TFCap_ratio(i)=Behavious.ConventionalLoad_Hour(floor((i-1)/4)+1)/BCS_params.DTF_Cap;
    elseif(rem(i,4)==2)
         BCS_params.CP_TFCap_ratio(i)=Behavious.FirstConventionalLoad+(Behavious.SecondConventionalLoad-Behavious.FirstConventionalLoad)/4;
    elseif(rem(i,4)==3)
        BCS_params.CP_TFCap_ratio(i)=Behavious.FirstConventionalLoad+2*(Behavious.SecondConventionalLoad-Behavious.FirstConventionalLoad)/4;
    else
        BCS_params.CP_TFCap_ratio(i)=Behavious.FirstConventionalLoad+3*(Behavious.SecondConventionalLoad-Behavious.FirstConventionalLoad)/4;
    end
end
Behavious.ConventionalLoad_Min=BCS_params.DTF_Cap*BCS_params.CP_TFCap_ratio;  %96时段常规负荷
Behavious.CP_max=BCS_params.DTF_Cap*MC_params.B-Behavious.ConventionalLoad_Min;     %实际最大充电负荷

for t=1:MC_params.periods_per_day   %从中午12点开始计算(从第50个时段开始计算), 12.25为第一个时间段
    Behavious.StartTime=12.25+0.25*(t-1);
    %% 起始充电时间与车辆数的MC模拟
    if Behavious.StartTime>24
        Behavious.StartTime=Behavious.StartTime-24;
    end
    Behavious.StartTime_us=17.6;    %起始充电时间概率密度函数期望
    Behavious.StartTime_ds=3.4;     %起始充电时间概率密度函数标准差
    %起始充电时间概率密度函数
    if Behavious.StartTime>(Behavious.StartTime_us-12)
        Behavious.StartTime_fs=@(x)1/(Behavious.StartTime_ds*(2*pi)^0.5).*exp(-(x-Behavious.StartTime_us).^2./(2*Behavious.StartTime_ds^2)); %(us-12)<x<=24
    else
        Behavious.StartTime_fs=@(x)1/(Behavious.StartTime_ds*(2*pi)^0.5).*exp(-(x+24-Behavious.StartTime_us).^2./(2*Behavious.StartTime_ds^2)); %0<x<=(us-12)
    end
    Behavious.s_ts=integral(Behavious.StartTime_fs,Behavious.StartTime-0.25,Behavious.StartTime);  %0.25小时时段内的概率
    MC_params.nEVs_Count=round(Behavious.s_ts*MC_params.nEVs);  %该时段接入的电动汽车数量
    MC_params.nEVs_Count_Time(t)=MC_params.nEVs_Count;
    MC_params.nEVs_Count_ALL=MC_params.nEVs_Count_ALL+MC_params.nEVs_Count;
    %% 电动汽车的MC模拟
    for i=1:MC_params.nEVs_Count
        %% 初始SOC的MC模拟
        Behavious.StartSOC_ud=3.2;      %初始SOC概率密度函数期望
        Behavious.StartSOC_dd=0.88;     %初始SOC概率密度函数标准差
        %初始SOC概率密度函数
        Behavious.StartSOC=0.9-15*lognrnd(Behavious.StartSOC_ud,Behavious.StartSOC_dd)/(100*EV_params.Cap);
        while Behavious.StartSOC<0.1 || Behavious.StartSOC>=0.3
            Behavious.StartSOC=0.9-15*lognrnd(Behavious.StartSOC_ud,Behavious.StartSOC_dd)/(100*EV_params.Cap);
        end
        Behavious.StartSOC=fix(Behavious.StartSOC*100)/100;
        %% 预期停留时间的MC模拟
        Behavious.EndTime_ue=8.92;      %预期停留时间概率密度函数期望
        Behavious.EndTime_de=3.24;      %预期停留时间概率密度函数标准差
        %预期停留时间概率密度函数
        Behavious.EndTime=normrnd(Behavious.EndTime_ue,Behavious.EndTime_de);
        while Behavious.EndTime>=12 || Behavious.EndTime<=2
            Behavious.EndTime=normrnd(Behavious.EndTime_ue,Behavious.EndTime_de);
        end
        Behavious.EndTime=ceil((Behavious.EndTime*60)/15)+48;
        Behavious.J_max=Behavious.EndTime;
        %判断是否能在预定停留时间内达到所需最终荷电状态
        if (0.25*Behavious.J_max*BCS_params.P>((0.9-Behavious.StartSOC)*EV_params.Cap))
            MC_params.nEVs_No=MC_params.nEVs_No+1;
            MC_params.nEVs_StartTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=t;
            MC_params.nEVs_SOC(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=Behavious.StartSOC;
            MC_params.nEVs_Consumption(t,MC_params.nEVs_No_Count+MC_params.nEVs_No)=(1-Behavious.StartSOC)*EV_params.Cap;
            MC_params.nEVs_EndTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=Behavious.EndTime;
        end
    end
    MC_params.nEVs_No_Count=MC_params.nEVs_No_Count+MC_params.nEVs_No;
    MC_params.nEVs_No=0;
end
MC_params.nEVs_StartTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_SOC((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_SOC_Time(:,(MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_EndTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_CSOC_min=0.9*ones(MC_params.nEVs_No_Count,1);
MC_params.nEVs_CSOC_max=ones(MC_params.nEVs_No_Count,1);

%% 无序充电负荷曲线
MC_params.nEVs_Consumption_Time=sum(MC_params.nEVs_Consumption,2)';         %各时段总电动汽车耗电量
MC_params.nEVs_ChargeTime=sum(MC_params.nEVs_Consumption)./BCS_params.P;    %各电动汽车充电时间
MC_params.nEVs_ChargeTime=ceil((MC_params.nEVs_ChargeTime*60)/15);          %24小时转换成15分钟
for i=1:MC_params.nEVs_No_Count
    if MC_params.nEVs_StartTime(i)==0
        MC_params.nEVs_StartTime(i)=MC_params.periods_per_day;
    end
    MC_params.ChargeLoad(MC_params.nEVs_StartTime(i):MC_params.nEVs_StartTime(i)+MC_params.nEVs_ChargeTime(i))=BCS_params.RCP;
    MC_params.V0G_ChargeLoad=MC_params.V0G_ChargeLoad+MC_params.ChargeLoad;
    MC_params.ChargeLoad=zeros(1,MC_params.periods_per_day*2);
end
MC_params.V0G_ChargeLoad=MC_params.V0G_ChargeLoad(1:96)+MC_params.V0G_ChargeLoad(97:192);   %电动汽车无序充电负荷

%% 电动汽车有序充电控制策略
% 优化策略
yalmip('clear');
% 定义矩阵
MC_params.S=sdpvar(MC_params.nEVs_No_Count,MC_params.periods_per_day);
% 约束条件
Algorithm.Constraints=[(BCS_params.RCP*sum(MC_params.S))<=(BCS_params.DTF_Cap*MC_params.B-Behavious.ConventionalLoad_Min)];
Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*MC_params.periods_Hour*MC_params.S*MC_params.A+EV_params.Cap*(MC_params.nEVs_SOC'))>=EV_params.Cap*MC_params.nEVs_CSOC_min];
Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*MC_params.periods_Hour*MC_params.S*MC_params.A+EV_params.Cap*(MC_params.nEVs_SOC'))<=EV_params.Cap*MC_params.nEVs_CSOC_max];
% for i=1:MC_params.nEVs_No_Count
%     for t=1:MC_params.periods_per_day
%         Algorithm.Constraints=[Algorithm.Constraints,MC_params.S(i,t)>=1];
%     end
% end
% 定义对象
Algorithm.Objective=BCS_params.RCP*MC_params.periods_Hour*sum(MC_params.S*(BCS_params.EPrice-(BCS_params.TOU_EPrice_Min')));
% 为YALMIP求解器设置选项
Algorithm.options = sdpsettings('solver','cplex','verbose',1);
% 优化模型
tic
Algorithm.sol = optimize(Algorithm.Constraints,Algorithm.Objective,Algorithm.options);
% 分析错误
if Algorithm.sol.problem == 0
    Algorithm.solution = double(MC_params.S);
else
    Algorithm.solution = double(MC_params.S);
    disp('Hmm, something went wrong!');
    sol.info
    yalmiperror(sol.problem)
end
toc

%% 数据分析
Result.xaxis=0:0.25:23.75;
Result.TOU_EPrice=BCS_params.TOU_EPrice_Min;                %分时电价
Result.EPrice=BCS_params.EPrice*MC_params.B;                %充电电价
Result.ConventionalLoad=Behavious.ConventionalLoad_Min;     %常规负荷
Result.nEVs_Count=MC_params.nEVs_Count_Time;                %各时段接入车辆数
Result.nEVs_StartTime=MC_params.nEVs_StartTime;             %起始充电时间
Result.nEVs_SOC=MC_params.nEVs_SOC;                         %初始SOC
Result.nEVs_EndTime=MC_params.nEVs_EndTime;                 %预期停留时间
Result.DTF_Cap=BCS_params.DTF_Cap*MC_params.B;              %配电变压器额定容量
Result.CP_max=Behavious.CP_max;                             %实际最大充电负荷
Result.V0G_ChargeLoad=MC_params.V0G_ChargeLoad;
Result.V0G_Load_ALL=Behavious.ConventionalLoad_Min+Result.V0G_ChargeLoad;
Result.S=sum(Algorithm.solution);
Result.V1G_ChargeLoad=BCS_params.P*Result.S;
Result.V1G_Load_ALL=Behavious.ConventionalLoad_Min+Result.V1G_ChargeLoad;

tiledlayout(2,2)
% 变电站购电电价与充点电价曲线
nexttile
hold on
title("变电站购电电价与充点电价曲线")
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
% 有序充电与无序充电负荷曲线
nexttile
hold on
title("有序充电与无序充电负荷曲线")
plot(Result.xaxis,Result.CP_max,'LineWidth',2,'Color',[1 0 0]);
plot(Result.xaxis,Result.V0G_ChargeLoad,'LineWidth',2,'Color',[0 0 1]);
% plot(Result.xaxis,Result.V0G_ChargeLoad,'LineWidth',2,'Color',[0 0 1]);
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
% plot(Result.xaxis,Result.V1G_Load_ALL,'LineWidth',2,'Color',[0 0 1]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Load/kW');
legend('Capacity of DTF','Conventional Load','V0G Load','V0G Load');
hold off

figure 
hold on
title("异常错误")
plot(Result.xaxis,Result.V1G_Load_ALL,'LineWidth',2,'Color',[0 0 1]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Load/kW');
legend('V1G Load');
hold off


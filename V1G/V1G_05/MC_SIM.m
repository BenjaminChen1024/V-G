clc; close all; clear;

%% 定义全局变量
EV_params=Parans_Init().EV_params;      %电动汽车参数
BCS_params=Parans_Init().BCS_params;    %充电站参数
Basic_params=Parans_Init().Basic_params;    %基础参数
%% 初始化MC模拟参数
MC_params.all_day=1;            %模拟天数
MC_params.nEVs=500;             %电动汽车数量
MC_params.nEVs_Count=0;         %电动汽车接入临时变量
MC_params.nEVs_Count_ALL=0;     %电动汽车接入充电站总数
MC_params.nEVs_No=0;            %电动汽车编号
MC_params.nEVs_No_Count=0;      %电动汽车编号计数
MC_params.nEVs_Count_Time=zeros(1,Basic_params.periods_per_day);    %电动汽车接入时间分布
MC_params.nEVs_StartTime=zeros(1,MC_params.nEVs);                   %电动汽车接入初始时间
MC_params.nEVs_SOC=zeros(1,MC_params.nEVs);                         %电动汽车接入初始SOC
MC_params.nEVs_SOC_Time=zeros(Basic_params.periods_per_day,MC_params.nEVs); %电动汽车初始SOC时间分布
MC_params.nEVs_EChargeTime=zeros(1,MC_params.nEVs);                 %电动汽车预期充电时间
MC_params.nEVs_NChargeTime=zeros(1,MC_params.nEVs);                 %电动汽车所需充电时间
MC_params.nEVs_V2G=zeros(1,MC_params.nEVs);                         %电动汽车可充放电状态
MC_params.nEVs_V2G_R=0.7;       %电动汽车可充放电比例

%% 电动汽车MC模拟
for t=1:Basic_params.periods_per_day   %从中午12点开始计算(从第50个时段开始计算), 12.25为第一个时间段
    StartTime=12.25+0.25*(t-1);
    % 起始充电时间与车辆数的MC模拟
    if StartTime>24
        StartTime=StartTime-24;
    end
    StartTime_us=17.6;    %起始充电时间概率密度函数期望
    StartTime_ds=3.4;     %起始充电时间概率密度函数标准差
    %起始充电时间概率密度函数
    if StartTime>(StartTime_us-12)
        StartTime_fs=@(x)1/(StartTime_ds*(2*pi)^0.5).*exp(-(x-StartTime_us).^2./(2*StartTime_ds^2)); %(us-12)<x<=24
    else
        StartTime_fs=@(x)1/(StartTime_ds*(2*pi)^0.5).*exp(-(x+24-StartTime_us).^2./(2*StartTime_ds^2)); %0<x<=(us-12)
    end
    s_ts=integral(StartTime_fs,StartTime-0.25,StartTime);  %0.25小时时段内的概率
    MC_params.nEVs_Count=round(s_ts*MC_params.nEVs);  %该时段接入的电动汽车数量
    MC_params.nEVs_Count_Time(t)=MC_params.nEVs_Count;
    MC_params.nEVs_Count_ALL=MC_params.nEVs_Count_ALL+MC_params.nEVs_Count;

    for i=1:MC_params.nEVs_Count
        %% 初始SOC的MC模拟
        StartSOC_ud=3.2;      %初始SOC概率密度函数期望
        StartSOC_dd=0.88;     %初始SOC概率密度函数标准差
        %初始SOC概率密度函数
        StartSOC=0.9-15*lognrnd(StartSOC_ud,StartSOC_dd)/(100*EV_params.Cap);
        while StartSOC<0.1 || StartSOC>=0.3
            StartSOC=0.9-15*lognrnd(StartSOC_ud,StartSOC_dd)/(100*EV_params.Cap);
        end
        StartSOC=fix(StartSOC*100)/100;
        Consumption=(0.9-StartSOC)*EV_params.Cap;     %电动汽车耗电量
        NChargeTime_Hour=Consumption/BCS_params.P;  %电动汽车所需充电时间
        NChargeTime_Min=ceil((NChargeTime_Hour*60)/15);     %24小时转换成15分钟
        % 预期充电时间时间的MC模拟
        %预期充电时间概率密度函数
        EChargeTime_Hour=2+6*rand(1);
        while EChargeTime_Hour>=8 || EChargeTime_Hour<=2
            EChargeTime_Hour=8*rand(1);
        end
        EChargeTime_Min=ceil((EChargeTime_Hour*60)/15);
        % V2G电动汽车的MC模拟
        V2G=rand(1)<=MC_params.nEVs_V2G_R;
        while V2G~=0 & V2G~=1
            V2G=rand(1)<=MC_params.nEVs_V2G_R;
        end
        %判断是否能在预定充电时间内达到所需最终荷电状态
        if (0.25*EChargeTime_Min*BCS_params.P>((0.9-StartSOC)*EV_params.Cap))
            MC_params.nEVs_No=MC_params.nEVs_No+1;
            MC_params.nEVs_StartTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=t;
            MC_params.nEVs_SOC(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=StartSOC;
            MC_params.nEVs_EChargeTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=EChargeTime_Min;
            MC_params.nEVs_NChargeTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=NChargeTime_Min;
            MC_params.nEVs_V2G(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=V2G;
        end
    end
    MC_params.nEVs_No_Count=MC_params.nEVs_No_Count+MC_params.nEVs_No;
    MC_params.nEVs_No=0;
end

MC_params.nEVs_StartTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_SOC((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_SOC_Time(:,(MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_EChargeTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_NChargeTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_V2G((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];

nEVs_No_Count=MC_params.nEVs_No_Count;
nEVs_Count_Time=MC_params.nEVs_Count_Time;
nEVs_StartTime=MC_params.nEVs_StartTime;
nEVs_SOC=MC_params.nEVs_SOC;
nEVs_EChargeTime=MC_params.nEVs_EChargeTime;
nEVs_NChargeTime=MC_params.nEVs_NChargeTime;
nEVs_V2G=MC_params.nEVs_V2G;

save('nEVs_MC','nEVs_No_Count','nEVs_Count_Time','nEVs_StartTime','nEVs_SOC','nEVs_EChargeTime','nEVs_NChargeTime','nEVs_V2G');
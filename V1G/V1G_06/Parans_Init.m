function Params=Parans_Init()

%% 初始化基础参数
Params.Basic_params.periods_per_day=96;   %一天划分为若干时段数
Params.Basic_params.periods_Hour=0.25;
Params.Basic_params.periods_Min=15;
Params.Basic_params.A=ones(Params.Basic_params.periods_per_day,1);
Params.Basic_params.B=ones(1,Params.Basic_params.periods_per_day);

%% 初始化电动汽车参数（比亚迪 宋Pro DM-i 110KM）
Params.EV_params.Cap=18.3;          %电池容量（kWh）
Params.EV_params.NEDC=110;         %纯电续航里程（km）
Params.EV_params.Consumption=0;    %耗电量
Params.EV_params.minSOC=0.1;    %最小荷电状态
Params.EV_params.Expected_Time=0;  %预期充电时间

%% 初始化充电站参数（广州特来电充电站-盛大国际特惠充电站）
Params.BCS_params.nPiles=500;                   %充电桩数量（个）
Params.BCS_params.DTF_PowerFactor=0.8;         %配电变压器负荷功率因数
Params.BCS_params.DTF_Cap=300*5/0.8/0.85;      %配电变压器额定容量（kW）(户数*每户用电量/功率因数/负荷率）
Params.BCS_params.RCP=7;                       %额定充电功率（kW）
Params.BCS_params.PowerFactor=0.9;             %充电负荷功率因数
Params.BCS_params.P=Params.BCS_params.RCP*Params.BCS_params.PowerFactor;   %实际充电功率（kW）

%% 电价计算（南方电网）
Params.BCS_params.GPrice=[1.215 0.726 0.293];  %电网购电电价（峰平谷）
Params.BCS_params.TOU_EPrice_Hour=[
    0.726 0.726 1.215 1.215 1.215 1.215 ...
    1.215 0.726 0.726 0.726 0.726 0.726 ...
    0.293 0.293 0.293 0.293 0.293 0.293 ...
    0.293 0.293 0.726 0.726 1.215 1.215
];  %分时电价（12点开始）（高峰时段为10-12点、14-19点；低谷时段为0-8点；其余时段为平段；峰平谷比价为1.7:1:0.38）
Params.BCS_params.TOU_EPrice_Min=zeros(1,96);  %分时段电价
for i=1:95
    Params.BCS_params.TOU_EPrice_Min(i)=Params.BCS_params.TOU_EPrice_Hour(floor(i/4)+1);
    if floor((i-1)/4)<floor(i/4)
       Params.BCS_params.TOU_EPrice_Min(i)=Params.BCS_params.TOU_EPrice_Hour(floor(i/4));    
    end
end
Params.BCS_params.TOU_EPrice_Min(96)=Params.BCS_params.TOU_EPrice_Hour(24);
Params.BCS_params.EPrice=1.72;  %充电电价（元）

end
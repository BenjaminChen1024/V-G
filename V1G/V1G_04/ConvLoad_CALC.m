clc; close all; clear;

%% 定义全局变量
BCS_params=Parans_Init().BCS_params;        %充电站参数
Basic_params=Parans_Init().Basic_params;    %基础参数

%% 计算实际充电功率
ConventionalLoad_Hour=[
    1426.39 1445.58 1426.39 1416.39 1426.39 1491.22 ...
    1512.84 1523.64 1512.84 1426.39 1399.37 1275.10 ...
    1188.66 1048.18 832.06 780.22 768.64 812.06 884.48 ...
    1069.70 1170.66 1275.10 1404.78 1426.39 1426.39
    ];  %从12点开始每小时常规负荷
ConventionalLoad_Hour=BCS_params.DTF_PowerFactor*ConventionalLoad_Hour; %实际常规负荷
BCS_params.CP_TFCap_ratio=zeros(1,96);  %充电功率占变压器容量的比例
for i=1:Basic_params.periods_per_day   %24小时局部线性化为96个时段
    FirstConventionalLoad=ConventionalLoad_Hour(floor((i-1)/4)+1)/BCS_params.DTF_Cap;
    SecondConventionalLoad=ConventionalLoad_Hour(floor((i-1)/4)+2)/BCS_params.DTF_Cap;
    if(rem(i,4)==1)
    BCS_params.CP_TFCap_ratio(i)=ConventionalLoad_Hour(floor((i-1)/4)+1)/BCS_params.DTF_Cap;
    elseif(rem(i,4)==2)
         BCS_params.CP_TFCap_ratio(i)=FirstConventionalLoad+(SecondConventionalLoad-FirstConventionalLoad)/4;
    elseif(rem(i,4)==3)
        BCS_params.CP_TFCap_ratio(i)=FirstConventionalLoad+2*(SecondConventionalLoad-FirstConventionalLoad)/4;
    else
        BCS_params.CP_TFCap_ratio(i)=FirstConventionalLoad+3*(SecondConventionalLoad-FirstConventionalLoad)/4;
    end
end

ConventionalLoad_Min=BCS_params.DTF_Cap*BCS_params.CP_TFCap_ratio;  %96时段常规负荷
CP_max=(BCS_params.DTF_Cap*Basic_params.B-ConventionalLoad_Min)*BCS_params.DTF_PowerFactor;     %实际最大充电负荷

save('ConventionalLoad','ConventionalLoad_Min','CP_max');
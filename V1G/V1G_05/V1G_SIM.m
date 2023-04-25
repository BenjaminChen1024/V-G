clc; close all; clear;
%% 定义全局变量
EV_params=Parans_Init().EV_params;      %电动汽车参数
BCS_params=Parans_Init().BCS_params;    %充电站参数
Basic_params=Parans_Init().Basic_params;  %基础参数
load('ConventionalLoad.mat');
load('nEVs_MC.mat');

V1G_params.nEVs_CSOC_min=0.9*ones(nEVs_No_Count,1);
V1G_params.nEVs_CSOC_max=ones(nEVs_No_Count,1);
V1G_params.J_max=0;              %最大时间段数
V1G_params.Y=zeros(BCS_params.nPiles,1);
V1G_params.N=zeros(BCS_params.nPiles,1);
V1G_params.S=zeros(BCS_params.nPiles,Basic_params.periods_per_day); %充电站状态矩阵
V1G_params.S_ALL=zeros(BCS_params.nPiles,Basic_params.periods_per_day);
V1G_params.C=zeros(BCS_params.nPiles,Basic_params.periods_per_day); %充电站决策矩阵
V1G_params.C_ALL=zeros(BCS_params.nPiles,Basic_params.periods_per_day);

%% 充电站有序充电模拟
tic
for t=1:Basic_params.periods_per_day
    % 预更新充电站汽车充电状态
    if V1G_params.J_max~=0
        V1G_params.J_max=V1G_params.J_max-1;
    end
    V1G_params.S(:,1)=0;
    V1G_params.S=circshift(V1G_params.S,-1,2);
    for n=1:BCS_params.nPiles
        if V1G_params.C(n,1)~=0
            if V1G_params.N(n,1)~=0
                V1G_params.N(n,1)=V1G_params.N(n,1)-1;
            end
        end
    end
    % 预更新充电站汽车控制策略
    V1G_params.C(:,1)=0;
    V1G_params.C=circshift(V1G_params.C,-1,2);
    % 判断是否有新车接入
    EV_index=find(nEVs_StartTime==t);
    if ~isempty(EV_index)
        % 记录电动汽车SOC和预期充电时间
        EV_Count=numel(EV_index);
        EV_SOC=nEVs_SOC(EV_index);
        EV_EChargeTime=nEVs_EChargeTime(EV_index);
        EV_NChargeTime=nEVs_NChargeTime(EV_index);
        EV_V2G=nEVs_V2G(EV_index);
        % 确定控制时间段数
        V1G_params.J_max=max([EV_EChargeTime,V1G_params.J_max]);
        % 更新充电站状态方程
        for n=1:BCS_params.nPiles
            if V1G_params.S(n,1)==0
                V1G_params.S(n,1:EV_EChargeTime(EV_Count))=1;
                V1G_params.Y(n,1)=EV_SOC(EV_Count);
                V1G_params.N(n,1)=EV_NChargeTime(EV_Count);
                EV_Count=EV_Count-1;
            end
            if EV_Count==0
                break;
            end
        end
        % 更新充电桩对应电动汽车SOC数据
        for n=1:BCS_params.nPiles
            if V1G_params.S(n,1)==0
                V1G_params.Y(n,1)=0;
                V1G_params.N(n,1)=0;
            end
        end
        V1G_params.SC=V1G_params.S(:,1:V1G_params.J_max);
        V1G_params.S_ALL(:,t)=V1G_params.S(:,1);
        % 优化策略
        yalmip('clear');
        % 定义矩阵
        V1G_params.X=binvar(BCS_params.nPiles,V1G_params.J_max);
        % 约束条件
        Algorithm.Constraints=[V1G_params.X>=0,V1G_params.X<=1];
        for j=1:V1G_params.J_max
            if (t+j-1)<=Basic_params.periods_per_day
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.RCP*sum(V1G_params.X(:,j).*V1G_params.SC(:,j)))<=(CP_max(t+j-1))];
            else
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.RCP*sum(V1G_params.X(:,j).*V1G_params.SC(:,j)))<=(CP_max(t+j-1-96))];
            end
        end
        for n=1:BCS_params.nPiles
            if V1G_params.Y(n,1)~=0
%                 Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*Basic_params.periods_Hour*sum(V1G_params.X(n,:).*V1G_params.SC(n,:))+EV_params.Cap*V1G_params.Y(n,1))>=EV_params.Cap*V1G_params.nEVs_CSOC_min];
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*Basic_params.periods_Hour*sum(V1G_params.X(n,:).*V1G_params.SC(n,:))+EV_params.Cap*V1G_params.Y(n,1))<=EV_params.Cap*V1G_params.nEVs_CSOC_max];
                Algorithm.Constraints=[Algorithm.Constraints,sum(V1G_params.X(n,:).*V1G_params.SC(n,:))>=V1G_params.N(n,1)];
            end
        end
        % 定义对象
        Algorithm.Objective=BCS_params.RCP*Basic_params.periods_Hour*sum(sum(V1G_params.X).*(BCS_params.EPrice-BCS_params.TOU_EPrice_Min(t)));
        % 为YALMIP求解器设置选项
        Algorithm.options = sdpsettings('solver','cplex','verbose',1);
        % 优化模型
        Algorithm.sol = optimize(Algorithm.Constraints,Algorithm.Objective,Algorithm.options);
        % 分析错误
        if Algorithm.sol.problem == 0
            Algorithm.solution = double(V1G_params.X);
        else
            Algorithm.solution = double(V1G_params.X);
            disp('Hmm, something went wrong!');
            sol.info
            yalmiperror(sol.problem)
        end
        V1G_params.C=Algorithm.solution;
    end
    EV_index=[];
    V1G_params.C_ALL(:,t)=V1G_params.C(:,1);
end
toc

V1G_params.V1G_ChargeLoad=BCS_params.P*sum(V1G_params.C_ALL);
V1G_params.V1G_Load_ALL=ConventionalLoad_Min+V1G_params.V1G_ChargeLoad;
V1G_params.V1G_Income=V1G_params.V1G_ChargeLoad.*(BCS_params.EPrice-BCS_params.TOU_EPrice_Min);
V1G_params.V1G_Income_ALL=Basic_params.B.*sum(V1G_params.V1G_ChargeLoad.*(BCS_params.EPrice-BCS_params.TOU_EPrice_Min));
V1G_ChargeLoad=V1G_params.V1G_ChargeLoad;
V1G_Load_ALL=V1G_params.V1G_Load_ALL;
V1G_Income=V1G_params.V1G_Income;
V1G_Income_ALL=V1G_params.V1G_Income_ALL;
save("V1G_CLoad",'V1G_ChargeLoad','V1G_Load_ALL','V1G_Income','V1G_Income_ALL')

run("Data_ANAL.m");
clc; close all; clear;
%% ����ȫ�ֱ���
global EV_params;   %�綯��������
global BCS_params;  %���վ����
global MC_params;   %MCģ�����
global Behavious;   %�û���Ϊ
global Algorithm;   %�Ż��㷨
global Result;      %�������

%% ��ʼ���綯�������������ǵ� ��Pro DM-i 110KM��
EV_params.Cap=18.3;          %���������kWh��
EV_params.NEDC=110;         %����������̣�km��
EV_params.Consumption=0;    %�ĵ���
EV_params.minSOC=0.1;    %��С�ɵ�״̬
EV_params.Expected_Time=0;  %Ԥ�ڳ��ʱ��
EV_params.Expected_SOC=[];   %Ԥ�ڳ��ɵ�״̬

%% ��ʼ�����վ������������������վ-ʢ������ػݳ��վ��
BCS_params.nPiles=10;                   %���׮����������
BCS_params.DTF_PowerFactor=0.8;         %����ѹ�����ɹ�������
BCS_params.DTF_Cap=230*4/0.8/0.85;      %����ѹ���������kW��(����*ÿ���õ���/��������/�����ʣ�
BCS_params.RCP=7;                       %���繦�ʣ�kW��
BCS_params.PowerFactor=0.9;             %��縺�ɹ�������
BCS_params.P=BCS_params.RCP*BCS_params.PowerFactor;   %ʵ�ʳ�繦�ʣ�kW��
%% ��ۼ��㣨�Ϸ�������
BCS_params.GPrice=[1.215 0.726 0.293];  %���������ۣ���ƽ�ȣ�
BCS_params.TOU_EPrice_Hour=[
    0.726 0.726 1.215 1.215 1.215 1.215 ...
    1.215 0.726 0.726 0.726 0.726 0.726 ...
    0.293 0.293 0.293 0.293 0.293 0.293 ...
    0.293 0.293 0.726 0.726 1.215 1.215
];  %��ʱ��ۣ�12�㿪ʼ�����߷�ʱ��Ϊ10-12�㡢14-19�㣻�͹�ʱ��Ϊ0-8�㣻����ʱ��Ϊƽ�Σ���ƽ�ȱȼ�Ϊ1.7:1:0.38��
BCS_params.TOU_EPrice_Min=zeros(1,96);  %��ʱ�ε��
for i=1:95
    BCS_params.TOU_EPrice_Min(i)=BCS_params.TOU_EPrice_Hour(floor(i/4)+1);
    if floor((i-1)/4)<floor(i/4)
       BCS_params.TOU_EPrice_Min(i)=BCS_params.TOU_EPrice_Hour(floor(i/4));    
    end
end
BCS_params.TOU_EPrice_Min(96)=BCS_params.TOU_EPrice_Hour(24);
BCS_params.EPrice=1.72;  %����ۣ�Ԫ��

%% ��ʼ��MCģ�����
MC_params.all_day=1;            %ģ������
MC_params.periods_per_day=96;   %һ�컮��Ϊ����ʱ����
MC_params.periods_Hour=0.25;
MC_params.periods_Min=15;
MC_params.nEVs=250;             %�綯��������
MC_params.nEVs_Count=0;
MC_params.nEVs_Count_ALL=0;
MC_params.nEVs_Count_Time=zeros(1,MC_params.periods_per_day);
MC_params.nEVs_StartTime=zeros(1,MC_params.nEVs);
MC_params.nEVs_SOC=zeros(1,MC_params.nEVs);
MC_params.nEVs_SOC_Time=zeros(MC_params.periods_per_day,MC_params.nEVs);
MC_params.nEVs_EChargeTime=zeros(1,MC_params.nEVs);
MC_params.J_max=0;              %���ʱ�����
MC_params.nEVs_No=0;            %�綯�������
MC_params.nEVs_No_Count=0;      %�綯������ż���
MC_params.Y=zeros(BCS_params.nPiles,1);
MC_params.S=zeros(BCS_params.nPiles,MC_params.periods_per_day); %���վ״̬����
MC_params.C=zeros(BCS_params.nPiles,MC_params.periods_per_day); %���վ״̬����
MC_params.C_ALL=zeros(BCS_params.nPiles,MC_params.periods_per_day);
MC_params.V0G_ChargeLoad=zeros(1,MC_params.periods_per_day*2);
MC_params.ChargeLoad=zeros(1,MC_params.periods_per_day*2);
MC_params.A=ones(MC_params.periods_per_day,1);
MC_params.B=ones(1,MC_params.periods_per_day);

%% ����ʵ�ʳ�繦��
Behavious.ConventionalLoad_Hour=[
    1426.39 1445.58 1426.39 1416.39 1426.39 1491.22 ...
    1512.84 1523.64 1512.84 1426.39 1399.37 1275.10 ...
    1188.66 1048.18 832.06 780.22 768.64 812.06 884.48 ...
    1069.70 1170.66 1275.10 1404.78 1426.39 1426.39
    ];  %��12�㿪ʼÿСʱ���渺��
Behavious.ConventionalLoad_Hour=BCS_params.DTF_PowerFactor*Behavious.ConventionalLoad_Hour; %ʵ�ʳ��渺��
BCS_params.CP_TFCap_ratio=zeros(1,96);  %��繦��ռ��ѹ�������ı���
for i=1:MC_params.periods_per_day   %24Сʱ�ֲ����Ի�Ϊ96��ʱ��
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
Behavious.ConventionalLoad_Min=BCS_params.DTF_Cap*BCS_params.CP_TFCap_ratio;  %96ʱ�γ��渺��
Behavious.CP_max=(BCS_params.DTF_Cap*MC_params.B-Behavious.ConventionalLoad_Min)*BCS_params.DTF_PowerFactor;     %ʵ������縺��

%% �綯����MCģ��
for t=1:MC_params.periods_per_day   %������12�㿪ʼ����(�ӵ�50��ʱ�ο�ʼ����), 12.25Ϊ��һ��ʱ���
    Behavious.StartTime=12.25+0.25*(t-1);
    % ��ʼ���ʱ���복������MCģ��
    if Behavious.StartTime>24
        Behavious.StartTime=Behavious.StartTime-24;
    end
    Behavious.StartTime_us=17.6;    %��ʼ���ʱ������ܶȺ�������
    Behavious.StartTime_ds=3.4;     %��ʼ���ʱ������ܶȺ�����׼��
    %��ʼ���ʱ������ܶȺ���
    if Behavious.StartTime>(Behavious.StartTime_us-12)
        Behavious.StartTime_fs=@(x)1/(Behavious.StartTime_ds*(2*pi)^0.5).*exp(-(x-Behavious.StartTime_us).^2./(2*Behavious.StartTime_ds^2)); %(us-12)<x<=24
    else
        Behavious.StartTime_fs=@(x)1/(Behavious.StartTime_ds*(2*pi)^0.5).*exp(-(x+24-Behavious.StartTime_us).^2./(2*Behavious.StartTime_ds^2)); %0<x<=(us-12)
    end
    Behavious.s_ts=integral(Behavious.StartTime_fs,Behavious.StartTime-0.25,Behavious.StartTime);  %0.25Сʱʱ���ڵĸ���
    MC_params.nEVs_Count=round(Behavious.s_ts*MC_params.nEVs);  %��ʱ�ν���ĵ綯��������
    MC_params.nEVs_Count_Time(t)=MC_params.nEVs_Count;
    MC_params.nEVs_Count_ALL=MC_params.nEVs_Count_ALL+MC_params.nEVs_Count;

    for i=1:MC_params.nEVs_Count
        %% ��ʼSOC��MCģ��
        Behavious.StartSOC_ud=3.2;      %��ʼSOC�����ܶȺ�������
        Behavious.StartSOC_dd=0.88;     %��ʼSOC�����ܶȺ�����׼��
        %��ʼSOC�����ܶȺ���
        Behavious.StartSOC=0.9-15*lognrnd(Behavious.StartSOC_ud,Behavious.StartSOC_dd)/(100*EV_params.Cap);
        while Behavious.StartSOC<0.1 || Behavious.StartSOC>=0.3
            Behavious.StartSOC=0.9-15*lognrnd(Behavious.StartSOC_ud,Behavious.StartSOC_dd)/(100*EV_params.Cap);
        end
        Behavious.StartSOC=fix(Behavious.StartSOC*100)/100;
        % Ԥ�ڳ��ʱ��ʱ���MCģ��
        %Ԥ�ڳ��ʱ������ܶȺ���
        Behavious.EChargeTime_Hour=2+6*rand(1);
        while Behavious.EChargeTime_Hour>=8 || Behavious.EChargeTime_Hour<=2
            Behavious.EChargeTime_Hour=8*rand(1);
        end
        Behavious.EChargeTime_Min=ceil((Behavious.EChargeTime_Hour*60)/15);
        %�ж��Ƿ�����Ԥ�����ʱ���ڴﵽ�������պɵ�״̬
%         if (0.25*Behavious.EChargeTime_Min*BCS_params.P>((0.9-Behavious.StartSOC)*EV_params.Cap))
            MC_params.nEVs_No=MC_params.nEVs_No+1;
            MC_params.nEVs_StartTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=t;
            MC_params.nEVs_SOC(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=Behavious.StartSOC;
            MC_params.nEVs_Consumption(t,MC_params.nEVs_No_Count+MC_params.nEVs_No)=(1-Behavious.StartSOC)*EV_params.Cap;
            MC_params.nEVs_EChargeTime(1,MC_params.nEVs_No_Count+MC_params.nEVs_No)=Behavious.EChargeTime_Min;
%         end
    end
    MC_params.nEVs_No_Count=MC_params.nEVs_No_Count+MC_params.nEVs_No;
    MC_params.nEVs_No=0;
end

MC_params.nEVs_StartTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_SOC((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_SOC_Time(:,(MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];
MC_params.nEVs_EChargeTime((MC_params.nEVs_No_Count+1):MC_params.nEVs)=[];

MC_params.nEVs_CSOC_min=0.9*ones(MC_params.nEVs_No_Count,1);
MC_params.nEVs_CSOC_max=ones(MC_params.nEVs_No_Count,1);

%% �����縺������
MC_params.nEVs_Consumption_Time=sum(MC_params.nEVs_Consumption,2)';         %��ʱ���ܵ綯�����ĵ���
MC_params.nEVs_ChargeTime=sum(MC_params.nEVs_Consumption)./BCS_params.P;    %���綯�������ʱ��
MC_params.nEVs_ChargeTime=ceil((MC_params.nEVs_ChargeTime*60)/15);          %24Сʱת����15����
for i=1:MC_params.nEVs_No_Count
    if MC_params.nEVs_StartTime(i)==0
        MC_params.nEVs_StartTime(i)=MC_params.periods_per_day;
    end
    MC_params.ChargeLoad(MC_params.nEVs_StartTime(i):MC_params.nEVs_StartTime(i)+MC_params.nEVs_ChargeTime(i))=BCS_params.RCP;
    MC_params.V0G_ChargeLoad=MC_params.V0G_ChargeLoad+MC_params.ChargeLoad;
    MC_params.ChargeLoad=zeros(1,MC_params.periods_per_day*2);
end
for t=1:MC_params.periods_per_day
    if MC_params.V0G_ChargeLoad(t)>=BCS_params.nPiles*BCS_params.RCP*2
        MC_params.V0G_ChargeLoad(t)=BCS_params.nPiles*BCS_params.RCP*2;
    end
end
MC_params.V0G_ChargeLoad=MC_params.V0G_ChargeLoad(1:96)+MC_params.V0G_ChargeLoad(97:192);   %�綯���������縺��

%% ���վ������ģ��
tic
for t=1:MC_params.periods_per_day
    % Ԥ���³��վ�������״̬
    MC_params.S(:,1)=0;
    MC_params.S=circshift(MC_params.S,-1,2);
    % Ԥ���³��վ�������Ʋ���
    MC_params.C(:,1)=0;
    MC_params.C=circshift(MC_params.C,-1,2);
    % �ж��Ƿ����³�����
    MC_params.EV_index=find(MC_params.nEVs_StartTime==t);
    if ~isempty(MC_params.EV_index)
        % ��¼�綯����SOC��Ԥ�ڳ��ʱ��
        MC_params.EV_Count=numel(MC_params.EV_index);
        MC_params.EV_SOC=MC_params.nEVs_SOC(MC_params.EV_index);
        MC_params.EV_EChargeTime=MC_params.nEVs_EChargeTime(MC_params.EV_index);
        % ȷ������ʱ�����
        MC_params.J_max=max([MC_params.EV_EChargeTime,MC_params.J_max]);
        % ���³��վ״̬����
        for n=1:BCS_params.nPiles
            if MC_params.S(n,1)==0
                MC_params.S(n,1:MC_params.EV_EChargeTime(MC_params.EV_Count))=1;
                MC_params.Y(n,1)=MC_params.EV_SOC(MC_params.EV_Count);
                MC_params.EV_Count=MC_params.EV_Count-1;
            end
            if MC_params.EV_Count==0
                break;
            end
        end
        % ���³��׮��Ӧ�綯����SOC����
        for n=1:BCS_params.nPiles
            if MC_params.S(n,1)==0
                MC_params.Y(n,1)=0;
            end
        end
        MC_params.SC=MC_params.S(:,1:MC_params.J_max);
        % �Ż�����
        yalmip('clear');
        % �������
        MC_params.X=sdpvar(BCS_params.nPiles,MC_params.J_max);
        % Լ������
        Algorithm.Constraints=[];
        for j=1:MC_params.J_max
            if (t+j-1)<=MC_params.periods_per_day
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.RCP*sum(MC_params.X(:,j).*MC_params.SC(:,j)))<=(Behavious.CP_max(t+j-1))];
            else
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.RCP*sum(MC_params.X(:,j).*MC_params.SC(:,j)))<=(Behavious.CP_max(t+j-1-96))];
            end
        end
        for n=1:BCS_params.nPiles
            if MC_params.Y(n,1)~=0
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*MC_params.periods_Hour*sum(MC_params.X(n,:).*MC_params.SC(n,:))+EV_params.Cap*MC_params.Y(n,1))>=EV_params.Cap*MC_params.nEVs_CSOC_min];
                Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*MC_params.periods_Hour*sum(MC_params.X(n,:).*MC_params.SC(n,:))+EV_params.Cap*MC_params.Y(n,1))<=EV_params.Cap*MC_params.nEVs_CSOC_max];
            end
        end
        % �������
        Algorithm.Objective=BCS_params.RCP*MC_params.periods_Hour*sum(sum(MC_params.X.*MC_params.SC).*(BCS_params.EPrice-BCS_params.TOU_EPrice_Min(t)));
        % ΪYALMIP���������ѡ��
        Algorithm.options = sdpsettings('solver','cplex','verbose',1);
        % �Ż�ģ��
        Algorithm.sol = optimize(Algorithm.Constraints,Algorithm.Objective,Algorithm.options);
        % ��������
        if Algorithm.sol.problem == 0
            Algorithm.solution = double(MC_params.S);
        else
            Algorithm.solution = double(MC_params.S);
            disp('Hmm, something went wrong!');
            sol.info
            yalmiperror(sol.problem)
        end
        MC_params.C=Algorithm.solution;
    end
    MC_params.EV_index=[];
    MC_params.C_ALL(:,t)=MC_params.C(:,1);
end
toc

%% ���ݷ���
Result.xaxis=0:0.25:23.75;
Result.TOU_EPrice=BCS_params.TOU_EPrice_Min;                %��ʱ���
Result.EPrice=BCS_params.EPrice*MC_params.B;                %�����
Result.ConventionalLoad=Behavious.ConventionalLoad_Min;     %���渺��
Result.nEVs_Count=MC_params.nEVs_Count_Time;                %��ʱ�ν��복����
Result.nEVs_StartTime=MC_params.nEVs_StartTime;             %��ʼ���ʱ��
Result.nEVs_SOC=MC_params.nEVs_SOC;                         %��ʼSOC
Result.nEVs_EChargeTime=MC_params.nEVs_EChargeTime;         %Ԥ��ͣ��ʱ��
Result.DTF_Cap=BCS_params.DTF_Cap*MC_params.B;              %����ѹ�������
Result.CP_max=Behavious.CP_max;                             %ʵ������縺��
Result.V0G_ChargeLoad=MC_params.V0G_ChargeLoad;
Result.V0G_Load_ALL=Behavious.ConventionalLoad_Min+Result.V0G_ChargeLoad;
Result.C=sum(MC_params.C_ALL);
Result.V1G_ChargeLoad=BCS_params.P*Result.C;
Result.V1G_Load_ALL=Behavious.ConventionalLoad_Min+Result.V1G_ChargeLoad;

tiledlayout(2,2)
% ���վ����������������
nexttile
hold on
title("���վ����������������")
stairs(Result.xaxis,Result.TOU_EPrice,'LineWidth',2,'Color',[0 0 0]);
stairs(Result.xaxis,Result.EPrice,'LineWidth',2,'Color',[1 0 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Price/��');
legend('TOU Electricity Price','Charging Price');
hold off
% ��ʱ�γ��վ����綯��������
nexttile
hold on
title("��ʱ�γ��վ����綯��������")
stairs(Result.xaxis,Result.nEVs_Count,'LineWidth',2,'Color',[0 0 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Count');
legend('Count of EV');
hold off
% �������������縺������
nexttile
hold on
title("�������������縺������")
plot(Result.xaxis,Result.CP_max,'LineWidth',2,'Color',[1 0 0]);
plot(Result.xaxis,Result.V0G_ChargeLoad,'LineWidth',2,'Color',[0 0 1]);
plot(Result.xaxis,Result.V1G_ChargeLoad,'LineWidth',2,'Color',[0 1 0]);
set(gca, 'XTick', [0 2 4 6 8 10 12 14 16 18 20 22 24]);
set(gca, 'XTickLabel', {'12:00','14:00','16:00','18:00','20:00','22:00','24:00','02:00','04:00','06:00','08:00','10:00','12:00'});
xlabel('Time/h');
ylabel('Load/kW');
legend('Max Charge Load','V0G Charge Load','V1G Charge Load');
hold off
% �ܸ�������
nexttile
hold on
title("�ܸ�������")
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


%% �綯�������������
EV_params=Parans_Init().EV_params;      %�綯��������
BCS_params=Parans_Init().BCS_params;    %���վ����
Basic_params=Parans_Init().Basic_params;    %��������

%% ���渺�ɼ���
% run("ConvLoad_CALC.m");

%% �綯����MCģ��
% run("MC_SIM.m");

%% �綯���������縺�ɼ���
% run("V0G_CLoad_CALC.m");

%% �綯����������ģ��
% run("V1G_SIM.m");

%% ���ݷ���
run("Data_ANAL.m");

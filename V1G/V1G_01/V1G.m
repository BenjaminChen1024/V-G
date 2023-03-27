close all;
clc;
clear;
 
 
%% ��������
 
%==(1)�����ɺ�����===
L_b=[
    1648181.19
    1510114.92
    1404600.51
    1348140.62
    1355294.53
    1380434.41
    1472398.73
    1619859.88
    1774726.71
    1891739.09
    2024589.36
    2154006.65
    2214969.44
    2248348.3
    2257444.05
    2253898.58
    2251095.52
    2240891.11
    2187658.11
    2060455.55
    2032531.95
    1984614.47
    1846244.76
    1676395.15];
 
%====(2)Ԥ��Ļ������ɣ�ƽ�������� = 0.089��====
P_L_b1=[
    1737223.863
    1603267.075
    1501043.33
    1434323.708
    1427034.265
    1445808.13
    1535646.84
    1703557
    1878913.403
    2041190.428
    2189203.243
    2300813.958
    2376838.56
    2431838.998
    2456820.033
    2472628.88
    2497750.498
    2502256.753
    2487853.418
    2333072.535
    2313458.498
    2278059.543
    2121749.573
    1908084.005];
 
 
%====(3)Ԥ��Ļ������ɣ�ƽ�������� = 0.0414��====
P_L_b2=[
    1599948.91
    1468345.518
    1370502.199
    1310946.046
    1308525.559
    1330298.288
    1417044.254
    1592177.276
    1774327.31
    1935791.394
    2081450.673
    2194127.508
    2266347.528
    2310264.895
    2317806.969
    2328853.886
    2350763.395
    2356239.943
    2340220.599
    2215920.234
    2192252.838
    2168526.739
    2014122.374
    1803843.804];
 
%=====(4)�ڶ���Ԥ��Ļ������ɣ����õ�Ԥ�⣩��ƽ��������=0.0234��===
P_L_b3=[
    1648037.519
    1458944.669
    1366366.043
    1310276.476
    1309105.99
    1329282.055
    1411672.493
    1587762.671
    1728429.463
    1888917.875
    2032770.183
    2133804.711
    2199858.463
    2240117.111
    2241852.165
    2245048.574
    2259487.69
    2260142.395
    2243557.341
    2145562.018
    2122157.145
    2104126.554
    1948760.596
    1740961.875];
 
%=====ѡ��ʹ���ĸ�Ԥ�⸺��====
P_L_b=P_L_b2;
 
%% ΢�����Ļ�������
Scale_factor=1/1500;
L_b_mic=L_b*Scale_factor;  % ��������
P_L_b_mic=P_L_b*Scale_factor;  % ����Ԥ�⸺��
 
%% �۸�ģ��
% alfa=1.0;
% theta=1;
omega=1.2*max(L_b_mic);
k_0=0.0001;
k_1=0.00012;
k_2=0;
%====(1)���������ɱ�======
beta=0.001;
beta=0;
 
%===�򵥳˷�����=====
% k_con=alfa/(omega^theta*(theta+1));
 
%=====�����ʱ��======
tau=1; % Сʱ��
 
%=====�������========
num_slot=length(L_b_mic);
 
%====(2)�����۸�=======
price_basic=zeros(num_slot,1); % ���ڻ������ɵļ۸�
for i=1:num_slot
    price_basic(i)=k_0+k_1* L_b_mic(i);
end
fprintf('�۸���ͼ۸�=%g,��߼۸�=%g.\n',min(price_basic), max(price_basic));

%% �綯����EV����
Cap_battery_org=16; % KWh
gamma=0.9; % ������ʱ��صİٷֱ�
Cap_battery=gamma*Cap_battery_org;
 
%% ==�������===
P_max=5; % KW
 
%% �綯��������
num_EV=200;
 
% ������س��ĵ綯�����İٷֱ�
P_Chg=0;
 
% CHG EVs����
num_CHG_EV=round(P_Chg*num_EV);  % CHG EV ��λ�� EV ��Ϣ�����ǰ�沿�֡�
% V2G EVs����
num_V2G_EV=num_EV-num_CHG_EV;
 
%% �綯�������ģʽ
% 30% �ĵ綯�����ڼ�� 1 ֮ǰ���ӵ����վ������ľ��ȷֲ�
 
%EV����1) ����ʱ�䣬2) ����ʱ�䣬3) ��ʼ������4) ������ڣ�5) ��С���ʱ��%
 
EV_info=zeros(num_EV,3);
% ===���1ǰ����վ��EVS�ٷֱ�====
Per_EV=0.1;
% =====������������ʱ����ȷֲ���[  1,20 ]֮��======
for i=1:num_EV
    temp_00=rand;
    if temp_00<=Per_EV
        T_arrival(i,1)=1;
    else
        T_arrival(i,1)=round(1 + (20-1).*rand);
    end
end

% =====���ʱ����ȷֲ��� [4, 12] Сʱ֮��======
T_charging= round(4 + (12-4).*rand(num_EV,1));
T_charging=-1*sort(-1*T_charging);

% the departure time
for i=1:num_EV
    T_departure(i,1)=min(24, T_arrival(i,1)+T_charging(i,1));
end
% ====��ʼ�������ȷֲ��ڵ��������[0 0.8]֮��======
Ini_percentage=0+ (0.8-0).*rand(num_EV,1);
% fill the EV_info
EV_info(:,1)=T_arrival;
EV_info(:,2)=T_departure;
EV_info(:,3)=Cap_battery_org*Ini_percentage;

for i=1:num_EV
    EV_info(i,4)=EV_info(i,2)-EV_info(i,1)+1; % �������
    EV_info(i,5)=EV_info(i,3)/P_max; % ��С���ʱ��
    if EV_info(i,4) < EV_info(i,5)
        fprintf('EV %g ���ʱ�䲻����.\n',i);
    end
end

% % save and load EV_info
% save EV_info.txt EV_info -ascii;
%  
% load EV_info.txt;
% EV_info=EV_info(1:num_EV,:);
 
%% �綯�����������Ĺ�ϵ
F=zeros(num_EV, num_slot);
G=ones(num_EV, num_slot);
for i=1:num_EV
    for j=EV_info(i,1):EV_info(i,2)
        F(i,j)=1;
        G(i,j)=0;
    end
end
F1=reshape(F',1,[]);
% F=ones(num_EV, num_slot);
%% ���ƻ�������
xx_1=1:num_slot;
figure;
yy_1(:,1)=L_b_mic;
yy_1(:,2)=P_L_b_mic;
plot(xx_1,yy_1);
ylabel('����[KW]');
xlabel('Сʱ��');
legend('ʵ�ʸ�����','Ԥ�⸺����');
%% ʹ��CVX���ߵ�V2Gȫ�����ŷ���
%��1����ʽԼ��: Ax=b
% ��2���Ż�����x=[z1, z2, ..., z_24, x11, x12, ...., x_100,24]'
num_OptVar=1*num_slot+num_slot*num_EV;
b_a=L_b_mic; %��һ����ʽԼ���ľ���
A1_a=zeros(num_slot, num_OptVar-1*num_slot);
A1=[eye(num_slot) A1_a];
 
A2_a=zeros(num_slot, num_OptVar-1*num_slot);
s_temp=0;
for i=1:num_slot
    for j=1:num_EV
        A2_a(i, (j-1)*num_slot+i)=F(j,i);
        % fprintf('Assign F(%g,%g)=%g, to A2_a(%g, %g).\n',j,i,F(j,i),i,(j-1)*num_slot+1);
        s_temp=s_temp+F(j,i);
    end
end
A2_b=zeros(num_slot, num_slot);
A2=[A2_b A2_a];
 
A_a=A1-A2;  % ��һ����ʽԼ���ľ���
clear A1 A2 A1_a A2_a A2_b;
 
%======��һ����ʽԼ���ľ���=====
B_1=zeros(num_EV, num_OptVar-1*num_slot);
for i=1:num_EV
    B_1(i,(i-1)*num_slot+1:(i-1)*num_slot+num_slot)=F(i,:);
end
temp_1=zeros(num_EV, num_slot);
B1=[temp_1 B_1];    % �ڶ���ʽԼ���ľ���
b_b=(Cap_battery/tau)*ones(num_EV,1)-EV_info(:,3);% �ڶ���ʽԼ���ľ���
clear  B_1  temp_1;
 
%�ϲ���ʽ����
% Eq_left=[A_a' B1']';
% Eq_right=[b_a' b_b']';
 
 
%% ======��ʽԼ��=====
Eq_L=A_a;
Eq_R=b_a;
clear  A_a  b_a;
%% ======����ʽԼ��=====
% ====1)��һ������ʽԼ��=====
In_1=zeros(num_EV*num_slot, num_OptVar);
for i=1:num_slot
    for j=1:num_EV
        In_1((i-1)*num_EV+j,num_slot+(j-1)*num_slot+1:num_slot+(j-1)*num_slot+i)=F(j,1:i);
        %         fprintf('set row %g, col %g:%g by using F(%g,1:%g).\n',(i-1)*num_EV+j,num_slot+(j-1)*num_slot+1,num_slot+(j-1)*num_slot+i,j,i);
    end
end
In_1=-1*In_1;  % ��һ������ʽ�����
In_b1=zeros(num_EV*num_slot, 1);    % ��һ������ʽ���ұ�, [EV1_slot1, EV2_slot1, ..., EV1_slot2, EV2_slot2,...]'
for i=1:num_slot
    In_b1( (i-1)*num_EV+1:(i-1)*num_EV+num_EV, 1 )= (1/tau)*EV_info(1:num_EV,3);
end
%=====2)�ڶ�������ʽԼ��=====
In_2=-1*In_1; %�ڶ�������ʽԼ�������
In_b2=zeros(num_EV*num_slot, 1);    % �ڶ�������ʽԼ�����ұ�, [EV1_slot1, EV2_slot1, ..., EV1_slot2, EV2_slot2,...]'
temp_b2=Cap_battery_org - EV_info(1:num_EV,3);
for i=1:num_slot
    In_b2( (i-1)*num_EV+1:(i-1)*num_EV+num_EV, 1 )= (1/tau)*temp_b2;
end
% ���ÿ���綯��(ȫ�����ŷ���)�ĵ���ˮƽ�ݻ�ͼ��
% figure;
% xxx=0:num_slot;
% plot(xxx,v_Energy_variation(1:40,:));
% ylabel('����[KWH]');
% xlabel('Сʱ��');
% legend('EV1','EV2','EV3','EV4','EV5','EV6','EV7','EV8','EV9','EV10');
% title('ȫ�����ŷ����еĵ��ܱ仯');
 
% ����ÿ���綯����������ˮƽ�ݻ�(�ֲ����ŷ���)
% figure;
% xxx=0:num_slot;
% plot(xxx,Energy_variation);
% ylabel('����[KWH]');
% xlabel('Сʱ��');
% legend('EV1','EV2','EV3','EV4','EV5','EV6','EV7','EV8','EV9','EV10');
% title('�ֲ����ŷ����еĵ��ܱ仯');
 
% ����ÿ��EV������ˮƽ�ݻ�(�ȷ��䷽��)
% figure;
% plot(xxx,N_Energy_variation);
% ylabel('����[KWH]');
% xlabel('Сʱ��');
% legend('EV1','EV2','EV3','EV4','EV5','EV6','EV7','EV8','EV9','EV10');
% title('���ȷ������ŷ����еĵ��ܱ仯');
 
% %����ÿ���綯�����ĳ����
% figure;
% EV_ID=65;
% energy_mmm(1,:)=v_Energy_variation(EV_ID,:);
% energy_mmm(2,:)=Energy_variation(EV_ID,:);
% energy_mmm(3,:)=N_Energy_variation(EV_ID,:);
% plot(xxx,energy_mmm);
% ylabel('���� [KWH]');
% xlabel('ʱ��(Hours)');
% legend('ȫ�����ŷ���','�ֲ����ŷ���','���ȷ��䷽��');
% title('�綯�����ĵ��ܱ仯');
 
figure;
% nnn(:,1)=v_x_Matrix(EV_ID,:)';%ȫ������
% nnn(:,2)=x_Matrix(EV_ID,:)';%�ֲ�����
% nnn(:,3)=N_x_Matrix(EV_ID,:)';%���ȷ���
% h=bar(xx,nnn);
% ylabel('����[KW]');
% xlabel('ʱ��(Hours)');
% legend('ȫ������','�ֲ�����','���ȷ���');
% title('ȫ�����ŷ����еĳ�ŵ�����');
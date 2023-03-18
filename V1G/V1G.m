close all;
clc;
clear;
 
 
%% 参数设置
 
%==(1)基本荷荷向量===
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
 
%====(2)预测的基本负荷（平均相对误差 = 0.089）====
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
 
 
%====(3)预测的基本负荷（平均相对误差 = 0.0414）====
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
 
%=====(4)第二次预测的基本负荷（更好的预测）（平均相对误差=0.0234）===
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
 
%=====选择使用哪个预测负荷====
P_L_b=P_L_b2;
 
%% 微电网的基本负荷
Scale_factor=1/1500;
L_b_mic=L_b*Scale_factor;  % 基本负荷
P_L_b_mic=P_L_b*Scale_factor;  % 基本预测负荷
 
%% 价格模型
% alfa=1.0;
% theta=1;
omega=1.2*max(L_b_mic);
k_0=0.0001;
k_1=0.00012;
k_2=0;
%====(1)寿命缩减成本======
beta=0.001;
beta=0;
 
%===简单乘法计算=====
% k_con=alfa/(omega^theta*(theta+1));
 
%=====充电间隔时间======
tau=1; % 小时内
 
%=====充电间隔数========
num_slot=length(L_b_mic);
 
%====(2)基本价格=======
price_basic=zeros(num_slot,1); % 基于基本负荷的价格
for i=1:num_slot
    price_basic(i)=k_0+k_1* L_b_mic(i);
end
fprintf('价格，最低价格=%g,最高价格=%g.\n',min(price_basic), max(price_basic));

%% 电动汽车EV容量
Cap_battery_org=16; % KWh
gamma=0.9; % 充电完成时电池的百分比
Cap_battery=gamma*Cap_battery_org;
 
%% ==最大充电率===
P_max=5; % KW
 
%% 电动汽车数量
num_EV=200;
 
% 仅给电池充电的电动汽车的百分比
P_Chg=0;
 
% CHG EVs数量
num_CHG_EV=round(P_Chg*num_EV);  % CHG EV 将位于 EV 信息矩阵的前面部分。
% V2G EVs数量
num_V2G_EV=num_EV-num_CHG_EV;
 
%% 电动汽车充电模式
% 30% 的电动汽车在间隔 1 之前连接到充电站，其余的均匀分布
 
%EV矩阵：1) 到达时间，2) 出发时间，3) 初始能量，4) 充电周期，5) 最小充电时间%
 
EV_info=zeros(num_EV,3);
% ===间隔1前接入站的EVS百分比====
Per_EV=0.1;
% =====其他车辆到达时间均匀分布在[  1,20 ]之间======
for i=1:num_EV
    temp_00=rand;
    if temp_00<=Per_EV
        T_arrival(i,1)=1;
    else
        T_arrival(i,1)=round(1 + (20-1).*rand);
    end
end

% =====充电时间均匀分布在 [4, 12] 小时之间======
T_charging= round(4 + (12-4).*rand(num_EV,1));
T_charging=-1*sort(-1*T_charging);

% the departure time
for i=1:num_EV
    T_departure(i,1)=min(24, T_arrival(i,1)+T_charging(i,1));
end
% ====初始电量均匀分布在电池容量的[0 0.8]之间======
Ini_percentage=0+ (0.8-0).*rand(num_EV,1);
% fill the EV_info
EV_info(:,1)=T_arrival;
EV_info(:,2)=T_departure;
EV_info(:,3)=Cap_battery_org*Ini_percentage;

for i=1:num_EV
    EV_info(i,4)=EV_info(i,2)-EV_info(i,1)+1; % 充电周期
    EV_info(i,5)=EV_info(i,3)/P_max; % 最小充电时间
    if EV_info(i,4) < EV_info(i,5)
        fprintf('EV %g 充电时间不合理.\n',i);
    end
end

% % save and load EV_info
% save EV_info.txt EV_info -ascii;
%  
% load EV_info.txt;
% EV_info=EV_info(1:num_EV,:);
 
%% 电动汽车与充电间隔的关系
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
%% 绘制基本负荷
xx_1=1:num_slot;
figure;
yy_1(:,1)=L_b_mic;
yy_1(:,2)=P_L_b_mic;
plot(xx_1,yy_1);
ylabel('负荷[KW]');
xlabel('小时数');
legend('实际负荷量','预测负荷量');
%% 使用CVX工具的V2G全局最优方案
%（1）等式约束: Ax=b
% （2）优化变量x=[z1, z2, ..., z_24, x11, x12, ...., x_100,24]'
num_OptVar=1*num_slot+num_slot*num_EV;
b_a=L_b_mic; %第一个等式约束的矩阵
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
 
A_a=A1-A2;  % 第一个等式约束的矩阵
clear A1 A2 A1_a A2_a A2_b;
 
%======第一个等式约束的矩阵=====
B_1=zeros(num_EV, num_OptVar-1*num_slot);
for i=1:num_EV
    B_1(i,(i-1)*num_slot+1:(i-1)*num_slot+num_slot)=F(i,:);
end
temp_1=zeros(num_EV, num_slot);
B1=[temp_1 B_1];    % 第二等式约束的矩阵
b_b=(Cap_battery/tau)*ones(num_EV,1)-EV_info(:,3);% 第二等式约束的矩阵
clear  B_1  temp_1;
 
%合并等式矩阵
% Eq_left=[A_a' B1']';
% Eq_right=[b_a' b_b']';
 
 
%% ======等式约束=====
Eq_L=A_a;
Eq_R=b_a;
clear  A_a  b_a;
%% ======不等式约束=====
% ====1)第一个不等式约束=====
In_1=zeros(num_EV*num_slot, num_OptVar);
for i=1:num_slot
    for j=1:num_EV
        In_1((i-1)*num_EV+j,num_slot+(j-1)*num_slot+1:num_slot+(j-1)*num_slot+i)=F(j,1:i);
        %         fprintf('set row %g, col %g:%g by using F(%g,1:%g).\n',(i-1)*num_EV+j,num_slot+(j-1)*num_slot+1,num_slot+(j-1)*num_slot+i,j,i);
    end
end
In_1=-1*In_1;  % 第一个不等式，左边
In_b1=zeros(num_EV*num_slot, 1);    % 第一个不等式，右边, [EV1_slot1, EV2_slot1, ..., EV1_slot2, EV2_slot2,...]'
for i=1:num_slot
    In_b1( (i-1)*num_EV+1:(i-1)*num_EV+num_EV, 1 )= (1/tau)*EV_info(1:num_EV,3);
end
%=====2)第二个不等式约束=====
In_2=-1*In_1; %第二个不等式约束，左边
In_b2=zeros(num_EV*num_slot, 1);    % 第二个不等式约束，右边, [EV1_slot1, EV2_slot1, ..., EV1_slot2, EV2_slot2,...]'
temp_b2=Cap_battery_org - EV_info(1:num_EV,3);
for i=1:num_slot
    In_b2( (i-1)*num_EV+1:(i-1)*num_EV+num_EV, 1 )= (1/tau)*temp_b2;
end
% 绘出每个电动车(全局最优方案)的电能水平演化图。
% figure;
% xxx=0:num_slot;
% plot(xxx,v_Energy_variation(1:40,:));
% ylabel('电能[KWH]');
% xlabel('小时数');
% legend('EV1','EV2','EV3','EV4','EV5','EV6','EV7','EV8','EV9','EV10');
% title('全局最优方案中的电能变化');
 
% 绘制每个电动汽车的能量水平演化(局部最优方案)
% figure;
% xxx=0:num_slot;
% plot(xxx,Energy_variation);
% ylabel('电能[KWH]');
% xlabel('小时数');
% legend('EV1','EV2','EV3','EV4','EV5','EV6','EV7','EV8','EV9','EV10');
% title('局部最优方案中的电能变化');
 
% 绘制每个EV的能量水平演化(等分配方案)
% figure;
% plot(xxx,N_Energy_variation);
% ylabel('电能[KWH]');
% xlabel('小时数');
% legend('EV1','EV2','EV3','EV4','EV5','EV6','EV7','EV8','EV9','EV10');
% title('均等分配最优方案中的电能变化');
 
% %绘制每辆电动汽车的充电率
% figure;
% EV_ID=65;
% energy_mmm(1,:)=v_Energy_variation(EV_ID,:);
% energy_mmm(2,:)=Energy_variation(EV_ID,:);
% energy_mmm(3,:)=N_Energy_variation(EV_ID,:);
% plot(xxx,energy_mmm);
% ylabel('电能 [KWH]');
% xlabel('时间(Hours)');
% legend('全局最优方案','局部最优方案','均等分配方案');
% title('电动汽车的电能变化');
 
figure;
% nnn(:,1)=v_x_Matrix(EV_ID,:)';%全局最优
% nnn(:,2)=x_Matrix(EV_ID,:)';%局部最优
% nnn(:,3)=N_x_Matrix(EV_ID,:)';%均等分配
% h=bar(xx,nnn);
% ylabel('速率[KW]');
% xlabel('时间(Hours)');
% legend('全局最优','局部最优','均等分配');
% title('全局最优方案中的充放电速率');
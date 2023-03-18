clc; close all,clear;

%% 创建电动汽车基础参数
N = 10000; % 电动汽车数量
Car.Capcity = 35; % 电动汽车电池容量
Car.max = 0.9; % 电动汽车最大荷电容量
Car.min = 0.1; % 电动汽车最小荷电容量
Car.P = 0.1; % 每公里耗电量
Car.char = 4; % 充电功率/h

%% 起始充电时间概率分布
us=17.6; %概率密度函数期望
ds=3.4; %概率密度函数标准差
%% 起始充电时间概率密度函数
fs1=@(x)1/(ds*(2*pi)^0.5).*exp(-(x-us).^2./(2*ds^2)); %(us-12)<x<=24
fs2=@(x)1/(ds*(2*pi)^0.5).*exp(-(x+24-us).^2./(2*ds^2)); %0<x<=(us-12)
xs=linspace(0,24,N);
%% 起始充电时间概率分布曲线
fs_ts=fs2(xs).*(xs<=us-12)+fs1(xs).*(xs>us-12);
s_ts=trapz(xs,fs_ts);  %计算整个区间概率密度的积分
%% 蒙特卡洛法计算起始充电时间概率分布
n=0;
while n<N
    t=rand(1)*24; %生成[0,24]均匀分布随机数
    if t<=us-12
        ft_ts=fs2(t)/s_ts;
    else
        ft_ts=fs1(t)/s_ts;
    end
    r=rand(1); %生成[0,1]均匀分布随机数
    if r<=ft_ts %如果随机数r小于f(t)，接纳该t并加入序列a中
        n=n+1;
        Car_in(n)=t; %随机生成起始充电时间
    end
end
num=96; %分24个区间统计
[xt,ct]=hist(Car_in,num); %统计不同区间出现的个数
dc=24/num; %区间大小
xt=xt/N/dc; %根据统计结果计算起始充电时间概率密度
%% 绘制起始充电时间概率密度曲线与概率密度直方图
figure(1);
tiledlayout(1,2)
nexttile
plot(Car_in,'x');
title('电动汽车起始充电时间分布');
xlabel('编号（No.）');
ylabel('时间（h）');
nexttile
bar(ct,xt,1,'b'); hold on; %根据统计结果画概率密度直方图
plot(xs,fs_ts,'r','lineWidth',2); hold off; %根据公式画概率密度曲线
title('电动汽车起始充电时间概率分布');
xlabel('时间（h）');
ylabel('概率密度');

%% 日行驶里程概率分布
ud=3.2; %概率密度函数期望
dd=0.88; %概率密度函数标准差
km=500; %模拟日形式里程最大值
%% 日行驶里程概率密度函数
fd=@(x)1./(x.*dd*(2*pi).^0.5).*exp(-(log(x)-ud).^2/(2*dd^2));
xd=linspace(0.1,km,N);
%% 日行驶里程概率分布曲线
fd_km=fd(xd);
s=trapz(xd,fd_km); %计算整个区间概率密度的积分
%% 蒙特卡洛法计算日行驶里程概率分布
n=0;
while n<N
    t=rand(1)*km; %生成[0,km]均匀分布随机数
    f_km=fd(t)/s;
    r=rand(1); %生成[0,1]均匀分布随机数
    if r<=f_km %如果随机数r小于f(t)，接纳该t并加入序列a中
        n=n+1;
        Car_km(n)=t; %随机生成日行驶里程概率
    end
end
num=100; %分100个区间统计
[x_km,c_km]=hist(Car_km,num); %统计不同区间出现的个数
dc=km/num; %区间大小
x_km=x_km/N/dc; %根据统计结果计算日行驶里程概率密度
%% 绘制日行驶里程概率密度曲线与概率密度直方图
figure(2);
tiledlayout(1,2)
nexttile
plot(Car_km,'x');
title('电动汽车日行驶里程分布');
xlabel('编号（No.）');
ylabel('行驶里程（km）');
nexttile
bar(c_km,x_km,1); hold on;  %根据统计结果画日行驶里程概率密度直方图
plot(xd,fd_km,'r','lineWidth',2); %hold off; %根据公式画日行驶里程概率密度曲线
title('电动汽车日行驶里程概率分布');
xlabel('行驶里程（km）');
ylabel('概率密度');

%% 电动汽车耗电量与充电时间分布
W = Car_km*Car.P;
T_char = W/Car.char;
figure(3)
tiledlayout(1,2)
nexttile
plot(W,'x');
title('电动汽车耗电量分布');
xlabel('编号（No.）');
ylabel('耗电量（KWH）');
nexttile
plot(T_char,'x');
title('电动汽车充电时间分布');
xlabel('编号（No.）');
ylabel('充电时间（t）');

%% 无序充电负荷曲线
T_char = round(T_char);
P_char_total = zeros(1,48);
P = zeros(1,48);
for n = 1:N
    start = uint8(Car_in(n));
    if start==0
        start=24;
    end
    t = uint8(T_char(n));
    P(start:start+t) = Car.char;
    P_char_total = P_char_total+P;
    P = zeros(1,48);
end
P_char_total = P_char_total(1:24)+P_char_total(25:48);
figure(5)
plot(P_char_total,'b','lineWidth',2);
title('电动汽车无序充电负荷曲线');
xlabel('充电时间(h)');
ylabel('充电功率(w)');
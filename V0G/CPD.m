clc; close all,clear;
%% 起始充电时间概率分布
us=17.6; %概率密度函数期望
ds=3.4; %概率密度函数标准差
N=10000; %模拟电动汽车数
%% 起始充电时间概率密度函数
fs1=@(x)1/(ds*(2*pi)^0.5).*exp(-(x-us).^2./(2*ds^2)); %(us-12)<x<=24
fs2=@(x)1/(ds*(2*pi)^0.5).*exp(-(x+24-us).^2./(2*ds^2)); %0<x<=(us-12)
xs=linspace(0,24,N);
%% 起始充电时间概率分布曲线
fs_ts=fs2(xs).*(xs<=us-12)+fs1(xs).*(xs>us-12);
s_ts=trapz(xs,fs_ts);  %计算整个区间概率密度的积分
fs_ts=fs_ts/s_ts; %归一化概率密度
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
        ts_rand(n)=t; %随机生成起始充电时间概率
    end
end
num=96; %分24个区间统计
[xt,ct]=hist(ts_rand,num); %统计不同区间出现的个数
dc=24/num; %区间大小
xt=xt/N/dc; %根据统计结果计算起始充电时间概率密度
%% 绘制起始充电时间概率密度曲线与概率密度直方图
figure;
bar(ct,xt,1,'b'); hold on; %根据统计结果画概率密度直方图
plot(xs,fs_ts,'r','lineWidth',2); hold off; %根据公式画概率密度曲线
title('电动汽车出行时间概率分布');
xlabel('时间（h）');
ylabel('概率密度');

%% 日行驶里程概率分布
ud=3.2; %概率密度函数期望
dd=0.88; %概率密度函数标准差
N=10000; %模拟电动汽车数
km=500; %模拟日形式里程最大值
%% 日行驶里程概率密度函数
fd=@(x)1./(x.*dd*(2*pi).^0.5).*exp(-(log(x)-ud).^2/(2*dd^2));
xd=linspace(0.1,km,N);
%% 日行驶里程概率分布曲线
fd_km=fd(xd);
s=trapz(xd,fd_km); %计算整个区间概率密度的积分
fd_km=fd_km/s; %归一化概率密度
%% 蒙特卡洛法计算日行驶里程概率分布
n=0;
while n<N
    t=rand(1)*km; %生成[0,km]均匀分布随机数
    f_km=fd(t)/s;
    r=rand(1); %生成[0,1]均匀分布随机数
    if r<=f_km %如果随机数r小于f(t)，接纳该t并加入序列a中
        n=n+1;
        km_rand(n)=t; %随机生成日行驶里程概率
    end
end
num=100; %分100个区间统计
[x_km,c_km]=hist(km_rand,num); %统计不同区间出现的个数
dc=km/num; %区间大小
x_km=x_km/N/dc; %根据统计结果计算日行驶里程概率密度
%% 绘制日行驶里程概率密度曲线与概率密度直方图
figure;
bar(c_km,x_km,1); hold on;  %根据统计结果画日行驶里程概率密度直方图
plot(xd,fd_km,'r','lineWidth',2); %hold off; %根据公式画日行驶里程概率密度曲线
title('电动汽车日行驶里程概率分布');
xlabel('行驶里程（km）');
ylabel('概率密度');
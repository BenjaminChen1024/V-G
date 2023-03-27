%% 初始化充电站数据
P = 100; %额定充电功率kW
St = 500; %配电变压器额定容量kW
lambda = 0.9; %充电负荷功率因数平均值

%% 初始化当日配电网负载信息以及当天电价信息
% 当日配电网负载信息
A = zeros(96, 1); %每日常规负荷曲线
A_j = zeros(96, 1); %允许充电的功率占配电变压器容量的比例
% 电价信息
V_j = [0.365,0.869,0.687]; % 电网购电的电价
P_j = 1; % 向电动汽车用户收取的充电电价

%% 

% 最大停留时间
t_max =  ; % 小时

% 计算时间段数
J = floor(t_max * 60 / 15);
S = zeros(n, J); % 电动汽车充电站状态矩阵

% 充电机状态矩阵
X = zeros(n, J);

% 充电控制程序的时间步长
delta_t = 15; % 分钟

% 计算功率
function [Pn_j] = compute_power(S, A, A_j, c_j, p_j, X)
    % 根据充电机状态矩阵计算各个充电机在不同时间段的充电功率
    Pn_j = zeros(size(X));
    for n = 1:size(X, 1)
        for j = 1:size(X, 2)
            if X(n, j) == 1
                Pn_j(n, j) = P;
            end
        end
    end

    % 根据当前时间、每日常规负荷曲线、允许充电的功率占配电变压器容量的比例、电价信息等计算电力系统的总负荷
    total_load = sum(A .* A_j .* Pn_j, 2);

    % 根据当前时间和电价信息计算购电成本
    purchase_cost = sum(A .* c_j);

    % 根据当前时间、充电机状态矩阵、充电功率等计算充电收益
    charging_profit = sum(A .* A_j .* X .* Pn_j .* p_j, 2);

    % 计算总的收益
    total_profit = sum(charging_profit) - purchase_cost;

    % 计算负载率
    load_factor = max(total_load) / S;
end

% 计算充电机状态
function [X] = compute_charging_states(S, A


% 有序充电优化程序
function [P_nj, S_nj] = ordered_charging_opt(S, P, S_max, lambda, A, c, p, J)
% 参数：
%   S: 充电站状态矩阵
%   P: 充电机的额定充电功率
%   S_max: 配电变压器的额定容量
%   lambda: 充电负荷功率因数平均值
%   A: 充电功率占配电变压器容量的比例
%   c: 充电站购电电价
%   p: 充电站售电电价
%   J: 时间段数

n = size(S, 1); % 充电机数量
c_k = c(1:J); % 当前时刻起到第J个时刻的购电电价
p_k = p(1:J); % 当前时刻起到第J个时刻的售电电价

% 构造线性规划模型
f = [-p_k'; c_k'];
Aeq = ones(1, 2*J);
beq = S_max*A;
lb = zeros(2*J, 1);
ub = [P*S.*S*lambda'; S.*S_max*lambda'];
options = optimoptions('linprog','Algorithm','dual-simplex','Display','off');
[x, ~] = linprog(f, [], [], Aeq, beq, lb, ub, options);

% 解析优化结果
P_nj = reshape(x(1:J*n), [n, J]);
S_nj = reshape(x(J*n+1:end), [n, J]);

end

% 主函数
function [P_nj, S_nj] = charging_station_optimization(S, P, S_max, lambda, A, c, p, t_max)
% 参数：
%   S: 充电站状态矩阵
%   P: 充电机的额定充电功率
%   S_max: 配电变压器的额定容量
%   lambda: 充电负荷功率因数平均值
%   A: 充电功率占配电变压器容量的比例
%   c: 充电站购电电价
%   p: 充电站售电电价
%   t_max: 所有车辆停留时间的最大值

J = floor(t_max/15); % 时间段数
P_nj = zeros(size(S, 1), J); % 初始化充电功率矩阵
S_nj = zeros(size(S, 1), J); % 初始化停车状态矩阵

for j = 1:J
    %
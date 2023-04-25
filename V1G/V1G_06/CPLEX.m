function C = CPLEX()

global EV_params;   %电动汽车参数
global BCS_params;  %充电站参数
global MC_params;   %MC模拟参数
global Behavious;   %用户行为
global Algorithm;   %优化算法

% 优化策略
yalmip('clear');
% 定义矩阵
MC_params.C=sdpvar(BCS_params.nPiles,MC_params.periods_per_day);
% 约束条件
Algorithm.Constraints=[(BCS_params.RCP*sum(MC_params.S))<=(BCS_params.DTF_Cap*MC_params.B-Behavious.ConventionalLoad_Min)];
Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*MC_params.periods_Hour*MC_params.S*MC_params.A+EV_params.Cap*(MC_params.nEVs_SOC'))>=EV_params.Cap*MC_params.nEVs_CSOC_min];
Algorithm.Constraints=[Algorithm.Constraints,(BCS_params.P*MC_params.periods_Hour*MC_params.S*MC_params.A+EV_params.Cap*(MC_params.nEVs_SOC'))<=EV_params.Cap*MC_params.nEVs_CSOC_max];
% for i=1:MC_params.nEVs_No_Count
%     for t=1:MC_params.periods_per_day
%         Algorithm.Constraints=[Algorithm.Constraints,MC_params.S(i,t)>=1];
%     end
% end
% 定义对象
Algorithm.Objective=BCS_params.RCP*MC_params.periods_Hour*sum(MC_params.S*(BCS_params.EPrice-(BCS_params.TOU_EPrice_Min')));
% 为YALMIP求解器设置选项
Algorithm.options = sdpsettings('solver','cplex','verbose',1);
% 优化模型
Algorithm.sol = optimize(Algorithm.Constraints,Algorithm.Objective,Algorithm.options);
% 分析错误
if Algorithm.sol.problem == 0
    Algorithm.solution = double(MC_params.S);
else
    Algorithm.solution = double(MC_params.S);
    disp('Hmm, something went wrong!');
    sol.info
    yalmiperror(sol.problem)
end
C=Algorithm.solution;
end

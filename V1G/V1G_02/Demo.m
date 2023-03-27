% 定义电动汽车队列
ev_queue = [1.5, 2, 0.75, 1.25, 3, 0.5]; % 电动汽车需要充电的时间（小时）
battery_capacity = [70, 90, 50, 60, 100, 40]; % 电动汽车的电池容量（度）

% 定义充电站参数
num_chargers = 4;
charge_fees = [0.5, 0.4, 0.3]; % 不同时间段的充电费用
energy_prices = [0.8, 0.6, 0.4]; % 不同时间段的能源价格
time_intervals = [0, 6, 18, 24]; % 时间段划分：[0, 6)、[6, 18)、[18, 24)

% 初始化状态
charging_status = zeros(1, num_chargers);
charge_time_left = zeros(1, num_chargers);
total_wait_time = 0;
total_charge_time = 0;
total_energy_cost = 0;
total_revenue = 0;

% 开始充电
for i = 1:length(ev_queue)
    % 找到空闲充电桩
    available_chargers = find(charging_status == 0);
    
    % 如果没有空闲充电桩，等待充电完成
    while isempty(available_chargers)
        % 更新充电状态和剩余充电时间
        [min_time_left, min_index] = min(charge_time_left);
        charge_time_left = charge_time_left - min_time_left;
        charging_status(charge_time_left &lt;= 0) = 0;
        total_wait_time = total_wait_time + min_time_left;
        
        % 找到空闲充电桩
        available_chargers = find(charging_status == 0);
    end
    
    % 在可用充电桩中选择电池容量低的电动汽车进行充电
    available_battery_capacity = battery_capacity(i:length(ev_queue));
    [~, best_ev_index] = min(available_battery_capacity);
    ev_index = i + best_ev_index - 1;
    
    % 根据时间段选择充电策略和充电费用
    current_time = mod(total_charge_time, 24);
    if current_time &lt; time_intervals(2)
        % 时间段1：[0, 6)
        charge_fee = charge_fees(1);
        energy_price = energy_prices(1);
    elseif current_time &lt; time_intervals(3)
        % 时间段2：[6, 18)
        charge_fee = charge_fees(2);
        energy_price = energy_prices(2);
    else
        % 时间段3：[18, 24)
        charge_fee = charge_fees(3);
        energy_price = energy_prices(3);
    end
    
    % 计算充电时间和充电费用
    charge_time = ev_queue(ev_index);
    charge_cost = charge_time * energy_price * battery_capacity(ev_index);
    
    % 如果充电费用高于充电费用，则不进行充电
    if charge_cost &gt;= charge_fee
        continue;
    end
    
    % 选择可用充电桩中最靠前的充电桩进行充电
    charger_index = available_chargers(1);
    charging_status(charger_index) = 1;
    charge_time_left(charger_index) = charge_time;
    
    % 更新统计信息
    total_charge_time = total_charge_time + charge_time;
    total_energy_cost = total_energy_cost + charge_cost;
    total_revenue = total_revenue + charge_fee;
end

% 输出统计结果
fprintf('Total wait time: %.2f hours\n', total_wait_time);
fprintf('Total charge time: %.2f hours\n', total_charge_time);
fprintf('Total energy cost: $%.2f\n', total_energy_cost);
fprintf('Total revenue: $%.2f\n', total_revenue);
fprintf('Profit: $%.2f\n', total_revenue - total_energy_cost);
% --- 汇报级：时域对比绘图 ---
figure('Color', 'w', 'Name', 'DDPG 主动抑振效果对比');

% 绘制波形
plot(error_raw.Time, error_raw.Data, 'Color', [0.7, 0.7, 0.7], 'LineStyle', ':', 'LineWidth', 1, 'DisplayName', '无控制 (Baseline)');
hold on;
plot(error_rl.Time, error_rl.Data, 'b', 'LineWidth', 1.2, 'DisplayName', 'DDPG 智能补偿');

% 美化
grid on; set(gca, 'GridLineStyle', ':');
xlabel('时间 (s)'); ylabel('跟踪误差 (mm)');
legend('Location', 'northeast');
title('机床末端动态跟踪误差对比分析 (Time Domain)');

% 计算抑振率 (RMS)
rms_raw = rms(error_raw.Data);
rms_rl = rms(error_rl.Data);
improvement = (rms_raw - rms_rl) / rms_raw * 100;
annotation('textbox', [0.15, 0.15, 0.3, 0.1], 'String', ...
    {['原始误差 RMS: ', num2str(rms_raw, '%.6f'), ' mm'], ...
     ['AI 补偿后 RMS: ', num2str(rms_rl, '%.6f'), ' mm'], ...
     ['振动幅值降低: ', num2str(improvement, '%.2f'), '%']}, ...
    'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', 'b');
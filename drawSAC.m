%% 发论文/PPT专用特写图：机床抑振性能 (Baseline vs SAC) 
clc;

% --- 1. 数据对齐 (自动拆盒提取纯数字) ---
if isa(error_raw, 'timeseries')
    err_base = error_raw.Data(:);
elseif isstruct(error_raw)
    err_base = error_raw.signals.values(:);
else
    err_base = double(error_raw(:));
end
err_sac = double(err_sac(:)); 

min_len = min(length(err_base), length(err_sac));
err_base = err_base(1:min_len);
err_sac  = err_sac(1:min_len);

% --- 2. 参数配置 ---
fs = 1000; % 采样频率
N = min_len;
t = (0:N-1) / fs;

% --- 3. 计算核心指标：RMS ---
rms_base = rms(err_base);
rms_sac  = rms(err_sac);
imp_sac  = (rms_base - rms_sac) / rms_base * 100;

% --- 4. 绘制高级对比图 ---
figure('Name', '低频主轨迹误差抑制特写', 'Position', [150, 150, 1200, 500], 'Color', 'w');

% 【左图：时域整体表现】
subplot(1, 2, 1);
plot(t, err_base, 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2); hold on; 
plot(t, err_sac,  'Color', [0 0.4470 0.7410], 'LineWidth', 1.8);          
grid on; set(gca, 'GridLineStyle', ':', 'FontSize', 11);
title('Time Domain Response (Overall)', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Time (s)', 'FontSize', 12); 
ylabel('Tracking Error (mm)', 'FontSize', 12);
legend('Baseline (Uncontrolled)', sprintf('SAC Control (%.2f%% RMS Red.)', imp_sac), 'Location', 'best');

% 【右图：频域低频特写 (核心亮点)】
fft_base = abs(fft(err_base - mean(err_base))) / N * 2;
fft_sac  = abs(fft(err_sac  - mean(err_sac)))  / N * 2;

f = fs * (0:(N/2)) / N;
fft_base = fft_base(1:N/2+1);
fft_sac  = fft_sac(1:N/2+1);

subplot(1, 2, 2);
% 使用半对数坐标系突出显示能量差异
semilogy(f, fft_base, 'Color', [0.6 0.6 0.6], 'LineWidth', 1.5); hold on;
semilogy(f, fft_sac,  'Color', [0 0.4470 0.7410], 'LineWidth', 2.0);
grid on; set(gca, 'GridLineStyle', ':', 'FontSize', 11);
title('Frequency Domain (Low-Frequency Detail)', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Frequency (Hz)', 'FontSize', 12); 
ylabel('Amplitude (Log Scale)', 'FontSize', 12);

% ⚠️ 核心视角锁定：只展示 0 ~ 0.5 Hz
xlim([0, 0.5]); 

% 动态调整 Y 轴，让曲线刚好撑满画面
low_f_idx = find(f <= 0.5);
min_y = min([fft_base(low_f_idx); fft_sac(low_f_idx)]);
max_y = max([fft_base(low_f_idx); fft_sac(low_f_idx)]);
ylim([max(min_y, 1e-4), max_y * 1.5]); 

legend('Baseline Error', 'SAC Compensated Error', 'Location', 'northeast');
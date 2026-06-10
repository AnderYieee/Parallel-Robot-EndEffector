%% PMT 自动化实验脚本：红线（原始） vs 蓝线（AI）
clear; clc;

% --- 1. 项目设置 ---
modelName = 'PMT_AI_Env_Version1_MatlabRL'; 
tcpSendPath = [modelName, '/TCP//IP Send'];
tcpRecvPath = [modelName, '/TCP//IP Receive'];

if ~bdIsLoaded(modelName), load_system(modelName); end
fprintf('🚀 开始自动化实验流程...\n');

%% --- 第一阶段：获取红线（Baseline - 无 AI） ---
fprintf('\n[1/2] 正在采集：原始对照组（红线）...\n');

set_param(tcpSendPath, 'Commented', 'on');
set_param(tcpRecvPath, 'Commented', 'on');

fprintf('   仿真运行中，请稍后...\n');
simOut = sim(modelName);

% 提取数据 (兼容 out 对象和直接变量)
if isprop(simOut, 'sim_error')
    error_raw = simOut.sim_error;
    fprintf('   ✅ 原始组数据提取成功。\n');
else
    error('❌ 错误：模型中没找到 sim_error。请确认 To Workspace 模块设置！');
end

%% --- 第二阶段：获取蓝线（AI 补偿） ---
fprintf('\n[2/2] 正在采集：AI 补偿组（蓝线）...\n');
fprintf('   ⚠️ 请确认 Python 端 test_rl.py 已启动并显示"环境已就绪"！\n');
input('   确认就绪后，按 Enter 键继续...', 's');

set_param(tcpSendPath, 'Commented', 'off');
set_param(tcpRecvPath, 'Commented', 'off');

fprintf('   仿真进行中，请观察 Python 终端...\n');
try
    simOut_rl = sim(modelName);
    error_rl = simOut_rl.sim_error;
    fprintf('   ✅ AI 组数据提取成功。\n');
catch ME
    fprintf('   ❌ 运行失败：可能是 Python 没连上。错误信息：%s\n', ME.message);
    return;
end

%% --- 第三阶段：自动绘图与对比 ---
fprintf('\n📊 正在生成对比分析报表...\n');

% 计算关键指标 (强制转换为标量)
r_data = error_raw.Data;
a_data = error_rl.Data;
rms_raw = rms(double(r_data));
rms_rl = rms(double(a_data));
imp = (rms_raw - rms_rl) / rms_raw * 100;

figure('Color', 'w', 'Name', 'DDPG 主动抑振效果对比', 'Position', [200, 200, 900, 700]);

% 子图 1: 时域波形
subplot(2,1,1);
plot(error_raw.Time, r_data, 'Color', [0.7, 0.7, 0.7], 'LineStyle', '--', 'DisplayName', 'Baseline');
hold on;
plot(error_rl.Time, a_data, 'b', 'LineWidth', 1.2, 'DisplayName', 'DDPG AI');
grid on; xlabel('时间 (s)'); ylabel('误差 (mm)');
legend('Location', 'northeast'); title('时域跟踪误差对比');

% 子图 2: 频域分析 (FFT - 修复索引问题)
subplot(2,1,2);
Fs = 1/mean(diff(error_raw.Time)); 
L = length(r_data);
f = Fs*(0:floor(L/2))/L; % 修复 1：使用 floor 确保整数索引

Y_raw = fft(double(r_data)); 
P2_raw = abs(Y_raw/L);
P1_raw = P2_raw(1:floor(L/2)+1); % 修复 2：确保整数索引
P1_raw(2:end-1) = 2*P1_raw(2:end-1);

Y_rl = fft(double(a_data)); 
P2_rl = abs(Y_rl/L);
P1_rl = P2_rl(1:floor(L/2)+1);
P1_rl(2:end-1) = 2*P1_rl(2:end-1);

semilogy(f, P1_raw, 'Color', [0.7, 0.7, 0.7], 'LineStyle', ':', 'DisplayName', 'Baseline');
hold on;
semilogy(f, P1_rl, 'b', 'DisplayName', 'DDPG AI');
grid on; xlim([0, 500]); xlabel('频率 (Hz)'); ylabel('幅值');
legend; title('误差信号频谱分析 (FFT)');

% --- 打印报告 (修复 fprintf 报错) ---
fprintf('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('📊 实验报告：\n');
fprintf('   - 原始误差 RMS: %.6f mm\n', rms_raw);
fprintf('   - AI 补偿后 RMS: %.6f mm\n', rms_rl);
% 修复 3：拆分打印，避免 %% 引起歧义
fprintf('   - 核心抑振率: %.2f ', imp);
fprintf('%%\n'); 
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
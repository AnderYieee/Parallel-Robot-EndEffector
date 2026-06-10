%% PMT 机床全自动 RL 联合训练(含连接保护)
clear; clc;
% 路径自适应与模型锁定
projectPath = fileparts(mfilename('fullpath')); 
cd(projectPath); 
addpath(genpath(projectPath)); 

mdl = 'PMT_AI_Env_Version1_MatlabRL';

try
    load_system(mdl); % 尝试后台加载模型
    open_system(mdl); % 打开窗口供观察
catch
    error('❌ 找不到模型文件 %s.slx，请确认它在当前文件夹！', mdl);
end

disp('========================================');
disp('🚀 项目: PMT_RL_Project');
disp('📢 正在检查 Python 端状态...');
disp('请确保 train_rl.py 已经显示"等待 Simulink 连入"');
disp('========================================');

max_episodes = 20000; 
for i = 1:max_episodes
    fprintf('▶ [Episode %d] 准备启动...\n', i);
    
    try
        % 尝试启动仿真
        set_param(mdl, 'SimulationCommand', 'start');
        
        % 等待 1 秒确认是否真的跑起来了
        pause(1);
        
        % 实时监控仿真状态
        % 如果状态一直不是 'stopped'，说明 TCP/IP 握手成功，正在传输数据
        while ~strcmp(get_param(mdl, 'SimulationStatus'), 'stopped')
            pause(0.5); 
        end
        
        fprintf('✅ [Episode %d] 正常结束，准备下一轮...\n', i);
        pause(1.5); % 给 Python 留出结算时间
        
    catch ME
        % 核心修改：检测"积极拒绝"错误
        if contains(ME.message, 'communication link') || ...
           contains(ME.message, '积极拒绝') || ...
           contains(ME.message, 'Connection refused')
            
            fprintf('\n❌ 致命错误：Python 服务器未响应！\n');
            fprintf('原因: %s\n', ME.message);
            fprintf('----------------------------------------\n');
            fprintf('请按以下顺序操作：\n');
            fprintf('1. 在 Python 终端重启 train_rl.py\n');
            fprintf('2. 确认看到"等待 Simulink 连入"字样\n');
            fprintf('3. 重新运行此脚本\n');
            fprintf('----------------------------------------\n');
            break; % 立即跳出循环，防止"瞬间启动一堆Episode"
        end
        
        % 如果是正常的仿真结束（Python 跑满了总步数关机）
        disp(' ');
        disp('🏁 联合训练已达到预设总步数，脚本自动终止。');
        break; 
    end
end
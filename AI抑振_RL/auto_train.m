%% PMT 机床全自动 RL 联合训练管家 (按键模拟版)
clear; clc;

% 1. 指定你的 Simulink 模型名称
mdl = 'PMT_AI_Env_Version1_MatlabRL';
open_system(mdl);

disp('========================================');
disp('开始全自动联合训练...');
disp('请确保 Python 端的 train_rl.py 已经运行并处于等待状态！');
disp('========================================');

max_episodes = 20000; 

for i = 1:max_episodes
    fprintf('▶ 正在启动第 %d 个 Episode...\n', i);
    
    try
        % 【关键修改】使用 set_param 模拟人工点击了绿色的 Run 按钮
        set_param(mdl, 'SimulationCommand', 'start');
        
        % 等待 1 秒钟让模型启动起来
        pause(1);
        
        % 实时监控：只要模型不是 'stopped' (停止) 状态，就一直耐心等
        while ~strcmp(get_param(mdl, 'SimulationStatus'), 'stopped')
            pause(0.5); % 每半秒看一眼进度条
        end
        
        % 跑完一回合后，强制歇 1.5 秒，让 Python 结算分数
        pause(1.5); 
        
    catch ME
        % 一旦 Python 10万步跑满关机，Simulink 连不上报错，就会跳到这里
        disp(' ');
        disp('✅ 捕获到 Python 端已断开连接（或者模型已训练完成保存）。');
        disp('自动循环完美终止！下班！');
        break; 
    end
end
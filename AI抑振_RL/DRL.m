%% PMT 机床 AI 减振强化学习训练脚本 
clear; clc;

mdl = 'PMT_AI_Env_Version0_MatlabRL';
open_system(mdl);

%1. 定义动作空间
% 允许 AI 最大输出 ±50 N.m 的微调力矩
actInfo = rlNumericSpec([1 1], 'LowerLimit', -50, 'UpperLimit', 50);
actInfo.Name = 'Delta_Torque';

%2. 定义状态空间 (Observation)
% Simulink 输入了 3 个信号 (指令、实际位置、当前误差)
obsInfo = rlNumericSpec([3 1]);
obsInfo.Name = 'Machine_States';

%3. 创建 Simulink 强化学习环境接口
% 指定模型名、Agent 模块的路径、状态和动作空间
blk = [mdl, '/RL Agent']; 
env = rlSimulinkEnv(mdl, blk, obsInfo, actInfo);

% 设定每次训练仿真跑 2 秒
env.ResetFcn = @(in) setVariable(in, 'Tf', 2); 

% 4. 创建 DDPG 智能体 (适用于连续动作控制)
agent = rlDDPGAgent(obsInfo, actInfo);

% 5. 设置训练参数
trainOpts = rlTrainingOptions(...
    'MaxEpisodes', 200, ...        % 最大训练回合数 
    'MaxStepsPerEpisode', 2000, ...% 每次跑多少步 (2秒 / 0.001步长)
    'ScoreAveragingWindowLength', 10, ...
    'Verbose', false, ...
    'Plots', 'training-progress',... % 开启训练进度曲线图
    'StopTrainingCriteria', 'AverageReward',...
    'StopTrainingValue', -5);      % 如果平均惩罚小于 -5，提前结束

disp('开始训练 AI...');
trainingStats = train(agent, env, trainOpts);
disp('训练完成！');
import os
from stable_baselines3 import SAC
from stable_baselines3.common.callbacks import CheckpointCallback

# ✅ 完美对齐导入：从 pmt_env 文件导入 PMTSimulinkEnv 类
from pmt_env import PMTSimulinkEnv

if __name__ == '__main__':
    # 1. 初始化带有平滑惩罚的新环境
    env = PMTSimulinkEnv()

    # 2. 配置日志与模型保存路径
    log_dir = "D:/PMT_RL_Project/RlDataOut/20260318/SAC_Evolution/"
    os.makedirs(log_dir, exist_ok=True)

    # 设置每 10000 步保存一次模型的自动化回调
    checkpoint_callback = CheckpointCallback(
        save_freq=10000, 
        save_path=log_dir,
        name_prefix='sac_pmt_model'
    )

    # 3. 初始化 SAC 智能体
    model = SAC(
        "MlpPolicy", 
        env, 
        learning_rate=3e-4, 
        buffer_size=100000, 
        batch_size=256,
        ent_coef='auto',     # 核心魔法：自动调节熵系数，使动作更加柔和
        gamma=0.99,
        verbose=1,
        tensorboard_log="./sac_pmt_tensorboard/"
    )

    print("🚀 开始 SAC 算法与平滑惩罚环境的联合训练...")

    # 4. 启动自动化迭代训练
    model.learn(
        total_timesteps=100000, 
        callback=checkpoint_callback,
        tb_log_name="SAC_Smooth_Run1"
    )

    # 训练结束后保存最终模型
    model.save(log_dir + "sac_pmt_final")
    print("✅ SAC 训练结束，模型已保存！")
import os
import gymnasium as gym
from stable_baselines3 import DDPG
from stable_baselines3.common.callbacks import CheckpointCallback
from pmt_env import PMTSimulinkEnv 

def train():
    # 路径锁定
    BASE_DIR = r"D:\PMT_RL_Project"
    OUT_DIR = os.path.join(BASE_DIR, "RlDataOut")
    LOG_DIR = os.path.join(OUT_DIR, "Training_Logs")
    
    if not os.path.exists(LOG_DIR):
        os.makedirs(LOG_DIR)

    # 实例化环境
    env = PMTSimulinkEnv() 

    model = DDPG(
        "MlpPolicy", 
        env, 
        verbose=1, 
        device="cpu",
        tensorboard_log=LOG_DIR 
    )

    checkpoint_callback = CheckpointCallback(
        save_freq=10000, 
        save_path=os.path.join(OUT_DIR, "Checkpoints"),
        name_prefix="pmt_vibration_v2"
    )

    print("\n" + "="*40)
    print("🚀 强化学习训练端已就绪！")
    print(f"项目目录: {BASE_DIR}")
    print("等待 MATLAB 启动 auto_train.m ...")
    print("="*40)

    try:
        # log_interval=1 确保每轮打印，解决 1KB 问题
        model.learn(
            total_timesteps=200000, 
            callback=checkpoint_callback,
            log_interval=1 
        )
        model.save(os.path.join(OUT_DIR, "final_model_v2"))
    except KeyboardInterrupt:
        print("\n🛑 训练被手动停止。")

if __name__ == '__main__':
    train()
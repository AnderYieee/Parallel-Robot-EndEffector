# 文件名: train_rl.py
from pmt_env import PMTSimulinkEnv
from stable_baselines3 import DDPG
import os
from datetime import datetime

# ==========================================
# 1. 自动生成时间戳与存储路径
# ==========================================
# 指定你的主输出文件夹
base_out_dir = r"D:\AI抑振_RL\RlDataOut"

# 如果这个文件夹不存在，Python 会自动帮你建一个
if not os.path.exists(base_out_dir):
    os.makedirs(base_out_dir)

# 获取当前时间，格式设为：年月日_时分秒 (例如 20260317_153022)
current_time = datetime.now().strftime("%Y%m%d_%H%M%S")

# 拼接出本次模型的最终保存名字和路径
model_filename = f"pmt_ddpg_model_{current_time}"
model_save_path = os.path.join(base_out_dir, model_filename)

# 顺便建一个专门存训练曲线数据(日志)的子文件夹
log_dir = os.path.join(base_out_dir, "Training_Logs")


# ==========================================
# 2. 初始化环境与 AI 大脑
# ==========================================
env = PMTSimulinkEnv()

print(f"即将开始训练，本次数据将输出至: {base_out_dir}")
print("正在初始化 DDPG 神经网络...")

# 把日志路径 (tensorboard_log) 也配置进去，它会自动记录每一次的得分和误差
model = DDPG("MlpPolicy", env, verbose=1, tensorboard_log=log_dir)


# ==========================================
# 3. 开始联合训练
# ==========================================
print("开始强化学习训练...")
# 这里的 100000 步可以根据你未来的需求随时改大
model.learn(total_timesteps=100000)


# ==========================================
# 4. 完美保存并下班
# ==========================================
model.save(model_save_path)
print("\n🎉 训练圆满结束！")
print(f"模型已成功保存至: {model_save_path}.zip")
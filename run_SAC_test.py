import os
from pmt_env import PMTSimulinkEnv
from stable_baselines3 import SAC

# --- 1. 启动环境 ---
env = PMTSimulinkEnv()

# --- 2. 配置文件路径 ---

MODEL_NAME = "sac_pmt_model_30000_steps" 

model_path = f"D:/PMT_RL_Project/RlDataOut/20260318/SAC_Evolution/{MODEL_NAME}"

# 防错检查
if not os.path.exists(model_path + ".zip"):
    print(f"\n❌ 致命错误：在文件夹里根本找不到 {MODEL_NAME}.zip")
    print("👉 解决办法：去 SAC_Evolution 文件夹里检查文件名。\n")
    exit()

# --- 3. 加载模型 ---
print(f"🔄 正在加载大脑: {MODEL_NAME}.zip ...")
model = SAC.load(model_path)

print("\n🚀 准备就绪，请切到 MATLAB 界面，点击 Run 启动测试！")

# --- 4. 开始闭环测试 ---
obs, info = env.reset()
done = False

while not done:
    # deterministic=True 代表关闭随机探索，输出确定的最优力矩
    action, _states = model.predict(obs, deterministic=True)
    obs, reward, terminated, truncated, info = env.step(action)
    done = terminated or truncated

print("\n✅ 测试回合结束！请前往 MATLAB 的 Workspace 查看最新的误差数据。")
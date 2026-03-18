# 文件名: test_rl.py
import os
import tkinter as tk
from tkinter import filedialog
from pmt_env import PMTSimulinkEnv
from stable_baselines3 import DDPG

# ==========================================
# 1. 弹出可视化窗口，选择历史模型
# ==========================================
base_out_dir = r"D:\AI抑振_RL\RlDataOut"

# 建立一个隐藏的图形界面主窗口
root = tk.Tk()
root.withdraw() 
# 把窗口顶置，防止被 MATLAB 挡住
root.attributes('-topmost', True) 

print("正在呼出模型选择器，请在弹出的窗口中挑选...")

# 呼出文件选择对话框
selected_model_path = filedialog.askopenfilename(
    initialdir=base_out_dir,
    title="👉 请选择你要测试的 AI 大脑 (.zip)",
    filetypes=(("RL Model", "*.zip"), ("All Files", "*.*"))
)

# 如果你点选了“取消”或者直接关了窗口
if not selected_model_path:
    print("❌ 未选择任何模型，测试取消。")
    exit()

print(f"\n✅ 成功加载指定模型: {selected_model_path}")

# ==========================================
# 2. 启动机床环境并注入灵魂
# ==========================================
env = PMTSimulinkEnv()
model = DDPG.load(selected_model_path, env=env)

# ==========================================
# 3. 开始一次真实的考试
# ==========================================
obs, info = env.reset()
print("一切准备就绪，请切到 MATLAB 中点击 Simulink 的 Run 按钮！")

while True:
    # deterministic=True 代表输出最优解
    action, _states = model.predict(obs, deterministic=True)
    obs, reward, terminated, truncated, info = env.step(action)
    
    if terminated or truncated:
        print("\n🎉 本次指定模型的测试圆满结束！可以直接去 Simulink 里看 Scope 波形了。")
        break
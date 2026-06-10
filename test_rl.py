import os
import tkinter as tk
from tkinter import filedialog
import gymnasium as gym
from pmt_env import PMTSimulinkEnv # 确保导入路径正确
from stable_baselines3 import DDPG

def test():
    # 1. 弹出可视化窗口，选择训练好的模型 (.zip)
    root = tk.Tk()
    root.withdraw() 
    root.attributes('-topmost', True) 

    # 默认指向你的新项目输出目录
    base_out_dir = r"D:\PMT_RL_Project\RlDataOut"
    
    print("="*40)
    print("🔍 正在呼出模型选择器，请挑选一个最优的 .zip 模型...")
    print("="*40)

    selected_model_path = filedialog.askopenfilename(
        initialdir=base_out_dir,
        title="👉 选择你要测试的 AI 模型 (.zip)",
        filetypes=(("RL Model", "*.zip"), ("All Files", "*.*"))
    )

    if not selected_model_path:
        print("❌ 未选择任何模型，测试取消。")
        return

    # 2. 启动机床环境 (注意：此时 pmt_env 内部已自动设为 50005 端口)
    print(f"\n✅ 成功加载模型: {os.path.basename(selected_model_path)}")
    env = PMTSimulinkEnv()
    
    # 加载模型并关联环境
    model = DDPG.load(selected_model_path, env=env)

    # 3. 开始一次真实的测试考核
    print("\n" + "!"*40)
    print("🚀 环境已就绪！请切换到 MATLAB，点击 Simulink 的 Run 按钮进行单次测试。")
    print("!"*40 + "\n")

    obs, info = env.reset()
    
    try:
        while True:
            # deterministic=True 代表使用 AI 的确定性最优策略，不带随机扰动
            action, _states = model.predict(obs, deterministic=True)
            obs, reward, terminated, truncated, info = env.step(action)
            
            if terminated or truncated:
                print("\n🎉 测试圆满结束！")
                print("请去 Simulink 查看 Scope 波形，对比抑振前后的效果。")
                break
    except KeyboardInterrupt:
        print("\n🛑 测试手动中止。")
    finally:
        env.close()

if __name__ == '__main__':
    test()
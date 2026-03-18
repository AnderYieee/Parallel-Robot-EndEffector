import socket
import struct
import numpy as np
import gymnasium as gym
from gymnasium import spaces

class PMTSimulinkEnv(gym.Env):
    def __init__(self):
        super(PMTSimulinkEnv, self).__init__()
        
        # 1. 定义动作空间 Action: 微调力矩 [-50, 50] N.m
        self.action_space = spaces.Box(low=-50.0, high=50.0, shape=(1,), dtype=np.float32)
        
        # 2. 定义状态空间 State: [目标位置, 实际位置, 跟踪误差]
        self.observation_space = spaces.Box(low=-np.inf, high=np.inf, shape=(3,), dtype=np.float32)
        
        # 3. 建立 TCP/IP 服务器
        self.host = '127.0.0.1'
        self.port = 50000
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # 加上这句，防止意外终止后端口被占用
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(1)
        print(f"等待 Simulink 模型在端口 {self.port} 连入...")
        
        self.conn = None
        self.state = np.zeros(3, dtype=np.float32) # 用于缓存最后一次的状态

    def reset(self, seed=None):
        super().reset(seed=seed)
        
        # 每次重置时，如果存在旧连接，先安全关闭
        if self.conn is not None:
            self.conn.close()
            self.conn = None

        print("\n==================================================")
        print("请在 MATLAB 中点击 Simulink 模型的 Run 按钮启动新一轮回合...")
        print("==================================================")
        
        self.conn, self.addr = self.server_socket.accept()
        print("Simulink 已成功连接，AI 开始本回合控制！")
        
        # 接收第一帧初始状态
        data = self.conn.recv(32)
        unpacked_data = struct.unpack('>4d', data)
        self.state = np.array(unpacked_data[0:3], dtype=np.float32)
        
        return self.state, {}

    def step(self, action):
        terminated = False
        truncated = False
        reward = 0.0

        try:
            # 1. 发送动作
            action_data = struct.pack('>d', float(action[0]))
            self.conn.sendall(action_data)
            
            # 2. 接收新状态
            data = self.conn.recv(32)
            if not data:
                raise ConnectionResetError("收到空数据，Simulink可能已结束仿真")
                
            unpacked_data = struct.unpack('>4d', data)
            self.state = np.array(unpacked_data[0:3], dtype=np.float32)
            reward = unpacked_data[3]
            
        except (ConnectionResetError, struct.error):
            # 【核心逻辑】：一旦捕获到 Simulink 断开，就判定为一个 Episode 结束！
            print("\n-> 检测到 Simulink 本轮仿真跑完。结算本回合...")
            terminated = True
            
        return self.state, reward, terminated, truncated, {}

    def close(self):
        if self.conn:
            self.conn.close()
        self.server_socket.close()
import gym
from gym import spaces
import numpy as np
import socket
import struct
import math

class PMT5AxisEnv(gym.Env):
    """
    五轴机床主动抑振强化学习环境 (SAC 适用)
    动作: 5维 (X, Y, Z, A, C 轴的补偿力矩)
    状态: 15维 (5个轴的 位置, 速度, 单轴误差) - 可根据实际 Simulink 输出调整
    """
    def __init__(self):
        super(PMT5AxisEnv, self).__init__()
        
        # 1. 动作空间: 5个轴的连续力矩输出，归一化到 [-1.0, 1.0]
        self.action_space = spaces.Box(low=-1.0, high=1.0, shape=(5,), dtype=np.float32)
        
        # 2. 状态空间: 假设 Simulink 返回 15 个双精度浮点数
        self.observation_space = spaces.Box(low=-np.inf, high=np.inf, shape=(15,), dtype=np.float32)
        
        # 3. TCP/IP 通信配置 (请确保与 Simulink 端的 TCPIP Server 参数一致)
        self.host = '127.0.0.1'
        self.port = 30000  # 根据你的 Simulink 配置修改
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))
        
        # 4. 初始化平滑惩罚项的历史动作记录
        self.last_action = np.zeros(5)
        self.k_factor = 2.0  # 五轴平滑惩罚系数 (五轴抖动更危险，建议调大)

    def step(self, action):
        """与 Simulink 进行一次步进交互"""
        # --- 1. 计算 5 维动作平滑惩罚 (核心防抖护身符) ---
        action_diff = np.sum(np.abs(action - self.last_action))
        smooth_penalty = self.k_factor * action_diff
        self.last_action = np.copy(action)
        
        # --- 2. 发送 5 维动作到 Simulink ---
        # '>5d' 表示大端模式下打包 5 个 double，占 40 字节
        send_data = struct.pack('>5d', action[0], action[1], action[2], action[3], action[4])
        self.socket.sendall(send_data)
        
        # --- 3. 接收 Simulink 的反馈数据 ---
        # 约定接收: 15个状态 + 1个基础Reward + 1个Done标志 = 17个 double
        # 17 * 8 bytes = 136 bytes
        recv_data = self.socket.recv(136)
        if not recv_data:
            raise ConnectionError("与 Simulink 的连接中断！")
            
        unpacked_data = struct.unpack('>17d', recv_data)
        
        # --- 4. 解析数据 ---
        state = np.array(unpacked_data[0:15], dtype=np.float32)
        sim_base_reward = unpacked_data[15]
        done = bool(unpacked_data[16])
        
        # 最终 Reward = Simulink算出的轮廓误差惩罚 - AI动作高频抖动惩罚
        total_reward = sim_base_reward - smooth_penalty
        
        info = {'sim_reward': sim_base_reward, 'penalty': smooth_penalty}
        
        return state, total_reward, done, info

    def reset(self):
        """重置环境"""
        self.last_action = np.zeros(5)
        
        # 发送特定的重置信号给 Simulink (例如发送 5 个 -999.0 表示重置)
        reset_signal = struct.pack('>5d', -999.0, -999.0, -999.0, -999.0, -999.0)
        self.socket.sendall(reset_signal)
        
        # 接收初始状态 (同 step 逻辑)
        recv_data = self.socket.recv(136)
        unpacked_data = struct.unpack('>17d', recv_data)
        state = np.array(unpacked_data[0:15], dtype=np.float32)
        
        return state

    def close(self):
        self.socket.close()
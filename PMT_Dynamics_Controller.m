%理论最优前馈力矩计算
function tau_cmd = PMT_Dynamics_Controller(xp, dxp, ddxp, v_limbs)
    % 输入: 
    % xp: [x, y, z, phi, theta]' 动平台位姿 (T&T angles) [cite: 1324]
    % dxp: [v_x, v_y, v_z, w_x, w_y, w_z]' 动平台速度 
    % ddxp: [a_x, a_y, a_z, dw_x, dw_y, dw_z]' 动平台加速度 [cite: 1388]
    % v_limbs: [v1, v2, v3, v4, v5]' 五个驱动支链的实际线速度 (用于计算摩擦力) [cite: 319-323]
    % 输出:
    % tau_cmd: [tau1, tau2, tau3, tau4, tau5]' 五个伺服电机的目标前馈力矩

    %% 0. 定义数学工具
    % 定义反对称矩阵算子 S(v)，用于计算叉乘 
    S = @(v) [0, -v(3), v(2); v(3), 0, -v(1); -v(2), v(1), 0];

    %% 1. 物理与几何参数化
    % 动平台真实辨识惯性参数 (摘自解老师论文 Table 2) [cite: 449-451]
    m_p = 45.32; 
    mp_es = 8.384; 
    I_xx = 6.24e-4; I_yy = 6.24e-4; I_zz = 1.03e-4;
    I_p_matrix = diag([I_xx, I_yy, I_zz]); % 忽略极小的耦合项 [cite: 343-344]
    g_vec = [0; 0; -9.81]; 

    % 驱动支链真实辨识摩擦力参数 (摘自论文 Table 1: [Tc, Ts, vs, Bv]) [cite: 452-454]
    Fric_Params = [
        186.21, 291.52, -1.87, 3.027; % Limb 1
        244.34, 372.97,  1.26, 3.766; % Limb 2
        187.89, 273.38,  1.35, 3.006; % Limb 3
        226.99, 314.07,  1.30, 3.489; % Limb 4
        224.82, 312.41,  2.69, 2.696  % Limb 5
    ];

    % 虚拟几何参数 (因原论文未公开，用于 DRL 环境预研构建)
    R_b = 0.5; % 基座分布半径 0.5m
    b = [
        0,  R_b*cos(pi/4), R_b*cos(3*pi/4), R_b*cos(5*pi/4), R_b*cos(7*pi/4);
        0,  R_b*sin(pi/4), R_b*sin(3*pi/4), R_b*sin(5*pi/4), R_b*sin(7*pi/4);
        0,  0,             0,               0,               0
    ];

    R_p = 0.15; % 动平台铰链分布半径 0.15m
    H_tool = -0.1; % 刀尖到平台铰链面的 Z 向距离
    p_local = [
        0,       R_p*cos(pi/4), R_p*cos(3*pi/4), R_p*cos(5*pi/4), R_p*cos(7*pi/4);
        0,       R_p*sin(pi/4), R_p*sin(3*pi/4), R_p*sin(5*pi/4), R_p*sin(7*pi/4);
        H_tool,  H_tool,        H_tool,          H_tool,          H_tool
    ];

    %% 2. 运动学正解与雅可比矩阵构建 (附录 A.1) [cite: 1318-1361]
    % (1) 计算旋转矩阵 R (基于 T&T angles, Eq. A-1) [cite: 1324-1327]
    phi = xp(4); theta = xp(5);
    p_vec = [cos(phi)*sin(theta); sin(phi)*sin(theta); cos(theta)];
    
    % 依据原论文的投影法生成正交旋转矩阵 R [cite: 1324-1328]
    O_B1 = b(:,1); 
    n_vec = cross(O_B1, p_vec); 
    if norm(n_vec) < 1e-6
        n_vec = [1;0;0]; % 奇异保护
    else
        n_vec = n_vec / norm(n_vec);
    end
    o_vec = cross(p_vec, n_vec);
    R = [n_vec, o_vec, p_vec];

    % (2) 运动传递雅可比 J_t (5x6 矩阵) 
    J_t = zeros(5, 6); 
    l_unit_all = zeros(3, 5); % 保存单位方向向量备用
    L_all = zeros(1, 5);      % 保存支链长度备用
    p_global_all = zeros(3, 5); % 保存全局坐标备用

    for i = 1:5
        p_i_global = R * p_local(:, i); % Eq. A-2 [cite: 1328-1329]
        p_global_all(:, i) = p_i_global;
        
        l_vec = (xp(1:3) + p_i_global) - b(:, i); % Eq. A-3 [cite: 1330-1331]
        L_i = norm(l_vec);
        L_all(i) = L_i;
        l_unit = l_vec / L_i; % Eq. A-3 [cite: 1332-1334]
        l_unit_all(:, i) = l_unit;
        
        J_t(i, :) = [l_unit', (cross(p_i_global, l_unit))']; % 组装 J_t 
    end
    
    % (3) 约束雅可比 J_c (1x6 矩阵，第一条 SPR 支链提供的一维约束) [cite: 1349, 155]
    % J_c = [n^T, (L_1(n x l_1) + p_1 x n)^T] 
    J_c = [n_vec', (L_all(1) * cross(n_vec, l_unit_all(:,1)) + cross(p_global_all(:,1), n_vec))'];

    % 组装完整满秩雅可比矩阵 J_a (6x6 矩阵) 
    J_a = [J_t; J_c]; 

    %% 3. 动力学受力分析 (附录 A.2 虚功原理) [cite: 1392-1400]
    % (1) 动平台惯性力和重力 F_p (Eq. A-12) [cite: 1397]
    w_p = dxp(4:6);   % 角速度
    dw_p = ddxp(4:6); % 角加速度
    a_c = ddxp(1:3);  % 线加速度
    
    F_p_trans = m_p * g_vec - m_p * a_c; 
    F_p_rot = -I_p_matrix * dw_p - cross(w_p, I_p_matrix * w_p);
    F_p = [F_p_trans; F_p_rot]; % 6x1 向量

    % (2) 支链惯性力简化 (为提高仿真速度，此处将支链质量等效附加到平台上)
    % 严格公式涉及大量的单连杆偏导数运算 F_i1, F_i2 [cite: 1399-1400]
    F_limbs_total = zeros(6, 1); 

    %% 4. 虚功反解理论刚体力矩 [cite: 1399-1400]
    % 求解: J_a' * [tau_ideal; F_constraint] = - F_p [cite: 1399-1400]
    Tau_and_Constraint = (J_a') \ (-F_p - F_limbs_total); 
    tau_ideal = Tau_and_Constraint(1:5); % 提取前5个主动电机的理论力矩

    %% 5. Stribeck 非线性摩擦力补偿 (Eq. 4) [cite: 318-323]
    f_friction = zeros(5, 1);
    for i = 1:5
        v = v_limbs(i);
        Tc = Fric_Params(i, 1);
        Ts = Fric_Params(i, 2);
        vs = Fric_Params(i, 3);
        Bv = Fric_Params(i, 4);
        
        f_friction(i) = (Tc + (Ts - Tc) * exp(-(v/vs)^2)) * sign(v) + Bv * v; [cite: 321-322]
    end

    %% 6. 输出最终前馈力矩指令 [cite: 1399-1400]
    tau_cmd = tau_ideal + f_friction;

end
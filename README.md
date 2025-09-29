# 分布式主动噪声控制 (ANC) MATLAB 仿真平台

这是一个使用 MATLAB 实现的模块化仿真平台，用于研究和比较集中式与分布式主动噪声控制算法。

## 项目概述

本项目旨在提供一个灵活的框架，用于在可定制的声学环境中仿真和评估不同的 ANC 系统。核心功能包括声学环境建模、网络拓扑定义以及多种 ANC 算法的实现。用户可以通过主脚本 `demo.m` 轻松配置和运行仿真。

## 主要特性

- **声学环境建模**: 使用 `acoustics.RIRManager` 类，通过**镜像声源法 (Image-Source Method)** 生成房间脉冲响应 (RIR)。
- **灵活的节点拓扑**: 支持通过 `topology.Network` 和 `topology.Node` 类自定义节点（传感器、执行器）的物理布局和通信网络。
- **算法实现**:
    - **集中式 FxLMS (CFxLMS)**: 一个传统的集中式 ANC 实现，作为基准。
    - **增强扩散 FxLMS (ADFxLMS)**: 一个先进的分布式算法，节点仅与其邻居节点通信，实现了去中心化控制。
- **模块化设计**: 项目采用面向对象的包（packages）结构，易于扩展和维护。
- **结果可视化**: 提供工具函数 `viz.plot_signals` 用于绘制期望信号和误差信号，直观评估算法性能。

## 项目结构

```
.
├── demo.m                # 主仿真脚本
├── +acoustics/
│   └── RIRManager.m      # 声学环境和 RIR 管理器
├── +algorithms/
│   ├── ADFxLMS.m         # 增强扩散 FxLMS 算法
│   ├── CFxLMS.m          # 集中式 FxLMS 算法
│   └── +ADFxLMS/
│       └── Node.m        # ADFxLMS 算法的特定节点实现
├── +topology/
│   ├── Network.m         # 定义节点间的通信网络
│   └── Node.m            # 定义基础物理节点
├── +utils/
│   └── wn_gen.m          # 带限白噪声生成工具
└── +viz/
    ├── plot_rir.m        # RIR 绘图工具
    └── plot_signals.m    # 信号对比绘图工具
```

## 如何运行

1.  打开 MATLAB。
2.  将当前目录切换到项目根目录。
3.  直接运行 `demo.m` 脚本：

    ```matlab
    >> demo
    ```

4.  仿真将依次运行 `ADFxLMS` 和 `CFxLMS` 算法，并在结束后输出仿真耗时和性能对比图。

## 核心组件详解

### `acoustics.RIRManager`

该类负责管理所有声学相关的参数：
- **房间属性**: 尺寸、混响时间、材料吸收/散射系数等。
- **声源/麦克风**: 管理主声源（噪声源）、次级声源（控制声源）和误差麦克风的位置。
- **RIR 计算**: 调用 `acousticRoomResponse` 函数生成主通路（P-M）和次级通路（S-M）的 RIR。

### `topology.Network` & `topology.Node`

这两个类共同定义了 ANC 系统的网络结构：
- `topology.Node`: 代表一个物理节点，包含其自身的 ID 以及关联的参考麦克风、次级扬声器和误差麦克风。
- `topology.Network`: 管理所有节点，并通过 `connectNodes` 方法定义节点之间的通信链接。

### `algorithms.ADFxLMS` & `algorithms.CFxLMS`

这是 ANC 算法的核心实现：
- `CFxLMS`: 所有节点的控制滤波器更新都依赖于全局的误差信号，需要一个中心控制器。
- `ADFxLMS`: 每个节点根据自身和邻居节点的信息进行协作，通过“扩散”策略更新其控制滤波器，无需中心控制器。`+ADFxLMS/Node.m` 为此算法扩展了节点类，增加了 `Phi` 和 `Psi` 等状态变量。

## 自定义仿真

您可以轻松地在 `demo.m` 脚本中修改参数以进行不同的仿真实验：

- **声学环境**: 修改 `mgr.Room`、`mgr.MaterialAbsorption` 等参数。
- **设备布局**: 使用 `mgr.addPrimarySpeaker`, `mgr.addSecondarySpeaker`, `mgr.addErrorMicrophone` 函数调整设备位置。
- **网络拓扑**: 在 `net.connectNodes` 中修改节点连接关系。
- **算法参数**: 调整 `params.L` (滤波器长度) 和 `params.mu` (步长) 等。

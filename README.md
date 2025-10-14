# 分布式主动噪声控制 (ANC) MATLAB 仿真平台

这是一个使用 MATLAB 实现的模块化仿真平台，用于研究和比较集中式与分布式主动噪声控制算法。

## 项目概述

本项目旨在提供一个灵活的框架，用于在可定制的声学环境中仿真和评估不同的分布式 ANC 系统。核心功能包括声学环境建模、网络拓扑定义以及多种 ANC 算法的实现。用户可以通过主脚本 `demo.m` 轻松配置和运行仿真。

## 项目结构

```
├── demo.m                # 主仿真脚本
├── +acoustics/
│   └── RIRManager.m      # 声学环境和 RIR 管理器
├── +algorithms/
│   ├── CFxLMS.m          # 集中式FxLMS
│   ├── Algorithm1.m      # 分布式 ANC 算法1实现
│   │   └── +Node/
│   │       └── Node.m    # Algorithm1 的特定节点实现
│   ├── Algorithm2.m      # 分布式 ANC 算法2实现
│   │   └── +Node/
│   │       └── Node.m    # Algorithm2 的特定节点实现
│   └── ...               # 更多算法
├── +topology/
│   ├── Network.m         # 定义节点间的通信网络
│   └── Node.m            # 定义基础物理节点
├── +utils/
│   └── wn_gen.m          # 带限白噪声生成工具
└── +viz/
    ├── plot_comparison.m # 性能对比绘图工具
    ├── plot_rir.m        # RIR 绘图工具
    └── plot_signals.m    # 信号对比绘图工具
```

## 依赖项

- **MATLAB** (R2025a 或更高版本)
- **Audio Toolbox**

## 如何运行

1.  打开 MATLAB。
2.  将当前目录切换到项目根目录。
3.  在命令窗口中运行 `demo` 脚本：

    ```matlab
    >> demo
    ```

4.  仿真将依次运行 `demo.m` 中包含的算法，并在结束后输出仿真耗时和性能对比图。

## 支持的算法

- **集中式 FxLMS (CFxLMS)**: 一个传统的集中式 ANC 实现，作为基准。所有节点的控制滤波器更新都依赖于全局的误差信号，需要一个中心控制器。
- **[增广扩散 FxLMS (ADFxLMS)](https://ieeexplore.ieee.org/abstract/document/10080983)**
- **[双向增广扩散 FxLMS (ADFxLMS)](https://doi.org/10.1121/10.0022573)**

## 核心组件详解

### `acoustics.RIRManager`

该类负责管理所有声学相关的参数：
- **房间属性**: 尺寸、采样率、墙壁、空气吸收率 等。
- **设备管理**: 管理主声源（噪声源）、次级声源（控制声源）和误差麦克风的位置。
- **RIR 计算**: 调用 Audio Toolbox 的acousticRoomResponse函数生成主通路（Primary-Mic）和次级通路（Secondary-Mic）的房间冲激响应 (RIR)。

### `topology.Network` & `topology.Node`

这两个类共同定义了 ANC 系统的网络结构：
- `topology.Node`: 代表一个物理节点，包含其自身的 ID 以及关联的参考麦克风、次级扬声器和误差麦克风。
- `topology.Network`: 管理所有节点，并通过 `connectNodes` 方法定义节点之间的通信链接（拓扑结构）。

> **注意**: 当前仿真使用理想参考信号，即直接使用主噪声源的信号。因此，在概念上“参考麦克风”的位置与“主扬声器”（噪声源）的位置是相同的。仿真程序中有关于此的变量命名有所混用。

### `algorithms` 包

`algorithms` 包中包含了各种 ANC 算法的核心实现。对于分布式算法，其节点可能需要存储额外信息（如邻居节点的滤波器状态），因此会在与算法同名的子包中定义一个继承自 `topology.Node` 的 `Node` 类，其中定义了额外的成员和方法。

### `viz` 包

`viz` 包提供了一系列可视化工具，用于分析仿真结果：
- `plotResults`: 绘制单个通道的期望信号和多个算法的误差信号进行时域和频域对比。
- `plot_rir`: 用于可视化生成的房间冲激响应。

## 自定义仿真

您可以轻松地在 `demo.m` 脚本中修改参数以进行不同的仿真实验：

- **声学环境**: 修改 `mgr.Room`、`mgr.MaterialAbsorption` 等参数。
- **设备布局**: 使用 `mgr.addPrimarySpeaker`, `mgr.addSecondarySpeaker`, `mgr.addErrorMicrophone` 函数调整设备位置。
- **网络拓扑**: 使用 `node.addRefMic`、 `node.addSecSpk`、`node.addErrMic` 函数配置节点，并使用 `net.connectNodes` 修改节点连接关系。
- **算法参数**: 调整 `params.L` (滤波器长度) 和 `params.mu` (步长) 等。

## To-Do
1. 修复主噪声源和参考麦克风命名混用的问题，对当前的理想参考信号模式通过显式的方式完成
2. 节点Id多处使用`dictionary`的`key`，变量中`key`和`id`也有类似混用问题，需要统一
3. 多处计算使用`for`循环实现，可以考虑构造矩阵进行矩阵计算以加速仿真
4. `topology.node`目前只支持连接一个参考麦克风、一个次级扬声器、一个误差麦克风，未来需要扩展以支持连接多个元件
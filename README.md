# 分布式主动噪声控制仿真平台

这是一个基于 MATLAB 的仿真平台，用于研究和比较不同的集中式和分布式主动噪声控制（ANC）算法。

## 功能

*   **声学环境建模**: 使用 `acoustics.RIRManager` 类来管理和生成房间脉冲响应（RIR）。支持镜像声源法来模拟不同房间尺寸、扬声器/麦克风布局以及墙面材料的声学特性。
*   **ANC 算法**:
    *   **集中式 FxLMS**: 实现标准的集中式Filtered-x LMS算法 (`algorithms.CFxLMS`)。
    *   **分布式 ADFxLMS**: 实现增广扩散FxLMS算法 (`algorithms.ADFxLMS`)，适用于分布式节点网络。
*   **节点网络**: 使用 `algorithms.Node` 类来定义分布式网络中的每个节点，包括其连接关系和负责的传感器/执行器。
*   **可视化**: 提供 `viz` 包中的工具，用于绘制脉冲响应 (`viz.plot_rir`) 和信号 (`viz.plot_signals`)，方便结果分析。

## 项目结构

```
.
├── +acoustics/         # 声学建模相关
│   └── RIRManager.m    # 房间脉冲响应管理器
├── +algorithms/        # ANC 算法
│   ├── +ADFxLMS/       # 分布式 ADFxLMS 算法
│   │   ├── ADFxLMS.m
│   │   └── AugmentedNode.m
│   ├── CFxLMS.m        # 集中式 FxLMS 算法
│   └── Node.m          # 分布式网络节点定义
├── +viz/               # 可视化工具
│   ├── plot_rir.m
│   └── plot_signals.m
├── demo.m              # 主仿真脚本
└── ...
```

## 如何运行

1.  打开 MATLAB。
2.  将项目根目录添加到 MATLAB 路径中。
3.  打开并运行 `demo.m` 脚本。

`demo.m` 脚本演示了如何：
-   配置 `RIRManager` 来定义声学场景（房间、扬声器、麦克风）。
-   生成所需的房间脉冲响应。
-   设置算法参数（如滤波器长度、步长）。
-   调用 ANC 算法进行仿真。
-   使用 `viz` 工具包可视化结果。

可以修改 `demo.m` 中的参数来测试不同的场景和算法性能。

## 核心组件

### `acoustics.RIRManager`
这个类是声学环境的核心。它负责计算所有主/次路径的脉冲响应。你可以配置房间大小、混响时间、传感器和执行器的位置等。

### `algorithms.CFxLMS`
一个函数，实现了传统的集中式 FxLMS 算法。所有误差信号都集中在一个控制器中进行处理。

### `algorithms.ADFxLMS`
实现了基于扩散策略的分布式 ANC 算法。网络中的每个 `Node` 仅与邻居节点通信，共同协作来抑制噪声。

### `algorithms.Node`
定义了分布式网络中的一个计算节点。它包含了节点的 ID、邻居信息以及它所控制的传感器和扬声器。

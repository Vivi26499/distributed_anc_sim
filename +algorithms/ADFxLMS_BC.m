function results = ADFxLMS_BC(params)
    % ADFxLMS-BC 分布式主动噪声控制FxLMS算法
    %
    % 输入:
    %   params: 包含所有仿真参数的结构体。
    %       - params.time: 离散时间轴
    %       - params.rirManager: RIRManager对象，用于获取脉冲响应
    %       - params.network: 通讯网络拓扑结构
    %       - params.L: 控制滤波器的长度
    %       - params.referenceSignal: 参考信号
    %       - params.desiredSignal: 期望信号
    %
    % 输出:
    %   results: 包含仿真结果的结构体。
    %       - results.errorSignal: 麦克风处的误差信号
    %       - results.controlSignal: 发送到扬声器的控制信号
    %       - results.W: 控制滤波器系数的历史记录
    %% 1. 解包参数
    time            = params.time;
    rirManager      = params.rirManager;
    network         = params.network;
    L               = params.L;
    x               = params.referenceSignal;
    d               = params.desiredSignal;

    % 从rirManager获取参数
    keyPriSpks = keys(rirManager.PrimarySpeakers);
    keySecSpks = keys(rirManager.SecondarySpeakers);
    keyErrMics = keys(rirManager.ErrorMicrophones);

    numPriSpks      = numEntries(rirManager.PrimarySpeakers);
    numSecSpks      = numEntries(rirManager.SecondarySpeakers);
    numErrMics      = numEntries(rirManager.ErrorMicrophones);
    
    nSamples = length(time);

    %% 2. 初始化
    max_Ls_hat = 0;
    for i = keySecSpks'
        Ls_hat = length(rirManager.getSecondaryRIR(i, keyErrMics(1)));
        if Ls_hat > max_Ls_hat
            max_Ls_hat = Ls_hat;
        end
    end

    x_taps = zeros(max([L, max_Ls_hat]), numPriSpks);

    e = zeros(nSamples, numErrMics); % 误差信号

    y_taps = cell(numSecSpks);   % 控制信号
    for k = 1:numSecSpks
        y_taps{k} = zeros(length(rirManager.getSecondaryRIR(keySecSpks(k), keyErrMics(1))), 1);
    end

    for keyNode = keys(network.Nodes)'
        node = network.Nodes(keyNode);
        node.init(L);
    end

    %% 3. 主循环
    disp('开始ADFxLMS-BC仿真...');
    for n = 1:nSamples
        % 3.1. 更新参考信号状态向量 (全局)
        x_taps = [x(n, :); x_taps(1:end-1, :)];

        % 3.2. 生成控制信号 y(n) (分布式)
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            y = node.Phi(:, node.NeighborIds == node.Id)' * x_taps(1:L, keyPriSpks == node.RefMicId);
            y_taps{keySecSpks == node.SecSpkId} = [y; y_taps{keySecSpks == node.SecSpkId}(1:end-1)];
        end

        % 3.3. 计算误差信号 e(n) (全局)
        for m = 1:numErrMics
            yf = 0;
            for k = 1:numSecSpks
                S = rirManager.getSecondaryRIR(keySecSpks(k), keyErrMics(m));
                Ls = length(S);
                yf = yf + S * y_taps{k}(1:Ls);
            end
            e(n, m) = d(n, m) + yf;
        end

        % 3.4. 更新节点信息 (分布式)
        % 3.4.1 滤波参考信号 x_filtered(n)
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            xf = zeros(1, numel(node.NeighborIds));
            for idx = 1:numel(node.NeighborIds)
                neighbor = network.Nodes(node.NeighborIds(idx));
                S_hat = rirManager.getSecondaryRIR(neighbor.SecSpkId, node.ErrMicId);
                Ls_hat = length(S_hat);
                xf(1, idx) = S_hat * x_taps(1:Ls_hat, keyPriSpks == node.RefMicId);
            end
            node.xf_taps = [xf; node.xf_taps(1:end-1, :)];
        end
        % 3.4.2 更新Psi      
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            node.Psi = node.Phi - node.StepSize * e(n, keyErrMics == node.ErrMicId) * node.xf_taps;
        end
        % 3.4.3 更新本地滤波器参数
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            node.Phi(:, node.NeighborIds == node.Id) = zeros(L, 1);
            for neighborId = node.NeighborIds
                neighbor = network.Nodes(neighborId);
                node.Phi(:, node.NeighborIds == node.Id) = node.Phi(:, node.NeighborIds == node.Id) + neighbor.Psi(:, neighbor.NeighborIds == node.Id) / numel(node.NeighborIds);
            end
        end       
        % 3.4.4 更新Phi
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            for neighborId = node.NeighborIds
                neighbor = network.Nodes(neighborId);
                node.Phi(:, node.NeighborIds == neighborId) = neighbor.Phi(:, neighbor.NeighborIds == neighborId);
            end
        end
    end

    %% 4. 打包结果
    results.description   = 'Augmented Diffusion FxLMS Algorithm';
    results.errorSignal   = e;
end
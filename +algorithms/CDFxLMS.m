function results = CDFxLMS(params)
    % CDFxLMS 分布式主动噪声控制FxLMS算法
    % 描述:
    %   类似集中式的分布式算法，每个节点使用局部误差信号和邻居节点的误差信号来更新其滤波器系数。
    %   本质是对全局成本函数进行求导
    %   与MGDFxLMS是一个思路
    %   名字是乱取的
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
    %       - results.err_hist: 麦克风处的误差信号历史
    %       - results.filter_coeffs: 各节点最终的控制器滤波器系数
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
    disp('开始CDFxLMS仿真...');
    for n = 1:nSamples
        % 3.1. 更新参考信号状态向量 (全局)
        x_taps = [x(n, :); x_taps(1:end-1, :)];

        % 3.2. 生成控制信号 y(n) (分布式)
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            y = node.W' * x_taps(1:L, keyPriSpks == node.RefMicId);
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
            S_hat = rirManager.getSecondaryRIR(node.SecSpkId, node.ErrMicId);
            Ls_hat = length(S_hat);
            xf = S_hat * x_taps(1:Ls_hat, keyPriSpks == node.RefMicId);
            node.xf_taps = [xf; node.xf_taps(1:end-1)];
            node.direction = e(n, keyErrMics == node.ErrMicId) * node.xf_taps;
        % 3.4.2 计算交叉路径补偿信号。如更新节点k时，需要补偿对节点m的影响：skm * x_taps * em 
            for neighborId = node.NeighborIds
                if neighborId ==node.Id
                    continue
                end

                neighbor = network.Nodes(neighborId);
                S_hat_km = rirManager.getSecondaryRIR(node.SecSpkId, neighbor.ErrMicId);
                Ls_hat_km = length(S_hat_km);
                xf_km = S_hat_km * x_taps(1:Ls_hat_km, keyPriSpks == node.RefMicId);

                % 如果没有创建，就初始化
                if ~isKey(node.xf_taps_km, neighborId)
                    node.xf_taps_km(neighborId) = {zeros(L, 1)};
                end
                
                buffer_cell = node.xf_taps_km(neighborId);
                buffer = buffer_cell{1};
                buffer = [xf_km; buffer(1:end-1)];     
                node.xf_taps_km(neighborId) = {buffer};

                node.direction = node.direction + e(n, keyErrMics == neighbor.ErrMicId) * buffer;
            end   
        end
        % 3.4.3 更新W
        for keyNode = keys(network.Nodes)'
            node = network.Nodes(keyNode);
            node.W = node.W - node.StepSize * node.direction;
        end
    end

    %% 4. 打包结果
    filter_coeffs = dictionary;
    for keyNode = keys(network.Nodes)'
        node = network.Nodes(keyNode);
        w = node.W;
        filter_coeffs(node.SecSpkId) = {w};
    end
    results.err_hist      = e;
    results.filter_coeffs = filter_coeffs;
end
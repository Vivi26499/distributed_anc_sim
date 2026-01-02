function results = MGDFxLMS(params)
% MGDFxLMS 分布式主动噪声控制FxLMS算法
% 描述:
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

fprintf('预计算交叉路径补偿滤波器 (ckm)...\n');
for keyNode = keys(network.Nodes)'
    node = network.Nodes(keyNode);
    for neighborId = node.NeighborIds
        if neighborId == node.Id
            continue
        end
        neighbor = network.Nodes(neighborId);

        % 2.1 计算ckm 可能能优化
        % 获取 RIR 并强制转换为列向量 (:)
        S_hat_km = rirManager.getSecondaryRIR(node.SecSpkId, neighbor.ErrMicId);
        S_hat_km = S_hat_km(:);

        S_hat_mm = rirManager.getSecondaryRIR(neighbor.SecSpkId, neighbor.ErrMicId);
        S_hat_mm = S_hat_mm(:);

        % 生成卷积矩阵
        M = convmtx(S_hat_mm, node.Lc);

        expected_len = size(M, 1);
        current_len = length(S_hat_km);

        % 构造目标向量 b (列向量)
        if current_len < expected_len
            % 补零
            b = [S_hat_km; zeros(expected_len - current_len, 1)];
        elseif current_len > expected_len
            % 截断 不应该发生
            b = S_hat_km(1:expected_len);
            fprintf("Warning: Truncating S_hat_km from length %d to %d for node %d -> neighbor %d\n", ...
                current_len, expected_len, node.Id, neighborId);
        else
            b = S_hat_km;
        end
        % 最小二乘求解
        ckm = M \ b;
        % fprintf('Node %d -> Neighbor %d: ckm norm = %.4f, max = %.4f\n', ...
        %        node.Id, neighborId, norm(ckm), max(abs(ckm)));
        node.ckm_taps(neighborId) = {ckm};

        % 2.2 验证ckm近似质量
        % 计算近似值
        S_km_approx = conv(S_hat_mm, ckm);
        S_km_approx = S_km_approx(1:length(S_hat_km));

        % 计算误差
        err = norm(S_km_approx - S_hat_km) / norm(S_hat_km);
        fprintf('Node %d -> Neighbor %d: 相对误差 = %.4f (%.1f%%)\n', ...
            node.Id, neighborId, err, err*100);
    end
end

%% 3. 主循环
fprintf('开始MGDFxLMS仿真... \n');
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
    % 3.4.1 计算xf、梯度
    for keyNode = keys(network.Nodes)'
        node = network.Nodes(keyNode);
        S_hat = rirManager.getSecondaryRIR(node.SecSpkId, node.ErrMicId);
        Ls_hat = length(S_hat);
        xf = S_hat * x_taps(1:Ls_hat, keyPriSpks == node.RefMicId);
        node.xf_taps = [xf; node.xf_taps(1:end-1)];
        node.gradient = e(n, keyErrMics == node.ErrMicId) * node.xf_taps;
        node.direction = e(n, keyErrMics == node.ErrMicId) * node.xf_taps;
    end
    % 3.4.2 收集所有邻居的梯度信息，并乘以ckm进行补偿
    for keyNode = keys(network.Nodes)'
        node = network.Nodes(keyNode);
        for neighborId = node.NeighborIds
            if neighborId == node.Id
                continue;
            end
            neighbor = network.Nodes(neighborId);

            ckm_cell = node.ckm_taps(neighbor.Id);
            ckm_vec = ckm_cell{1};

            ckm_flipped = flipud(ckm_vec);
            full_conv = conv(neighbor.gradient, ckm_flipped);
            % 截断（取“有效”部分）
            % 注意：由于翻转了，有效数据的起始点变了
            valid_start = node.Lc;
            % 提取正确的部分 (长度为 N)
            correction = full_conv(valid_start : valid_start + L - 1);
            
            node.direction = node.direction + correction;
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
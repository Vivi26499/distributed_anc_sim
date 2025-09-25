function results = CFxLMS(params)
    % CFxLMS 集中式前馈主动噪声控制FxLMS算法
    %
    % 输入:
    %   params: 包含所有仿真参数的结构体。
    %       - params.time: 离散时间轴
    %       - params.rirManager: RIRManager对象，用于获取脉冲响应
    %       - params.L: 控制滤波器的长度
    %       - params.mu: LMS算法的步长
    %       - params.referenceSignal: 参考信号
    %
    % 输出:
    %   results: 包含仿真结果的结构体。
    %       - results.errorSignal: 麦克风处的误差信号
    %       - results.controlSignal: 发送到扬声器的控制信号
    %       - results.W: 控制滤波器系数的历史记录
    import acoustics.RIRManager;
    %% 1. 解包参数
    time            = params.time;
    rirManager      = params.rirManager;
    L               = params.L;
    mu              = params.mu;
    x               = params.referenceSignal; % 参考信号

    % 从rirManager获取参数
    numPriSpks      = numEntries(rirManager.PrimarySpeakers);
    numSecSpks      = numEntries(rirManager.SecondarySpeakers);
    numErrMics      = numEntries(rirManager.ErrorMicrophones);
    % numPriSpks = rirManager.PrimarySpeakers.Count;
    % numSecSpks = rirManager.SecondarySpeakers.Count;
    % numErrMics = rirManager.ErrorMicrophones.Count;
    
    nSamples = length(time);

    %% 2. 初始化
    max_Ls_hat = 0;
    for i = 1:numSecSpks
        Ls_hat = length(rirManager.getSecondaryRIR(i, 1));
        if Ls_hat > max_Ls_hat
            max_Ls_hat = Ls_hat;
        end
    end
    W = zeros(L, numPriSpks, numSecSpks);

    x_taps = cell(numPriSpks);
    for j = 1:numPriSpks
        x_taps{j} = zeros(max([L, length(rirManager.getPrimaryRIR(j, 1)), max_Ls_hat]), 1);
    end

    xf_taps = zeros(L, numPriSpks, numSecSpks, numErrMics);

    e = zeros(nSamples, numErrMics); % 误差信号

    y_taps = cell(numSecSpks);   % 控制信号
    for k = 1:numSecSpks
        y_taps{k} = zeros(length(rirManager.getSecondaryRIR(k, 1)), 1);
    end

    d = zeros(nSamples, numErrMics); % 期望信号
    % 预先计算期望信号 d
    for m = 1:numErrMics
        for j = 1:numPriSpks
            P = rirManager.getPrimaryRIR(j, m);
            d_jm = conv(x(:, j), P);
            d(:, m) = d(:, m) + d_jm(1:nSamples);
        end
    end

    %% 3. 主循环
    disp('开始集中式FxLMS仿真...');
    for n = 1:nSamples
        % 3.1. 更新参考信号状态向量
        for j = 1:numPriSpks
            x_taps{j} = [x(n, j); x_taps{j}(1:end-1)];
        end

        % 3.2. 生成控制信号 y(n)
        for k = 1:numSecSpks
            y = 0;
            for j = 1:numPriSpks
                y = y + W(:, j, k)' * x_taps{j}(1:L);
            end
            y_taps{k} = [y; y_taps{k}(1:end-1)];
        end

        % 3.3. 计算误差信号 e(n)
        for m = 1:numErrMics
            yf = 0;
            for k = 1:numSecSpks
                S = rirManager.getSecondaryRIR(k, m);
                Ls = length(S);
                yf = yf + S * y_taps{k}(1:Ls);
            end
            e(n, m) = d(n, m) + yf;
        end

        % 3.4. 滤波参考信号 x_filtered(n)
        xf = zeros(1, numPriSpks, numSecSpks, numErrMics);
        for k = 1:numSecSpks
            for m = 1:numErrMics
                S = rirManager.getSecondaryRIR(k, m);
                Ls_hat = length(S);
                for j = 1:numPriSpks
                    xf(1, j, k, m) = S * x_taps{j}(1:Ls_hat);
                end
            end
        end
        xf_taps = [xf; xf_taps(1:end-1, :, :, :)];

        % 3.5. 更新滤波器系数 W(n+1)
        for k = 1:numSecSpks
            for m = 1:numErrMics
                W(:, :, k) = W(:, :, k) - mu * squeeze(xf_taps(:, :, k, m)) * e(n, m);
            end
        end
    end
    disp('仿真结束。');

    %% 4. 打包结果
    results.description   = 'Centralized FxLMS Algorithm';
    results.errorSignal   = e;
    results.desiredSignal = d;
    results.W             = W;

end
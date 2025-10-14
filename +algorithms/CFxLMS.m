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
    L               = params.L;
    mu              = params.mu;
    x               = params.referenceSignal; % 参考信号
    d               = params.desiredSignal;   % 期望信号

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
    W = zeros(L, numPriSpks, numSecSpks);

    x_taps = zeros(max([L, max_Ls_hat]), numPriSpks);

    xf_taps = zeros(L, numPriSpks, numSecSpks, numErrMics);

    e = zeros(nSamples, numErrMics); % 误差信号

    y_taps = cell(numSecSpks);   % 控制信号
    for k = 1:numSecSpks
        y_taps{k} = zeros(length(rirManager.getSecondaryRIR(keySecSpks(k), keyErrMics(1))), 1);
    end

    %% 3. 主循环
    disp('开始集中式FxLMS仿真...');
    for n = 1:nSamples
        % 3.1. 更新参考信号状态向量
        x_taps = [x(n, :); x_taps(1:end-1, :)];

        % 3.2. 生成控制信号 y(n)
        for k = 1:numSecSpks
            y = 0;
            for j = 1:numPriSpks
                y = y + W(:, j, k)' * x_taps(1:L, j);
            end
            y_taps{k} = [y; y_taps{k}(1:end-1)];
        end

        % 3.3. 计算误差信号 e(n)
        for m = 1:numErrMics
            yf = 0;
            for k = 1:numSecSpks
                S = rirManager.getSecondaryRIR(keySecSpks(k), keyErrMics(m));
                Ls = length(S);
                yf = yf + S * y_taps{k}(1:Ls);
            end
            e(n, m) = d(n, m) + yf;
        end

        % 3.4. 滤波参考信号 x_filtered(n)
        xf = zeros(1, numPriSpks, numSecSpks, numErrMics);
        for k = 1:numSecSpks
            for m = 1:numErrMics
                S = rirManager.getSecondaryRIR(keySecSpks(k), keyErrMics(m));
                Ls_hat = length(S);
                for j = 1:numPriSpks
                    xf(1, j, k, m) = S * x_taps(1:Ls_hat, j);
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

    %% 4. 打包结果
    results.description   = 'Centralized FxLMS Algorithm';
    results.errorSignal   = e;
end
function [signal, t] = wn_gen(fs, duration, f_low, f_high)
    %WN_GEN 生成带限白噪声信号
    %   Inputs:
    %       fs          - 采样频率 (Hz)
    %       duration    - 信号时长 (s)
    %       f_low       - 噪声下限频率 (Hz)
    %       f_high      - 噪声上限频率 (Hz)
    %
    %   Outputs:
    %       signal      - 生成的噪声信号 (时域)
    %       t           - 时间向量 (s)

    % 1. 计算信号长度，并确保为偶数
    N = round(fs * duration);
    if mod(N, 2) ~= 0
        N = N + 1;
    end

    % 2. 在频域生成信号
    X = zeros(1, N); % 初始化频域信号
    df = fs / N; % 频率分辨率

    % 3. 找到对应频率范围的索引
    % +1 是因为 MATLAB 索引从 1 开始
    idx_low = floor(f_low / df) + 1;
    idx_high = ceil(f_high / df) + 1;

    % 确保索引在有效范围内 [1, N/2+1]
    idx_low = max(idx_low, 1);
    idx_high = min(idx_high, N/2 + 1);

    % 4. 在指定频带内生成幅值为1，相位随机的信号
    if idx_low <= idx_high
        % 生成随机相位
        num_pts = idx_high - idx_low + 1;
        rand_phase = 2 * pi * rand(1, num_pts);
        
        % 构造正频率分量
        X(idx_low:idx_high) = exp(1j * rand_phase);
        
        % 构造共轭对称的负频率分量，以确保ifft结果为实数
        % N-k+2 是 k 对应的负频率索引
        neg_freq_indices = N - (idx_high:-1:idx_low) + 2;
        X(neg_freq_indices) = conj(X(idx_low:idx_high));
    end

    % 5. 反傅里叶变换到时域
    signal = real(ifft(X))';

    % 6. 生成时间向量
    t = (0:N-1)' / fs;

end

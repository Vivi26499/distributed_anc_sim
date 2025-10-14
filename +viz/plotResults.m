function plotResults(time, d_ch, error_signals, alg_names, mic_id, Fs)
% PLOTRESULTS 绘制单个通道的期望信号和多个算法的误差信号进行比较。
%
%   plotResults(time, d_ch, error_signals, alg_names, mic_id, Fs)
%
%   输入:
%       time          - 时间向量
%       d_ch          - 通道的期望信号
%       error_signals - 包含多个误差信号的 cell 数组, e.g., {e1, e2, ...}
%       alg_names     - 包含算法名称的 cell 数组, e.g., {'Alg 1', 'Alg 2', ...}
%       mic_id        - 麦克风ID，用于标题
%       Fs            - 采样率

    num_algs = numel(error_signals);
    if numel(alg_names) ~= num_algs
        error('The number of error signals and algorithm names must be the same.');
    end

    figure('Name', sprintf('Microphone %d Algorithm Comparison', mic_id));
    
    % 使用 'lines' colormap 获取一组鲜明的颜色
    colors = lines(num_algs);

    % --- 1. 时域信号 ---
    subplot(2, 1, 1);
    hold on;
    plot(time, d_ch, '-', 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1, ...
        'DisplayName', sprintf('期望信号 d_{%d}(n)', mic_id));
    
    for i = 1:num_algs
        plot(time, error_signals{i}, '-', 'Color', colors(i,:), 'LineWidth', 1.2, ...
            'DisplayName', sprintf('误差 (%s)', alg_names{i}));
    end
    
    grid on;
    title(sprintf('麦克风 %d: 时域信号对比', mic_id));
    xlabel('时间 (s)'); ylabel('幅值');
    legend('Location','best');
    hold off;

    % --- 2. 频域功率谱 (最后 1 秒) ---
    subplot(2, 1, 2);
    % 选取最后1秒的数据进行分析
    duration = time(end);
    if duration > 1
        startIndex = find(time >= duration - 1, 1);
    else
        startIndex = 1;
    end
    d_segment = d_ch(startIndex:end);
    
    % 使用 pwelch 计算功率谱密度
    [P_d, f] = pwelch(d_segment, [], [], [], Fs);

    hold on;
    plot(f, 10*log10(P_d), '-', 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1, ...
        'DisplayName', sprintf('PSD of d_{%d}', mic_id));

    for i = 1:num_algs
        e_segment = error_signals{i}(startIndex:end);
        [P_e, ~] = pwelch(e_segment, [], [], [], Fs);
        plot(f, 10*log10(P_e), '-', 'Color', colors(i,:), 'LineWidth', 1.2, ...
            'DisplayName', sprintf('PSD of error (%s)', alg_names{i}));
    end

    grid on;
    title(sprintf('麦克风 %d: 功率谱密度对比 (信号末段)', mic_id));
    xlabel('频率 (Hz)'); ylabel('功率/频率 (dB/Hz)');
    legend('Location','best');
    xlim([0 Fs/2]);
    hold off;

end

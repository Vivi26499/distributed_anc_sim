function plot_comparison(time, d_ch, e1_ch, e2_ch, mic_id, Fs, alg_names)
% PLOT_COMPARISON 绘制单个通道的期望信号和两个算法的误差信号进行比较。
%
%   plot_comparison(time, d_ch, e1_ch, e2_ch, mic_id, Fs, alg_names)
%
%   输入:
%       time      - 时间向量
%       d_ch      - 通道的期望信号
%       e1_ch     - 算法1的误差信号
%       e2_ch     - 算法2的误差信号
%       mic_id    - 麦克风ID，用于标题
%       Fs        - 采样率
%       alg_names - 包含两个算法名称的 cell 数组, e.g., {'CFxLMS', 'ADFxLMS'}

if nargin < 7
    alg_names = {'Alg 1', 'Alg 2'};
end

figure('Name', sprintf('Microphone %d Algorithm Comparison', mic_id));

% --- 1. 时域信号 ---
subplot(2, 1, 1);
hold on;
plot(time, d_ch, '-', 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1, ...
    'DisplayName', sprintf('期望信号 d_{%d}(n)', mic_id));
plot(time, e1_ch, '-',  'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.2, ...
    'DisplayName', sprintf('误差 (%s)', alg_names{1}));
plot(time, e2_ch, '-',  'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.2, ...
    'DisplayName', sprintf('误差 (%s)', alg_names{2}));
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
e1_segment = e1_ch(startIndex:end);
e2_segment = e2_ch(startIndex:end);

% 使用 pwelch 计算功率谱密度
[P_d, f] = pwelch(d_segment, [], [], [], Fs);
[P_e1, ~] = pwelch(e1_segment, [], [], [], Fs);
[P_e2, ~] = pwelch(e2_segment, [], [], [], Fs);

hold on;
plot(f, 10*log10(P_d), '-', 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1, ...
    'DisplayName', sprintf('PSD of d_{%d}', mic_id));
plot(f, 10*log10(P_e1), '-', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.2, ...
    'DisplayName', sprintf('PSD of error (%s)', alg_names{1}));
plot(f, 10*log10(P_e2), '-', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.2, ...
    'DisplayName', sprintf('PSD of error (%s)', alg_names{2}));
grid on;
title(sprintf('麦克风 %d: 功率谱密度对比 (信号末段)', mic_id));
xlabel('频率 (Hz)'); ylabel('功率/频率 (dB/Hz)');
legend('Location','best');
xlim([0 Fs/2]);
hold off;

end
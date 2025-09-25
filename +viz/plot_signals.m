function plot_signals(time, d_ch, e_ch, ch_num, Fs)
% PLOT_SIGNALS 绘制单个通道的期望信号和误差信号。
%
%   plot_signals(time, d_ch, e_ch, ch_num, Fs)
%
%   输入:
%       time    - 时间向量
%       d_ch    - 通道的期望信号
%       e_ch    - 通道的误差信号
%       ch_num  - 通道号，用于标题
%       Fs      - 采样率

figure('Name', sprintf('Channel %d Analysis', ch_num));

% --- 1. 时域信号 ---
subplot(2, 1, 1);
hold on;
plot(time, d_ch, '-', 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1.2, ...
    'DisplayName', sprintf('d_%d(n)', ch_num));
plot(time, e_ch, '-',  'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.2, ...
    'DisplayName', sprintf('e_%d(n)', ch_num));
grid on;
title(sprintf('通道 %d: 时域信号', ch_num));
xlabel('时间 (s)'); ylabel('幅值');
legend('Location','best');
hold off;

% % --- 2. 频域功率谱 (最后 1 秒) ---
% subplot(2, 1, 2);
% % 选取最后1秒的数据进行分析，如果总时长不足1秒则使用全部数据
% duration = time(end);
% if duration > 1
%     startIndex = find(time >= duration - 1, 1);
% else
%     startIndex = 1;
% end
% d_segment = d_ch(startIndex:end);
% e_segment = e_ch(startIndex:end);

% % 使用 pwelch 计算功率谱密度
% [P_d, f] = pwelch(d_segment, [], [], [], Fs);
% [P_e, ~] = pwelch(e_segment, [], [], [], Fs);

% hold on;
% plot(f, 10*log10(P_d), '-', 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1.2, ...
%     'DisplayName', sprintf('PSD of d_%d', ch_num));
% plot(f, 10*log10(P_e), '-', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.2, ...
%     'DisplayName', sprintf('PSD of e_%d', ch_num));
% grid on;
% title(sprintf('通道 %d: 功率谱密度 (信号末段)', ch_num));
% xlabel('频率 (Hz)'); ylabel('功率/频率 (dB/Hz)');
% legend('Location','best');
% xlim([0 Fs/2]);
% hold off;

end

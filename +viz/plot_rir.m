function plot_rir(rir, Fs, title_str)
% PLOT_RIR - 绘制脉冲响应及其频率响应。
%
% 语法:  plot_rir(rir, Fs, title_str)
%
% 输入:
%    rir - 脉冲响应向量。
%    Fs - 采样频率。
%    title_str - 绘图的标题。

figure;

% 绘制时域脉冲响应
subplot(2,1,1);
t = (0:length(rir)-1) / Fs;
plot(t, rir);
title(['Impulse Response: ' title_str]);
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

% 绘制频率响应
subplot(2,1,2);
L = length(rir);
f = Fs*(0:(L/2))/L;
H = fft(rir);
P2 = abs(H/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
plot(f, 20*log10(P1));
title('Frequency Response');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;

end

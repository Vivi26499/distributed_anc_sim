clear; clc;
mgr = acoustics.RIRManager();
mgr.Fs = 8000;
mgr.Room = [10 10 10];
mgr.Algorithm = "image-source";
mgr.ImageSourceOrder = 1;
mgr.MaterialAbsorption = .5;
mgr.MaterialScattering = 0.07;

% 主扬声器
mgr.addPrimarySpeaker(101, [9 5 5]);

% 次扬声器
mgr.addSecondarySpeaker(201, [7 5 5]);
mgr.addSecondarySpeaker(202, [3 5 5]);
mgr.addSecondarySpeaker(203, [5 7 5]);
mgr.addSecondarySpeaker(204, [5 3 5]);
mgr.addSecondarySpeaker(205, [5 5 7]);
mgr.addSecondarySpeaker(206, [5 5 3]);

% 误差麦克风
mgr.addErrorMicrophone(301, [6 5 5]);
mgr.addErrorMicrophone(302, [4 5 5]);
mgr.addErrorMicrophone(303, [5 6 5]);
mgr.addErrorMicrophone(304, [5 4 5]);
mgr.addErrorMicrophone(305, [5 5 6]);
mgr.addErrorMicrophone(306, [5 5 4]);

mgr.build(true);  % 批量生成 RIR

% --- 调用仿真 ---
duration = 3;                           % 秒

% 参考信号 (带限白噪声)
f_low = 100;    % Hz
f_high = 1000; % Hz
[noise, time] = utils.wn_gen(mgr.Fs, duration, f_low, f_high);
x = noise ./ max(abs(noise), [], 1); % 按列归一化

% 组装参数并调用 CFxLMS
params.time            = time;
params.rirManager      = mgr;
params.L               = 1024;           % 控制滤波器长度
params.referenceSignal = x;
params.mu = 0.0001;
tic;
results = algorithms.CFxLMS(params);
t = toc;
fprintf('CFxLMS simulation took %f seconds.\n', t);
% 绘制信号
d = results.desiredSignal;
e = results.errorSignal;
w = results.W;
if isvector(d), d = d(:); end
if isvector(e), e = e(:); end
numCh = min(size(d, 2), size(e, 2));
micIDs = keys(mgr.ErrorMicrophones);

for ch = 1:numCh
    viz.plot_signals(time, d(:, ch), e(:, ch), micIDs(ch), mgr.Fs);
end
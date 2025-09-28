clear; clc;
mgr = acoustics.old.RIRManager();
mgr.Fs = 24000;
mgr.Room = [10 10 10];
mgr.Algorithm = "image-source";
mgr.ImageSourceOrder = 0;
mgr.MaterialAbsorption = .5;
mgr.MaterialScattering = 0.07;

% 主扬声器
mgr.addPrimarySpeaker(101, [5 5 5]);

% 次扬声器
mgr.addSecondarySpeaker(111, [7 5 5]);
mgr.addSecondarySpeaker(112, [3 5 5]);

% 误差麦克风
mgr.addErrorMicrophone(201, [6 5 5]);
mgr.addErrorMicrophone(202, [4 5 5]);

mgr.build(true);  % 批量生成 RIR

% --- 调用 CFxLMS 仿真 ---
duration = 4;                           % 秒
nSamples = duration * mgr.Fs;
time = (0:nSamples-1)' / mgr.Fs;

% 参考信号
rng('default');
noise = randn(nSamples, 1);
x = noise ./ max(abs(noise));

% 组装参数并调用 CFxLMS
params.time            = time;
params.rirManager      = mgr;
params.L               = 1024;           % 控制滤波器长度
params.mu              = 0.002;          % 步长
params.referenceSignal = x;
tic;
results = algorithms.old.CFxLMS(params);
t = toc;
fprintf('Old CFxLMS took %f seconds.\n', t);
% 绘制信号
d = results.desiredSignal;
e = results.errorSignal;
w = results.W;
if isvector(d), d = d(:); end
if isvector(e), e = e(:); end
numCh = min(size(d, 2), size(e, 2));

for ch = 1:numCh
    viz.plot_signals(time, d(:, ch), e(:, ch), ch, mgr.Fs);
end
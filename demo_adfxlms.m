clear; clc;
mgr = acoustics.RIRManager();
mgr.Fs = 8000;
mgr.Room = [10 10 10];
mgr.Algorithm = "image-source";
mgr.ImageSourceOrder = 0;
mgr.MaterialAbsorption = .5;
mgr.MaterialScattering = 0.07;

% 主扬声器
mgr.addPrimarySpeaker(101, [9 5 5]);

% 次扬声器
mgr.addSecondarySpeaker(201, [7 5 5]);
mgr.addSecondarySpeaker(202, [3 5 5]);
mgr.addSecondarySpeaker(203, [5 7 5]);
mgr.addSecondarySpeaker(204, [5 3 5]);
% mgr.addSecondarySpeaker(205, [5 5 7]);
% mgr.addSecondarySpeaker(206, [5 5 3]);

% 误差麦克风
mgr.addErrorMicrophone(301, [6 5 5]);
mgr.addErrorMicrophone(302, [4 5 5]);
mgr.addErrorMicrophone(303, [5 6 5]);
mgr.addErrorMicrophone(304, [5 4 5]);
% mgr.addErrorMicrophone(305, [5 5 6]);
% mgr.addErrorMicrophone(306, [5 5 4]);

mgr.build(true);  % 批量生成 RIR

% 节点
mu = 1e-3;
node1 = algorithms.ADFxLMS.AugmentedNode(1, mu);
mgr.addNode(node1);
mgr.addRefMicToNode(1, 101);
mgr.addSecSpkToNode(1, 201);
mgr.addErrMicToNode(1, 301);

node2 = algorithms.ADFxLMS.AugmentedNode(2, mu);
mgr.addNode(node2);
mgr.addRefMicToNode(2, 101);
mgr.addSecSpkToNode(2, 202);
mgr.addErrMicToNode(2, 302);

node3 = algorithms.ADFxLMS.AugmentedNode(3, mu);
mgr.addNode(node3);
mgr.addRefMicToNode(3, 101);
mgr.addSecSpkToNode(3, 203);
mgr.addErrMicToNode(3, 303);

node4 = algorithms.ADFxLMS.AugmentedNode(4, mu);
mgr.addNode(node4);
mgr.addRefMicToNode(4, 101);
mgr.addSecSpkToNode(4, 204);
mgr.addErrMicToNode(4, 304);

% node5 = algorithms.ADFxLMS.AugmentedNode(5, mu);
% mgr.addNode(node5);
% mgr.addRefMicToNode(5, 101);
% mgr.addSecSpkToNode(5, 205);
% mgr.addErrMicToNode(5, 305);

% node6 = algorithms.ADFxLMS.AugmentedNode(6, mu);
% mgr.addNode(node6);
% mgr.addRefMicToNode(6, 101);
% mgr.addSecSpkToNode(6, 206);
% mgr.addErrMicToNode(6, 306);

% 邻居关系
mgr.connectNodes(1, 3);
mgr.connectNodes(1, 4);
mgr.connectNodes(2, 3);
mgr.connectNodes(2, 4);
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
tic;
results = algorithms.ADFxLMS.ADFxLMS(params);
t = toc;
fprintf('ADFxLMS simulation took %f seconds.\n', t);
% 绘制信号
d = results.desiredSignal;
e = results.errorSignal;

if isvector(d), d = d(:); end
if isvector(e), e = e(:); end
numCh = min(size(d, 2), size(e, 2));
micIDs = keys(mgr.ErrorMicrophones);

for ch = 1:numCh
    viz.plot_signals(time, d(:, ch), e(:, ch), micIDs(ch), mgr.Fs);
end
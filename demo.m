clear; clc;
%% 声学仿真环境
mgr = acoustics.RIRManager();
% 房间参数
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

% 误差麦克风
mgr.addErrorMicrophone(301, [6 5 5]);
mgr.addErrorMicrophone(302, [4 5 5]);
mgr.addErrorMicrophone(303, [5 6 5]);
mgr.addErrorMicrophone(304, [5 4 5]);

mgr.build(false);  % 批量生成 RIR

%% 通讯网络建立
% 节点
mu = 1e-3;
node1 = algorithms.ADFxLMS.Node(1, mu);
node1.addRefMic(101);
node1.addSecSpk(201);
node1.addErrMic(301);

node2 = algorithms.ADFxLMS.Node(2, mu);
node2.addRefMic(101);
node2.addSecSpk(202);
node2.addErrMic(302);

node3 = algorithms.ADFxLMS.Node(3, mu);
node3.addRefMic(101);
node3.addSecSpk(203);
node3.addErrMic(303);

node4 = algorithms.ADFxLMS.Node(4, mu);
node4.addRefMic(101);
node4.addSecSpk(204);
node4.addErrMic(304);

% 网络
net = topology.Network();
net.addNode(node1);
net.addNode(node2);
net.addNode(node3);
net.addNode(node4);
net.connectNodes(1, 3);
net.connectNodes(1, 4);
net.connectNodes(2, 3);
net.connectNodes(2, 4);

%% 源信号
duration = 3;                           % 秒

% 参考信号 (带限白噪声)
f_low = 100;    % Hz
f_high = 1000; % Hz
[noise, time] = utils.wn_gen(mgr.Fs, duration, f_low, f_high);
x = noise ./ max(abs(noise), [], 1); % 按列归一化

%% CFxLMS 算法仿真
params.time            = time;
params.rirManager      = mgr;
params.L               = 1024;           % 控制滤波器长度
params.referenceSignal = x;
params.mu = mu;

tic;
results_cf = algorithms.CFxLMS(params);
t = toc;
fprintf('CFxLMS simulation took %f seconds.\n', t);

%% ADFxLMS 算法仿真
params.time            = time;
params.rirManager      = mgr;
params.network         = net;
params.L               = 1024;           % 控制滤波器长度
params.referenceSignal = x;

tic;
results_adf = algorithms.ADFxLMS(params);
t = toc;
fprintf('ADFxLMS simulation took %f seconds.\n', t);

%% 结果比较与绘制
d = results_cf.desiredSignal;
e_cf = results_cf.errorSignal;
e_adf = results_adf.errorSignal;

numCh = size(d, 2);
micIDs = keys(mgr.ErrorMicrophones);
alg_names = {'CFxLMS', 'ADFxLMS'};

for ch = 1:numCh
    viz.plot_comparison(time, d(:, ch), e_cf(:, ch), e_adf(:, ch), micIDs(ch), mgr.Fs, alg_names);
end
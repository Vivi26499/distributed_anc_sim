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

%% 源信号
duration = 3;                           % 秒
f_low = 100;    % Hz
f_high = 1000; % Hz
[noise, time] = utils.wn_gen(mgr.Fs, duration, f_low, f_high);
x = noise ./ max(abs(noise), [], 1); % 按列归一化
d = mgr.calculateDesiredSignal(x, length(time)); % 期望信号

%% CFxLMS 算法仿真
% 仿真参数
params_cf.time            = time;
params_cf.rirManager      = mgr;
params_cf.L               = 1024;
params_cf.mu              = 1e-3;
params_cf.referenceSignal = x;
params_cf.desiredSignal   = d;

tic;
results_cf = algorithms.CFxLMS(params_cf);
t = toc;
fprintf('CFxLMS 仿真耗时 %f 秒。\n', t);

%% ADFxLMS 算法仿真
% 节点
mu_adf = 1e-3;
node1 = algorithms.ADFxLMS.Node(1, mu_adf);
node1.addRefMic(101);
node1.addSecSpk(201);
node1.addErrMic(301);

node2 = algorithms.ADFxLMS.Node(2, mu_adf);
node2.addRefMic(101);
node2.addSecSpk(202);
node2.addErrMic(302);

node3 = algorithms.ADFxLMS.Node(3, mu_adf);
node3.addRefMic(101);
node3.addSecSpk(203);
node3.addErrMic(303);

node4 = algorithms.ADFxLMS.Node(4, mu_adf);
node4.addRefMic(101);
node4.addSecSpk(204);
node4.addErrMic(304);

% 网络
net_adf = topology.Network();
net_adf.addNode(node1);
net_adf.addNode(node2);
net_adf.addNode(node3);
net_adf.addNode(node4);
net_adf.connectNodes(1, 3);
net_adf.connectNodes(1, 4);
net_adf.connectNodes(2, 3);
net_adf.connectNodes(2, 4);

% 仿真参数
params_adf.time            = time;
params_adf.rirManager      = mgr;
params_adf.network         = net_adf;
params_adf.L               = 1024;
params_adf.referenceSignal = x;
params_adf.desiredSignal   = d;

tic;
results_adf = algorithms.ADFxLMS(params_adf);
t = toc;
fprintf('ADFxLMS 仿真耗时 %f 秒。\n', t);

%% ADFxLMS-BC 算法仿真
% 节点
mu_adf_bc = 1e-3;
node1_bc = algorithms.ADFxLMS_BC.Node(1, mu_adf_bc);
node1_bc.addRefMic(101);
node1_bc.addSecSpk(201);
node1_bc.addErrMic(301);

node2_bc = algorithms.ADFxLMS_BC.Node(2, mu_adf_bc);
node2_bc.addRefMic(101);
node2_bc.addSecSpk(202);
node2_bc.addErrMic(302);

node3_bc = algorithms.ADFxLMS_BC.Node(3, mu_adf_bc);
node3_bc.addRefMic(101);
node3_bc.addSecSpk(203);
node3_bc.addErrMic(303);

node4_bc = algorithms.ADFxLMS_BC.Node(4, mu_adf_bc);
node4_bc.addRefMic(101);
node4_bc.addSecSpk(204);
node4_bc.addErrMic(304);

% 网络
net_bc = topology.Network();
net_bc.addNode(node1_bc);
net_bc.addNode(node2_bc);
net_bc.addNode(node3_bc);
net_bc.addNode(node4_bc);
net_bc.connectNodes(1, 3);
net_bc.connectNodes(1, 4);
net_bc.connectNodes(2, 3);
net_bc.connectNodes(2, 4);

% 仿真参数
params_adf_bc.time            = time;
params_adf_bc.rirManager      = mgr;
params_adf_bc.network         = net_bc;
params_adf_bc.L               = 1024;
params_adf_bc.referenceSignal = x;
params_adf_bc.desiredSignal   = d;

tic;
results_adf_bc = algorithms.ADFxLMS_BC(params_adf_bc);
t = toc;
fprintf('ADFxLMS-BC 仿真耗时 %f 秒。\n', t);


%% 结果比较与绘制
e_cf = results_cf.errorSignal;
e_adf = results_adf.errorSignal;
e_adf_bc = results_adf_bc.errorSignal;

numCh = size(d, 2);
micIDs = keys(mgr.ErrorMicrophones);
alg_names = {'CFxLMS', 'ADFxLMS', 'ADFxLMS-BC'};
error_signals = {e_cf, e_adf, e_adf_bc};

for ch = 1:numCh
    error_signals_ch = cellfun(@(x) x(:, ch), error_signals, 'UniformOutput', false);
    viz.plotResults(time, d(:, ch), error_signals_ch, alg_names, micIDs(ch), mgr.Fs);
end
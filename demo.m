clear; clc;
%% 声学仿真环境
mgr = acoustics.RIRManager();
% 房间参数
mgr.Fs = 8000;
mgr.Room = [5 5 5];
mgr.Algorithm = "image-source";
mgr.ImageSourceOrder = 2;
mgr.MaterialAbsorption = .5;
mgr.MaterialScattering = 0.07;

center = mgr.Room / 2;
% 主扬声器
mgr.addPrimarySpeaker(101, center + [1 0 0]);

% 次扬声器
r1 = 0.6;
mgr.addSecondarySpeaker(201, center + [r1 0 0]);
mgr.addSecondarySpeaker(202, center - [r1 0 0]);
mgr.addSecondarySpeaker(203, center + [0 r1 0]);
mgr.addSecondarySpeaker(204, center - [0 r1 0]);

% 误差麦克风
r2 = 0.3;
mgr.addErrorMicrophone(301, center + [r2 0 0]);
mgr.addErrorMicrophone(302, center - [r2 0 0]);
mgr.addErrorMicrophone(303, center + [0 r2 0]);
mgr.addErrorMicrophone(304, center - [0 r2 0]);

mgr.build(false);  % 批量生成 RIR

%% 源信号
duration = 10;                           % 秒
f_low = 100;    % Hz
f_high = 2000; % Hz
[noise, time] = utils.wn_gen(mgr.Fs, duration, f_low, f_high);
x = noise ./ max(abs(noise), [], 1); % 按列归一化
d = mgr.calculateDesiredSignal(x, length(time)); % 期望信号

%% CFxLMS 算法仿真
% 仿真参数
params_cf.time            = time;
params_cf.rirManager      = mgr;
params_cf.L               = 1024;
params_cf.mu              = 1e-4;
params_cf.referenceSignal = x;
params_cf.desiredSignal   = d;

tic;
results_cf = algorithms.CFxLMS(params_cf);
t = toc;
fprintf('CFxLMS 仿真耗时 %f 秒。\n', t);

%% ADFxLMS 算法仿真
% 节点
mu_adf = 1e-4;
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
mu_adf_bc = 1e-4;
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

%% Diff-FxLMS 算法仿真
% 节点
mu_diff = 1e-4;
node1_diff = algorithms.Diff_FxLMS.Node(1, mu_diff);
node1_diff.addRefMic(101);
node1_diff.addSecSpk(201);
node1_diff.addErrMic(301);

node2_diff = algorithms.Diff_FxLMS.Node(2, mu_diff);
node2_diff.addRefMic(101);
node2_diff.addSecSpk(202);
node2_diff.addErrMic(302);

node3_diff = algorithms.Diff_FxLMS.Node(3, mu_diff);
node3_diff.addRefMic(101);
node3_diff.addSecSpk(203);
node3_diff.addErrMic(303);

node4_diff = algorithms.Diff_FxLMS.Node(4, mu_diff);
node4_diff.addRefMic(101);
node4_diff.addSecSpk(204);
node4_diff.addErrMic(304);

% 网络
net_diff = topology.Network();
net_diff.addNode(node1_diff);
net_diff.addNode(node2_diff);
net_diff.addNode(node3_diff);
net_diff.addNode(node4_diff);
net_diff.connectNodes(1, 3);
net_diff.connectNodes(1, 4);
net_diff.connectNodes(2, 3);
net_diff.connectNodes(2, 4);

% 仿真参数
params_diff.time            = time;
params_diff.rirManager      = mgr;
params_diff.network         = net_diff;
params_diff.L               = 1024;
params_diff.referenceSignal = x;
params_diff.desiredSignal   = d;

tic;
results_diff = algorithms.Diff_FxLMS(params_diff);
t = toc;
fprintf('Diff-FxLMS 仿真耗时 %f 秒。\n', t);

%% DCFxLMS 算法仿真
% 节点
mu_dcf = 1e-4;
node1_dcf = algorithms.DCFxLMS.Node(1, mu_dcf);
node1_dcf.addRefMic(101);
node1_dcf.addSecSpk(201);
node1_dcf.addErrMic(301);

node2_dcf = algorithms.DCFxLMS.Node(2, mu_dcf);
node2_dcf.addRefMic(101);
node2_dcf.addSecSpk(202);
node2_dcf.addErrMic(302);

node3_dcf = algorithms.DCFxLMS.Node(3, mu_dcf);
node3_dcf.addRefMic(101);
node3_dcf.addSecSpk(203);
node3_dcf.addErrMic(303);

node4_dcf = algorithms.DCFxLMS.Node(4, mu_dcf);
node4_dcf.addRefMic(101);
node4_dcf.addSecSpk(204);
node4_dcf.addErrMic(304);

% 网络
net_dcf = topology.Network();
net_dcf.addNode(node1_dcf);
net_dcf.addNode(node2_dcf);
net_dcf.addNode(node3_dcf);
net_dcf.addNode(node4_dcf);

% 仿真参数
params_dcf.time            = time;
params_dcf.rirManager      = mgr;
params_dcf.network         = net_dcf;
params_dcf.L               = 1024;
params_dcf.referenceSignal = x;
params_dcf.desiredSignal   = d;

tic;
results_dcf = algorithms.DCFxLMS(params_dcf);
t = toc;
fprintf('DCFxLMS 仿真耗时 %f 秒。\n', t);

%% 结果比较与绘制
% 绘图参数
alg_names = {'CFxLMS', 'ADFxLMS', 'ADFxLMS-BC', 'Diff-FxLMS', 'DCFxLMS'};
sec_spk_ids = keys(mgr.SecondarySpeakers);

% 绘制滤波器系数
w_cf = results_cf.filter_coeffs;
w_adf = results_adf.filter_coeffs;
w_adf_bc = results_adf_bc.filter_coeffs;
w_diff = results_diff.filter_coeffs;
w_dcf = results_dcf.filter_coeffs;
w = {w_cf, w_adf, w_adf_bc, w_diff, w_dcf};
viz.plotTapWeights(w, alg_names, sec_spk_ids);

% 绘制误差信号
e_cf = results_cf.err_hist;
e_adf = results_adf.err_hist;
e_adf_bc = results_adf_bc.err_hist;
e_diff = results_diff.err_hist;
e_dcf = results_dcf.err_hist;
error_signals = {e_cf, e_adf, e_adf_bc, e_diff, e_dcf};

numCh = size(d, 2);
micIDs = keys(mgr.ErrorMicrophones);

for ch = 1:numCh
    error_signals_ch = cellfun(@(x) x(:, ch), error_signals, 'UniformOutput', false);
    viz.plotResults(time, d(:, ch), error_signals_ch, alg_names, micIDs(ch), mgr.Fs);
end
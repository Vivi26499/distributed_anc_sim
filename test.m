clear; clc;

%% 用户配置区域
% 可选选项: "CFxLMS", "ADFxLMS", "ADFxLMS-BC", "Diff-FxLMS", "DCFxLMS", "CDFxLMS", "MGDFxLMS"
% 例如：只想对比 CFxLMS 和 ADFxLMS，就写 ["CFxLMS", "ADFxLMS"]
selected_algorithms = ["MGDFxLMS"]; 

fprintf('当前选择运行的算法: %s\n', join(selected_algorithms, ', '));

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

fprintf('正在构建声学环境...\n');
mgr.build(false);  % 批量生成 RIR

%% 源信号
rng(42); % 固定随机种子以确保可重复性
duration = 10;                           % 秒
f_low = 100;    % Hz
f_high = 2000; % Hz
[noise, time] = utils.wn_gen(mgr.Fs, duration, f_low, f_high);
x = noise ./ max(abs(noise), [], 1); % 按列归一化
d = mgr.calculateDesiredSignal(x, length(time)); % 期望信号

%% 算法仿真

% 初始化结果容器，用于后续绘图
plot_results = {}; 
plot_names = {};

%% CFxLMS 算法仿真
if ismember("CFxLMS", selected_algorithms)
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
    
    % 保存结果用于绘图
    plot_results{end+1} = results_cf;
    plot_names{end+1} = 'CFxLMS';
end

%% ADFxLMS 算法仿真
if ismember("ADFxLMS", selected_algorithms)
    % 节点
    mu_adf = 1e-4;
    node1 = algorithms.ADFxLMS.Node(1, mu_adf);
    node1.addRefMic(101); node1.addSecSpk(201); node1.addErrMic(301);
    
    node2 = algorithms.ADFxLMS.Node(2, mu_adf);
    node2.addRefMic(101); node2.addSecSpk(202); node2.addErrMic(302);
    
    node3 = algorithms.ADFxLMS.Node(3, mu_adf);
    node3.addRefMic(101); node3.addSecSpk(203); node3.addErrMic(303);
    
    node4 = algorithms.ADFxLMS.Node(4, mu_adf);
    node4.addRefMic(101); node4.addSecSpk(204); node4.addErrMic(304);
    
    % 网络
    net_adf = topology.Network();
    net_adf.addNode(node1); net_adf.addNode(node2);
    net_adf.addNode(node3); net_adf.addNode(node4);
    net_adf.connectNodes(1, 2); net_adf.connectNodes(1, 4);
    net_adf.connectNodes(2, 3); net_adf.connectNodes(2, 4);
    net_adf.connectNodes(1, 2); net_adf.connectNodes(3, 4);
    
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
    
    plot_results{end+1} = results_adf;
    plot_names{end+1} = 'ADFxLMS';
end

%% ADFxLMS-BC 算法仿真
if ismember("ADFxLMS-BC", selected_algorithms)
    mu_adf_bc = 1e-4;
    node1_bc = algorithms.ADFxLMS_BC.Node(1, mu_adf_bc);
    node1_bc.addRefMic(101); node1_bc.addSecSpk(201); node1_bc.addErrMic(301);
    
    node2_bc = algorithms.ADFxLMS_BC.Node(2, mu_adf_bc);
    node2_bc.addRefMic(101); node2_bc.addSecSpk(202); node2_bc.addErrMic(302);
    
    node3_bc = algorithms.ADFxLMS_BC.Node(3, mu_adf_bc);
    node3_bc.addRefMic(101); node3_bc.addSecSpk(203); node3_bc.addErrMic(303);
    
    node4_bc = algorithms.ADFxLMS_BC.Node(4, mu_adf_bc);
    node4_bc.addRefMic(101); node4_bc.addSecSpk(204); node4_bc.addErrMic(304);
    
    net_bc = topology.Network();
    net_bc.addNode(node1_bc); net_bc.addNode(node2_bc);
    net_bc.addNode(node3_bc); net_bc.addNode(node4_bc);
    net_bc.connectNodes(1, 3); net_bc.connectNodes(1, 4);
    net_bc.connectNodes(2, 3); net_bc.connectNodes(2, 4);
    
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
    
    plot_results{end+1} = results_adf_bc;
    plot_names{end+1} = 'ADFxLMS-BC';
end

%% Diff-FxLMS 算法仿真
if ismember("Diff-FxLMS", selected_algorithms)
    mu_diff = 1e-4;
    node1_diff = algorithms.Diff_FxLMS.Node(1, mu_diff);
    node1_diff.addRefMic(101); node1_diff.addSecSpk(201); node1_diff.addErrMic(301);
    
    node2_diff = algorithms.Diff_FxLMS.Node(2, mu_diff);
    node2_diff.addRefMic(101); node2_diff.addSecSpk(202); node2_diff.addErrMic(302);
    
    node3_diff = algorithms.Diff_FxLMS.Node(3, mu_diff);
    node3_diff.addRefMic(101); node3_diff.addSecSpk(203); node3_diff.addErrMic(303);
    
    node4_diff = algorithms.Diff_FxLMS.Node(4, mu_diff);
    node4_diff.addRefMic(101); node4_diff.addSecSpk(204); node4_diff.addErrMic(304);
    
    net_diff = topology.Network();
    net_diff.addNode(node1_diff); net_diff.addNode(node2_diff);
    net_diff.addNode(node3_diff); net_diff.addNode(node4_diff);
    net_diff.connectNodes(1, 3); net_diff.connectNodes(1, 4);
    net_diff.connectNodes(2, 3); net_diff.connectNodes(2, 4);
    
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
    
    plot_results{end+1} = results_diff;
    plot_names{end+1} = 'Diff-FxLMS';
end

%% DCFxLMS 算法仿真
if ismember("DCFxLMS", selected_algorithms)
    mu_dcf = 1e-4;
    node1_dcf = algorithms.DCFxLMS.Node(1, mu_dcf);
    node1_dcf.addRefMic(101); node1_dcf.addSecSpk(201); node1_dcf.addErrMic(301);
    
    node2_dcf = algorithms.DCFxLMS.Node(2, mu_dcf);
    node2_dcf.addRefMic(101); node2_dcf.addSecSpk(202); node2_dcf.addErrMic(302);
    
    node3_dcf = algorithms.DCFxLMS.Node(3, mu_dcf);
    node3_dcf.addRefMic(101); node3_dcf.addSecSpk(203); node3_dcf.addErrMic(303);
    
    node4_dcf = algorithms.DCFxLMS.Node(4, mu_dcf);
    node4_dcf.addRefMic(101); node4_dcf.addSecSpk(204); node4_dcf.addErrMic(304);
    
    net_dcf = topology.Network();
    net_dcf.addNode(node1_dcf); net_dcf.addNode(node2_dcf);
    net_dcf.addNode(node3_dcf); net_dcf.addNode(node4_dcf);
    
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
    
    plot_results{end+1} = results_dcf;
    plot_names{end+1} = 'DCFxLMS';
end

%% CDFxLMS 算法仿真
if ismember("CDFxLMS", selected_algorithms)
    mu_cdf = 1e-4;
    node1_cdf = algorithms.CDFxLMS.Node(1, mu_cdf);
    node1_cdf.addRefMic(101); node1_cdf.addSecSpk(201); node1_cdf.addErrMic(301);
    
    node2_cdf = algorithms.CDFxLMS.Node(2, mu_cdf);
    node2_cdf.addRefMic(101); node2_cdf.addSecSpk(202); node2_cdf.addErrMic(302);
    
    node3_cdf = algorithms.CDFxLMS.Node(3, mu_cdf);
    node3_cdf.addRefMic(101); node3_cdf.addSecSpk(203); node3_cdf.addErrMic(303);
    
    node4_cdf = algorithms.CDFxLMS.Node(4, mu_cdf);
    node4_cdf.addRefMic(101); node4_cdf.addSecSpk(204); node4_cdf.addErrMic(304);
    
    net_cdf = topology.Network();
    net_cdf.addNode(node1_cdf); net_cdf.addNode(node2_cdf);
    net_cdf.addNode(node3_cdf); net_cdf.addNode(node4_cdf);

    net_cdf.connectNodes(1, 3); net_cdf.connectNodes(1, 4);
    net_cdf.connectNodes(2, 3); net_cdf.connectNodes(2, 4);
    net_cdf.connectNodes(1, 2); net_cdf.connectNodes(3, 4);
  
    params_cdf.time            = time;
    params_cdf.rirManager      = mgr;
    params_cdf.network         = net_cdf;
    params_cdf.L               = 1024;
    params_cdf.referenceSignal = x;
    params_cdf.desiredSignal   = d;
    
    tic;
    results_cdf = algorithms.CDFxLMS(params_cdf);
    t = toc;
    fprintf('CDFxLMS 仿真耗时 %f 秒。\n', t);
    
    plot_results{end+1} = results_cdf;
    plot_names{end+1} = 'CDFxLMS';
end

%% MGDFxLMS 算法仿真 还没成功
if ismember("MGDFxLMS", selected_algorithms)
    % 仿真参数
    mu_mgd = 1e-4;
    lc = 32; % 交叉路径补偿滤波器长度
    node1_mgd = algorithms.MGDFxLMS.Node(1, mu_mgd, lc);
    node1_mgd.addRefMic(101); node1_mgd.addSecSpk(201); node1_mgd.addErrMic(301);
    
    node2_mgd = algorithms.MGDFxLMS.Node(2, mu_mgd, lc);
    node2_mgd.addRefMic(101); node2_mgd.addSecSpk(202); node2_mgd.addErrMic(302);
    
    node3_mgd = algorithms.MGDFxLMS.Node(3, mu_mgd, lc);
    node3_mgd.addRefMic(101); node3_mgd.addSecSpk(203); node3_mgd.addErrMic(303);
    
    node4_mgd = algorithms.MGDFxLMS.Node(4, mu_mgd, lc);
    node4_mgd.addRefMic(101); node4_mgd.addSecSpk(204); node4_mgd.addErrMic(304);

    net_mgd = topology.Network();
    net_mgd.addNode(node1_mgd); net_mgd.addNode(node2_mgd);
    net_mgd.addNode(node3_mgd); net_mgd.addNode(node4_mgd);

    net_mgd.connectNodes(1, 3); net_mgd.connectNodes(1, 4);
    net_mgd.connectNodes(2, 3); net_mgd.connectNodes(2, 4);
    net_mgd.connectNodes(1, 2); net_mgd.connectNodes(3, 4);
    
    params_mgd.time            = time;
    params_mgd.rirManager      = mgr;
    params_mgd.network         = net_mgd; % 使用与 CDFxLMS 相同的网络拓扑
    params_mgd.L               = 1024;
    params_mgd.referenceSignal = x;
    params_mgd.desiredSignal   = d;
    
    tic;
    results_mgd = algorithms.MGDFxLMS(params_mgd);
    t = toc;
    fprintf('MGDFxLMS 仿真耗时 %f 秒。\n', t);
    
    % 保存结果用于绘图
    plot_results{end+1} = results_mgd;
    plot_names{end+1} = 'MGDFxLMS';
end

%% 检查是否有结果可绘制
if isempty(plot_results)
    warning('没有运行任何算法。请检查 selected_algorithms 设置。');
    return;
end

%% 结果比较与绘制
sec_spk_ids = keys(mgr.SecondarySpeakers);

% 绘制滤波器系数
% 提取所有运行结果的 filter_coeffs
w_all = cellfun(@(res) res.filter_coeffs, plot_results, 'UniformOutput', false);
viz.plotTapWeights(w_all, plot_names, sec_spk_ids);

% 绘制误差信号
% 提取所有运行结果的 err_hist
e_all = cellfun(@(res) res.err_hist, plot_results, 'UniformOutput', false);

numCh = size(d, 2);
micIDs = keys(mgr.ErrorMicrophones);

for ch = 1:numCh
    % 提取第 ch 个麦克风在所有算法中的误差数据
    error_signals_ch = cellfun(@(x) x(:, ch), e_all, 'UniformOutput', false);
    viz.plotResults(time, d(:, ch), error_signals_ch, plot_names, micIDs(ch), mgr.Fs);
end

% 绘制 NSE (dB) 对比图
fprintf('正在绘制 NSE 对比图...\n');
% 参数设置
window_size = round(0.1 * mgr.Fs); % 滑动平均窗口大小
mic_ids = keys(mgr.ErrorMicrophones);
num_mics = length(mic_ids);
colors = lines(length(plot_results)); 
line_styles = {'-', '-', '-', '-', '-'}; % 可根据算法数量自动循环

figure('Name', 'NSE Performance Comparison', 'Color', 'w', 'Position', [100, 100, 1200, 800]);

for m = 1:num_mics
    subplot(ceil(num_mics/2), 2, m);
    hold on; box on; grid on;
    
    % 分母：平滑后的期望信号功率
    d_power = movmean(d(:, m).^2, window_size) + eps;
    
    for k = 1:length(plot_results)
        % 分子：平滑后的误差信号功率
        e_curr = plot_results{k}.err_hist(:, m);
        e_power = movmean(e_curr.^2, window_size) + eps;
        
        % NSE (dB)
        nse_curve = 10 * log10(e_power ./ d_power);
        
        plot(time, nse_curve, ...
            'LineStyle', line_styles{mod(k-1, length(line_styles))+1}, ...
            'Color', colors(k, :), ...
            'LineWidth', 1.5, ...
            'DisplayName', plot_names{k});
    end
    
    % 格式美化
    subplot_idx_char = char(96 + m);
    title(sprintf('(%s) Node %d (Mic %d)', subplot_idx_char, m, mic_ids(m)), ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time (Second)', 'FontSize', 10);
    ylabel('NSE (dB)', 'FontSize', 10);
    xlim([0, duration]);
    ylim([-25, 5]); % 可根据需要调整
    
    if m == 1
        legend('Location', 'SouthWest', 'FontSize', 8);
    end

    lgd = legend('show', 'Location', 'SouthWest', 'FontSize', 8, 'Interpreter', 'none');
    lgd.ItemHitFcn = @toggleVisibility; % 绑定点击回调函数
end

fprintf('全部完成。\n');

%% 局部回调函数：点击图例切换可见性
function toggleVisibility(~, event)
    % event.Peer 是被点击图例项对应的线条对象
    if strcmp(event.Peer.Visible, 'on')
        event.Peer.Visible = 'off'; % 隐藏
    else
        event.Peer.Visible = 'on'; % 显示
    end
end
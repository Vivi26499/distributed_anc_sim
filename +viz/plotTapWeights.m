function plotTapWeights(filter_coeffs_cell, alg_names, sec_spk_ids)
    % plotTapWeights - 绘制并比较多种算法的控制器滤波器系数
    %
    % 输入:
    %   filter_coeffs_cell: 一个元胞数组，每个元素是一种算法的filter_coeffs字典。
    %   alg_names:          包含算法名称的元胞数组。
    %   sec_spk_ids:        一个包含所有次级扬声器ID的向量，用于保证连接顺序。

    if numel(filter_coeffs_cell) ~= numel(alg_names)
        error('滤波器系数集和算法名称的数量必须相同。');
    end

    figure('Name', 'Tap Weights Comparison');
    hold on;
    grid on;
    
    colors = lines(numel(alg_names));
    
    L = 0; % 用于存储单个滤波器的长度
    
    % 1. 绘制所有算法的滤波器系数
    for i = 1:numel(alg_names)
        alg_name = alg_names{i};
        coeffs_dict = filter_coeffs_cell{i};
        
        if ~isa(coeffs_dict, 'dictionary')
             warning('算法 ''%s'' 没有提供有效的滤波器系数字典。', alg_name);
             continue;
        end
        
        % 按照传入的 sec_spk_ids 顺序，连接所有滤波器系数
        all_coeffs = [];
        for spk_id = sec_spk_ids'
            if isKey(coeffs_dict, spk_id)
                coeff_cell = coeffs_dict(spk_id);
                w = coeff_cell{1};
                if L == 0, L = length(w); end % 获取滤波器长度
                all_coeffs = [all_coeffs; w];
            else
                warning('在算法 %s 中未找到扬声器ID %d 的系数。', alg_name, spk_id);
                % 如果缺少某个系数，用零填充以保持对齐
                if L > 0, all_coeffs = [all_coeffs; zeros(L, 1)]; end
            end
        end
        
        % 绘制连接后的总滤波器系数
        if ~isempty(all_coeffs)
            plot(all_coeffs, 'DisplayName', alg_name, 'Color', colors(i, :), 'LineWidth', 1.2);
        end
    end
    
    % 2. 自定义X轴
    if L > 0
        num_spks = numel(sec_spk_ids);
        
        % 1. 定义扬声器标签的位置和内容
        spk_tick_positions = (L/2) : L : (num_spks * L);
        spk_tick_labels = cell(1, num_spks);
        for k = 1:num_spks
            spk_tick_labels{k} = sprintf('Spk %d', sec_spk_ids(k));
        end
        
        % 2. 定义分隔线数值标签的位置和内容
        line_tick_positions = L * (1:num_spks);
        line_tick_labels = repmat({num2str(L)}, 1, num_spks);
        
        % 3. 合并并排序所有刻度和标签
        all_positions = [spk_tick_positions, line_tick_positions];
        all_labels = [spk_tick_labels, line_tick_labels];
        
        [sorted_positions, sort_idx] = sort(all_positions);
        sorted_labels = all_labels(sort_idx);
        
        % 4. 设置x轴刻度和标签
        ax = gca;
        ax.XTick = sorted_positions;
        ax.XTickLabel = sorted_labels;
        ax.XTickLabelRotation = 0; % 标签不旋转
        ax.TickLength = [0 0]; % 隐藏刻度线
        
        % 5. 添加垂直线分隔不同的滤波器
        for k = 1:num_spks-1
            line([k*L, k*L], ylim, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'HandleVisibility', 'off');
        end
        
        % 6. 设置X轴范围
        xlim([0, num_spks * L]);
    end
    
    hold off;
    
    title('Comparison of Concatenated Tap Weights');
    xlabel('Tap Index (Grouped by Speaker)');
    ylabel('Tap Weight');
    legend('show', 'Location', 'best');
    
end

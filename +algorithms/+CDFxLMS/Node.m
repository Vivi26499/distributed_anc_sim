classdef Node < topology.Node
    properties
        StepSize     (1,1) double {mustBePositive} = 0.01;
        W (:, 1) double = [];

        xf_taps double = [];
        xf_taps_km dictionary;  % 存储滤波参考信号的交叉路径分量
        direction double = [];  % 存储方向信息
    end

    methods
        function obj = Node(id, step)
            obj@topology.Node(id);
            if nargin >= 2
                obj.StepSize = step;
            end
        end

        % 初始化 W 和 filtered_x，全零向量
        function init(obj, filterlength)
            obj.W = zeros(filterlength, 1);
            obj.xf_taps = obj.W;
            obj.xf_taps_km = configureDictionary('uint32', 'cell');
            obj.direction = obj.W;
        end

    end
end



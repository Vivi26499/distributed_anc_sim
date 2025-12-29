classdef Node < topology.Node
    properties
        StepSize     (1,1) double {mustBePositive} = 0.01;
        W (:, 1) double = [];

        xf_taps double = [];
        gradient double = []; % 梯度
        direction double = []; % 更新方向

        Lc = 32; % 交叉路径补偿滤波器长度
        ckm_taps dictionary; % 存储交叉路径补偿滤波器系数，对节点k：skm = smm * ckm
        
    end

    methods
        function obj = Node(id, step, lc)
            obj@topology.Node(id);
            if nargin >= 2
                obj.StepSize = step;
            end
            if nargin >= 3
                obj.Lc = lc;
            end
        end

        % 生成 W 和 Psi，全零向量
        function init(obj, filterlength)
            obj.W = zeros(filterlength, 1);
            obj.xf_taps = obj.W;
            obj.gradient = obj.W;
            obj.direction = obj.W;
            obj.ckm_taps = configureDictionary("uint32", "cell");
        end
    end
end
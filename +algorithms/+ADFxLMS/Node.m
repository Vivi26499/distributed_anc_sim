classdef Node < topology.Node
    properties
        StepSize     (1,1) double {mustBePositive} = 0.01;
        Phi double = [];
        Psi double = [];

        xf_taps double = [];
    end

    methods
        function obj = Node(id, step)
            obj@topology.Node(id);
            if nargin >= 2
                obj.StepSize = step;
            end
        end

        % 生成 Psi 和 Phi，全零矩阵
        function init(obj, filterlength)
            numNeighbors = numel(obj.NeighborIds);
            if nargin < 2
                filterlength = 64; % 默认滤波器长度
            end
            obj.xf_taps = zeros(filterlength, numNeighbors);
            obj.Phi = zeros(filterlength, numNeighbors);
            obj.Psi = obj.Phi;
        end
    end
end
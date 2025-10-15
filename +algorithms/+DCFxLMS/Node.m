classdef Node < topology.Node
    properties
        StepSize     (1,1) double {mustBePositive} = 0.01;
        W (:, 1) double = [];

        xf_taps double = [];
    end

    methods
        function obj = Node(id, step)
            obj@topology.Node(id);
            if nargin >= 2
                obj.StepSize = step;
            end
        end

        % 生成 W 和 Psi，全零向量
        function init(obj, filterlength)
            obj.W = zeros(filterlength, 1);
            obj.xf_taps = obj.W;
        end
    end
end
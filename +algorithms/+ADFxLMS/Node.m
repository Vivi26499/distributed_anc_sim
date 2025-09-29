classdef Node < topology.Node
    properties
        StepSize     (1,1) double {mustBePositive} = 0.01;
        Phi double = [];
        Psi double = [];
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
            numNeighbors = init@topology.Node(obj, filterlength);
            obj.Phi = zeros(filterlength, numNeighbors);
            obj.Psi = obj.Phi;
        end
    end
end
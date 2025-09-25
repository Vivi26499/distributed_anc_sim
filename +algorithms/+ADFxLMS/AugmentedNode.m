classdef AugmentedNode < algorithms.Node
    properties
        StepSize     (1,1) double {mustBePositive} = 0.01;
        Psi double = [];
        Phi double = [];
    end

    methods
        function obj = AugmentedNode(id, step)
            obj@algorithms.Node(id);
            if nargin >= 2
                obj.StepSize = step;
            end
        end

        % 生成 Psi 和 Phi，全零矩阵
        function init(obj, filterlength)
            numRefMics = numel(obj.RefMicId);
            numSecSpks = numel(obj.SecSpkId);
            numNeighbors = numel(obj.NeighborIds);
            if nargin < 2
                filterlength = 64; % 默认滤波器长度
            end
            obj.Psi = zeros(filterlength, numRefMics, numSecSpks, numNeighbors);
            obj.Phi = obj.Psi;
        end
    end

    methods (Static)
        function selftest()
            fprintf('[AugmentedNode.selftest] start\n');

            % 构造：id=1, FilterLength=64, StepSize=0.02
            n = algorithms.ADFxLMS.AugmentedNode(1, 0.02);

            % 添加设备（只是覆盖下流程，大小校验与它们无关）
            n.addRefMic([101 102 103]);
            n.addSecSpk([201 202]);
            n.addErrMic([301 302 303 304]);

            % 添加邻居
            n.addNeighbor([2 3 4 5]);

            % 生成矩阵
            n.init(1024);

            % 期望尺寸
            expectedSize = [1024, 3, 2, 5];
            assert(isequal(size(n.Psi), expectedSize), 'Psi尺寸不匹配');
            assert(isequal(size(n.Phi), expectedSize), 'Phi尺寸不匹配');
            fprintf('[AugmentedNode.selftest] passed\n');
        end
    end

end
classdef Node < handle
    properties
        Id (1,1) uint32
        RefMicId (1,1) uint32   % 参考麦克风 ID
        SecSpkId (1,1) uint32   % 次级扬声器 ID
        ErrMicId (1,1) uint32   % 误差麦克风 ID
        NeighborIds (1,:) uint32     % 存储邻居节点 ID

        xf_taps
    end

    methods
        function obj = Node(id)
            if nargin > 0
                obj.Id = id;
                obj.NeighborIds = uint32(id); 
            end
        end

        function numNeighbors = init(obj, filterlength)
            numNeighbors = numel(obj.NeighborIds);
            if nargin < 2
                filterlength = 64; % 默认滤波器长度
            end
            obj.xf_taps = zeros(filterlength, numNeighbors);
        end
    end
end
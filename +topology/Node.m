classdef Node < handle
    properties
        Id (1,1) uint32
        RefMicId (1,1) uint32   % 参考麦克风 ID
        SecSpkId (1,1) uint32   % 次级扬声器 ID
        ErrMicId (1,1) uint32   % 误差麦克风 ID
        NeighborIds (1,:) uint32     % 存储邻居节点 ID

    end

    methods
        function obj = Node(id)
            if nargin > 0
                obj.Id = id;
                obj.NeighborIds = uint32(id); 
            end
        end

        function addRefMic(obj, micId)
            obj.RefMicId = micId;
        end

        function addSecSpk(obj, spkId)
            obj.SecSpkId = spkId;
        end

        function addErrMic(obj, micId)
            obj.ErrMicId = micId;
        end
    end
end
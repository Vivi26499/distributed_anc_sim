classdef Node < handle
    properties
        Id (1,1) uint32
        RefMicId (1,:) uint32   % 参考麦克风 ID
        SecSpkId (1,:) uint32   % 次级扬声器 ID
        ErrMicId (1,:) uint32   % 误差麦克风 ID
        NeighborIds (1,:) uint32     % 存储邻居节点 ID

        x_taps cell
        xf_taps
    end

    methods
        function obj = Node(id)
            if nargin > 0
                obj.Id = id;
                obj.RefMicId = [];
                obj.SecSpkId = [];
                obj.ErrMicId = [];
                obj.NeighborIds = uint32(id); 
            end
        end

        function addRefMic(obj, ids)
            mustBeNumeric(ids);
            obj.RefMicId = union(obj.RefMicId, uint32(ids(:)'));
        end

        function addSecSpk(obj, ids)
            mustBeNumeric(ids);
            obj.SecSpkId = union(obj.SecSpkId, uint32(ids(:)'));
        end

        function addErrMic(obj, ids)
            mustBeNumeric(ids);
            obj.ErrMicId = union(obj.ErrMicId, uint32(ids(:)'));
        end

        function addNeighbor(obj, neighborIds)
            mustBeNumeric(neighborIds);
            obj.NeighborIds = union(obj.NeighborIds, uint32(neighborIds(:)'));
        end
    end
end
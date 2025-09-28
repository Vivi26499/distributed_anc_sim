classdef RIRManager < handle
    properties
        Room (1,3) double = [7 5 3]
        Fs (1,1) double = 48000
        SoundSpeed (1,1) double = 343

        Algorithm (1,1) string = "image-source"

        ImageSourceOrder (1,1) double = 3

        NumStochasticRays (1,1) double = 1280
        MaxNumRayReflections (1,1) double = 10
        ReceiverRadius (1,1) double = 0.5

        BandCenterFrequencies = [125 250 500 1000 2000 4000]
        AirAbsorption = 0
        MaterialAbsorption = ...
        [0.10 0.20 0.40 0.60 0.50 0.60; ... %地面
         0.10 0.20 0.40 0.60 0.50 0.60; ... %前墙
         0.10 0.20 0.40 0.60 0.50 0.60; ... %后墙
         0.10 0.20 0.40 0.60 0.50 0.60; ... %左墙
         0.02 0.03 0.03 0.03 0.04 0.07; ... %右墙
         0.02 0.03 0.03 0.03 0.04 0.07].';  %天花
        MaterialScattering = []
        
        PrimarySpeakers   dictionary
        SecondarySpeakers dictionary
        ErrorMicrophones  dictionary

        Nodes             dictionary
    end

    properties (Access = private)
        PrimaryRIRs   dictionary
        SecondaryRIRs dictionary
    end

    methods
        function obj = RIRManager()
            % 初始化 dictionary
            obj.PrimarySpeakers   = configureDictionary("uint32", "cell");
            obj.SecondarySpeakers = configureDictionary("uint32", "cell");
            obj.ErrorMicrophones  = configureDictionary("uint32", "cell");

            obj.PrimaryRIRs       = configureDictionary("string", "cell");
            obj.SecondaryRIRs     = configureDictionary("string", "cell");
        end

        function addPrimarySpeaker(obj, id, position)
            arguments
                obj
                id (1,1) uint32
                position (1,3) double
            end
            obj.PrimarySpeakers(id) = {position};
        end

        function addSecondarySpeaker(obj, id, position)
            arguments
                obj
                id (1,1) uint32
                position (1,3) double
            end
            obj.SecondarySpeakers(id) = {position};
        end

        function addErrorMicrophone(obj, id, position)
            arguments
                obj
                id (1,1) uint32
                position (1,3) double
            end
            obj.ErrorMicrophones(id) = {position};
        end

        function addNode(obj, node)
            obj.Nodes(node.Id) = node;
        end

        function addRefMicToNode(obj, nodeId, micId)
            node = obj.Nodes(nodeId);
            if ~isKey(obj.PrimarySpeakers, micId)
                error('Reference microphone with ID %d does not exist.', id);
            end
            node.RefMicId = micId;
        end

        function addSecSpkToNode(obj, nodeId, spkId)
            node = obj.Nodes(nodeId);
            if ~isKey(obj.SecondarySpeakers, spkId)
                error('Secondary speaker with ID %d does not exist.', id);
            end
            node.SecSpkId = spkId;
        end

        function addErrMicToNode(obj, nodeId, micId)
            node = obj.Nodes(nodeId);
            if ~isKey(obj.ErrorMicrophones, micId)
                error('Error microphone with ID %d does not exist.', id);
            end
            node.ErrMicId = micId;
        end

        function connectNodes(obj, node1Id, node2Id)
            node1 = obj.Nodes(node1Id);
            node2 = obj.Nodes(node2Id);
            node1.NeighborIds = union(node1.NeighborIds, node2Id);
            node2.NeighborIds = union(node2.NeighborIds, node1Id);
        end
        
        function build(obj, verbose)
            if nargin < 2, verbose = true; end
            
            if numEntries(obj.ErrorMicrophones) == 0
                error('No error microphones have been added.');
            end

            micIds = keys(obj.ErrorMicrophones);
            micPositions = cell2mat(values(obj.ErrorMicrophones));
            % --- 1. 主通路 ---
            if numEntries(obj.PrimarySpeakers) > 0
                for spkId = keys(obj.PrimarySpeakers)'
                    spkPos = obj.PrimarySpeakers(spkId);
                    ir = obj.computeRIR(spkPos, micPositions);
                    
                    for j = 1:numel(micIds)
                        micId = micIds(j);
                        key = "P" + string(spkId) + "->M" + string(micId);
                        obj.PrimaryRIRs(key) = {ir(j, :)};
                    end
                    if verbose 
                        disp("Primary paths for Speaker " + spkId + " computed. RIR length: " + size(ir,2)); 
                    end
                end
            else
                error('No primary speakers have been added.');
            end
            % --- 2. 次级通路 ---
            if numEntries(obj.SecondarySpeakers) > 0
                for spkId = keys(obj.SecondarySpeakers)'
                    spkPos = obj.SecondarySpeakers(spkId);
                    ir = obj.computeRIR(spkPos, micPositions);
                    
                    for j = 1:numel(micIds)
                        micId = micIds(j);
                        key = "S" + string(spkId) + "->M" + string(micId);
                        obj.SecondaryRIRs(key) = {ir(j, :)};
                    end
                    if verbose 
                        disp("Secondary paths for Speaker " + spkId + " computed. RIR length: " + size(ir,2)); 
                    end
                end
            else
                error('No secondary speakers have been added.');
            end
        end

        function h = getPrimaryRIR(obj, spkId, micId)
            key = "P" + string(spkId) + "->M" + string(micId);
            if ~isKey(obj.PrimaryRIRs, key)
                error('Primary RIR for path (%s) does not exist.', key);
            end
            h = cell2mat(obj.PrimaryRIRs(key));
        end

        function h = getSecondaryRIR(obj, spkId, micId)
            key = "S" + string(spkId) + "->M" + string(micId);
            if ~isKey(obj.SecondaryRIRs, key)
                error('Secondary RIR for path (%s) does not exist.', key);
            end
            h = cell2mat(obj.SecondaryRIRs(key));
        end
    end

    methods (Access = private)
        function ir = computeRIR(obj, txPos, rxPos)
            ir = acousticRoomResponse( ...
                obj.Room, txPos{1}, rxPos, ...
                SampleRate=obj.Fs, SoundSpeed=obj.SoundSpeed, ...
                Algorithm=obj.Algorithm, ...
                ImageSourceOrder=obj.ImageSourceOrder, ...
                NumStochasticRays=obj.NumStochasticRays, ...
                MaxNumRayReflections=obj.MaxNumRayReflections, ...
                ReceiverRadius=obj.ReceiverRadius, ...
                AirAbsorption=obj.AirAbsorption, ...
                MaterialAbsorption=obj.MaterialAbsorption, ...
                MaterialScattering=obj.MaterialScattering, ...
                BandCenterFrequencies=obj.BandCenterFrequencies);
        end
    end
end

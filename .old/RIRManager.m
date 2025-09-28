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
        
        PrimarySpeakers
        SecondarySpeakers
        ErrorMicrophones

        Nodes
    end

    properties 
        PrimaryRIRs
        SecondaryRIRs
    end

    methods
        function obj = RIRManager()
            % 构造函数：初始化Map对象
            obj.PrimarySpeakers = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            obj.SecondarySpeakers = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            obj.ErrorMicrophones = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            obj.PrimaryRIRs = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.SecondaryRIRs = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.Nodes = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
        end

        function addPrimarySpeaker(obj, id, position)
            obj.PrimarySpeakers(id) = position;
        end

        function addSecondarySpeaker(obj, id, position)
            obj.SecondarySpeakers(id) = position;
        end

        function addErrorMicrophone(obj, id, position)
            obj.ErrorMicrophones(id) = position;
        end

        function addNode(obj, node)
            obj.Nodes(node.Id) = node;
        end
        
        function build(obj, verbose)
            if nargin < 2, verbose = true; end

            if obj.ErrorMicrophones.Count == 0
                error('No error microphones have been added.');
            end

            micIds = obj.ErrorMicrophones.keys;
            micPositions = cell2mat(values(obj.ErrorMicrophones, micIds'));

            % --- 1. 计算主通路 (所有主扬声器 -> 所有误差麦克风) ---
            if obj.PrimarySpeakers.Count > 0
                priSpkIds = obj.PrimarySpeakers.keys;
                for i = 1:length(priSpkIds)
                    spkId = priSpkIds{i};
                    spkPos = obj.PrimarySpeakers(spkId);
                    
                    ir = obj.computeRIR(spkPos, micPositions);
                    
                    for j = 1:length(micIds)
                        micId = micIds{j};
                        key = sprintf('P%d->M%d', spkId, micId);
                        obj.PrimaryRIRs(key) = ir(j, :);
                    end
                    if verbose, fprintf('Primary paths for Speaker P%d computed. RIR length: %d\n', spkId, size(ir, 2)); end
                end
            else
                error('No primary speakers have been added.');
            end

            % --- 2. 计算次级通路 (所有次级扬声器 -> 所有误差麦克风) ---
            if obj.SecondarySpeakers.Count > 0
                secSpkIds = obj.SecondarySpeakers.keys;
                for i = 1:length(secSpkIds)
                    spkId = secSpkIds{i};
                    spkPos = obj.SecondarySpeakers(spkId);
                    
                    ir = obj.computeRIR(spkPos, micPositions);
                    
                    for j = 1:length(micIds)
                        micId = micIds{j};
                        key = sprintf('S%d->M%d', spkId, micId);
                        obj.SecondaryRIRs(key) = ir(j, :);
                    end
                    if verbose, fprintf('Secondary paths for Speaker S%d computed. RIR length: %d\n', spkId, size(ir, 2)); end
                end
            else
                error('No secondary speakers have been added.');
            end
        end

        function h = getPrimaryRIR(obj, spkId, micId)
            % 获取主通路 RIR (主扬声器 -> 误差麦克风)
            key = sprintf('P%d->M%d', spkId, micId);
            if ~isKey(obj.PrimaryRIRs, key)
                error('Primary RIR for path (%s) does not exist.', key);
            end
            h = obj.PrimaryRIRs(key);
        end

        function h = getSecondaryRIR(obj, spkId, micId)
            % 获取次级通路 RIR (次级扬声器 -> 误差麦克风)
            key = sprintf('S%d->M%d', spkId, micId);
            if ~isKey(obj.SecondaryRIRs, key)
                error('Secondary RIR for path (%s) does not exist.', key);
            end
            h = obj.SecondaryRIRs(key);
        end
    end

    methods (Access = private)
        function ir = computeRIR(obj, txPos, rxPos)
            % 封装RIR计算逻辑
            ir = acousticRoomResponse( ...
                obj.Room, txPos, rxPos, ...
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

classdef Network < handle
    properties
        Nodes             dictionary
    end

    methods
        function addNode(obj, node)
            obj.Nodes(node.Id) = node;
        end

        function connectNodes(obj, node1Id, node2Id)
            node1 = obj.Nodes(node1Id);
            node2 = obj.Nodes(node2Id);
            node1.NeighborIds = union(node1.NeighborIds, node2Id);
            node2.NeighborIds = union(node2.NeighborIds, node1Id);
        end
    end
end

CREATE VIEW WorkOrder.View_Operations 
    AS 
    SELECT seg.SegmentName as OperationName,
    	seg.SegmentDescription as OperationDescription,
    	op.*
    FROM WorkOrder.View_OperationWithoutOperationName op WITH (NOEXPAND)
    JOIN WorkOrder.SegmentDetails seg
    ON seg.SegmentsDefinitionId = op.SegmentsDefinitionId
    	AND seg.SegmentId = op.SegmentId
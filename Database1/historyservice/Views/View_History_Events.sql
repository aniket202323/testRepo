CREATE VIEW historyservice.View_History_Events 
	WITH SCHEMABINDING
	AS
	SELECT he.id as id, 
		   he.EntryType as entryType, 
		   he.WorkOrderId as workOrderId, 
		   wo.Name as workOrderName, 
		   pm.Name as producedMaterialCode,
		   pm.Description as producedMaterialDescription,
		   pl.LineId as productionLineId,
		   pl.Name as productionLineName,
		   mla.MaterialLotActualsId as materialLotActualId,
		   mla.LotIdentifier as lotIdentifier,
		   sa.SegmentActualId as segmentActualId, 
		   sa.SegmentId as segmentId,
		   sa.Name as segmentName,
		   he.PerformedBy as performedBy, 
		   he.EventDate as timestamp,
		   se.Id as sourceEventId
	FROM historyservice.HistoryEntries he
	JOIN historyservice.SourceEvents se
	ON se.Id = he.SourceEventId
	JOIN historyservice.WorkOrders wo
	ON wo.WorkOrderId = he.WorkOrderId
	LEFT JOIN historyservice.ProductionLines pl
	ON pl.LineId = wo.ProductionLineId
	LEFT JOIN historyservice.ProducedMaterials pm
	ON pm.MaterialId = wo.ProducedMaterialId
	LEFT JOIN historyservice.MaterialLotActuals mla
	ON mla.MaterialLotActualsId = he.MaterialLotActualId
	LEFT JOIN historyservice.SegmentActuals sa
	ON sa.SegmentActualId = he.SegmentActualId
	WHERE he.EntryType NOT IN ('mes.workorder.workorders.SegmentActualsCreatedEvent', 'mes.workorder.workorders.HoldRecordsCreatedEvent', 'mes.workorder.workorders.HoldRecordsReleasedEvent' )
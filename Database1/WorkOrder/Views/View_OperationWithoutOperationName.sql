CREATE VIEW WorkOrder.View_OperationWithoutOperationName
    WITH SCHEMABINDING
    AS 
    SELECT sa.Id as SegmentActualId,
    	sa.SegmentId,
    	sa.MaterialLotActualId,
    	mla.LotIdentifier as LotIdentifier,
    	mla.WorkOrderId,
    	wo.Name as WorkOrderName,
    	wo.Prod_Id as ProducedMaterialId,
    	wo.PL_Id as ProductionLineId,
    	wo.Priority as WorkOrderPriority,
    	CASE
    		WHEN wo.Priority > 0
    		THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) 
    	END AS WorkOrderPriorityInitialized,
    	wo.SegmentsDefinitionId as SegmentsDefinitionId,
    	sa.Status,
    	sa.PU_Id as StartedOnUnitId,
    	CAST(CASE 
    		WHEN sa.Status IN (40, 60) THEN 0
    		WHEN sa.NumberOfActiveOperationHolds + mla.NumberOfActiveLotHolds > 0 THEN 1
    		ELSE 0
    	END AS BIT) as OnHold,
    	sa.ReadyOn,
    	sa.StartedOn,
    	sa.StartedBy,
    	sa.CompletedOn,
    	sa.CompletedBy,
    	mla.PlannedQuantity as LotPlannedQuantity,
        mla.InitialPlannedQuantity as LotInitialPlannedQuantity,
    	COALESCE(sa.CompletedQuantity, CASE
    		WHEN sa.Status = 40 THEN mla.PlannedQuantity
    		ELSE 0
    	END) as CompletedQuantity
    FROM WorkOrder.SegmentActuals sa
    JOIN WorkOrder.MaterialLotActuals mla
    ON mla.Id = sa.MaterialLotActualId
    JOIN WorkOrder.WorkOrders wo
    ON wo.Id = mla.WorkOrderId
GO
CREATE UNIQUE CLUSTERED INDEX [IX_WorkOrderPriorityInitialized_WorkOrderPriority_ReadyOn_SegmentActualId]
    ON [WorkOrder].[View_OperationWithoutOperationName]([WorkOrderPriorityInitialized] DESC, [WorkOrderPriority] ASC, [ReadyOn] ASC, [SegmentActualId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentId_SegmentsDefinitionId_OnHold_Status]
    ON [WorkOrder].[View_OperationWithoutOperationName]([SegmentId] ASC, [SegmentsDefinitionId] ASC, [OnHold] ASC, [Status] ASC)
    INCLUDE([MaterialLotActualId], [LotIdentifier], [WorkOrderId], [WorkOrderName], [ProducedMaterialId], [ProductionLineId], [StartedOnUnitId], [StartedOn], [StartedBy], [CompletedOn], [CompletedBy], [LotPlannedQuantity], [CompletedQuantity], [LotInitialPlannedQuantity]);


GO
CREATE NONCLUSTERED INDEX [IX_View_OperationWithoutOperationName_SegmentActualId]
    ON [WorkOrder].[View_OperationWithoutOperationName]([SegmentActualId] ASC)
    INCLUDE([SegmentId], [SegmentsDefinitionId]);


GO
CREATE NONCLUSTERED INDEX [IX_View_OperationWithoutOperationName_SegmentId_WorkOrderId]
    ON [WorkOrder].[View_OperationWithoutOperationName]([SegmentId] ASC, [WorkOrderId] ASC)
    INCLUDE([SegmentsDefinitionId]);


GO
CREATE NONCLUSTERED INDEX [IX_View_OperationWithoutOperationName_WorkOrderId]
    ON [WorkOrder].[View_OperationWithoutOperationName]([WorkOrderId] ASC)
    INCLUDE([SegmentId], [SegmentsDefinitionId]);


GO
CREATE NONCLUSTERED INDEX [IX_View_OperationWithoutOperationName_LotIdentifier_Status]
    ON [WorkOrder].[View_OperationWithoutOperationName]([LotIdentifier] ASC, [Status] ASC);


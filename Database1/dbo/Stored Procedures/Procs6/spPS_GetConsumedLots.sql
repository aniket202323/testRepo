
CREATE PROCEDURE [dbo].[spPS_GetConsumedLots]
 @ComponentId Int = Null
,@TargetMaterialLotIds nvarchar(max) = null
,@SourceMaterialLotId Int  = Null
,@WorkOrderId Int  = Null
,@SegmentId Int  = Null
,@BOMItemId Int  = Null
,@PageNumber Int  = Null -- Current page number
,@PageSize Int  = Null -- Total records per page to display

  AS
   BEGIN
		DECLARE @SQL NVARCHAR(MAX)='';
		 DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);
		 DECLARE @TotalRecords INT =0;
		 DECLARE @AllTargetLotIds Table (TargetLot_Id Int)
		
		if (@TargetMaterialLotIds is not null)
		INSERT INTO @AllTargetLotIds (TargetLot_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('xxx', @TargetMaterialLotIds, ',')
		
SELECT @SQL ='
select 
	c.event_id EventId,
	c.source_event_id SourceEventId,
	c.Component_Id ComponentId,
	w.work_order_id WorkOrderId,
	w.bom_item_id BOMItemId,
	w.segment_id SegmentId,
	c.Dimension_X DimensionX,
	es.Dimension_X_Eng_Unit_Id,
	CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as lotIdentifier,
	dbo.fnServer_CmnConvertFromDbTime(c.entry_on,''UTC'') as entry_on,c.user_id, dbo.fnServer_CmnConvertFromDbTime(c.Timestamp,''UTC'') as time_stamp,
	CASE WHEN (e.applied_product IS NOT NULL) THEN e.applied_product ELSE prods.prod_id END as applied_product,
	e.pu_id,
	COUNT(0) OVER() totalRecords
from 
	event_components c
	left join WorkOrder_Event_Components w on w.Component_Id=c.Component_Id
	inner join events e on e.event_id=c.source_event_id
	left join Event_Configuration ec on ec.PU_Id = e.PU_Id and ec.ET_Id = 1
	left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
	left join production_starts prods on (prods.PU_Id=e.Pu_id and e.Timestamp > prods.start_time and (e.Timestamp <= prods.end_time or prods.end_time is NULL))
where 
	c.Report_As_Consumption=1 and c.Dimension_X is not null and c.Dimension_X !=0
	'+CASE WHEN @TargetMaterialLotIds IS NULL THEN '' ELSE 'AND c.event_id  in ('+@TargetMaterialLotIds+')' END +'
	'+CASE WHEN @SourceMaterialLotId IS NULL THEN '' ELSE 'AND c.source_event_id='+Cast(@SourceMaterialLotId as nvarchar)+' ' END +'
	'+CASE WHEN @WorkOrderId IS NULL THEN '' ELSE 'AND w.work_order_id='+Cast(@WorkOrderId as nvarchar)+' ' END +'
	'+CASE WHEN @SegmentId IS NULL THEN '' ELSE 'AND w.segment_id='+cast(@SegmentId as nvarchar)+' ' END +'
	'+CASE WHEN @BOMItemId IS NULL THEN '' ELSE 'AND w.bom_item_id='+cast(@BOMItemId as nvarchar)+' ' END +'
	'+CASE WHEN @ComponentId IS NULL THEN '' ELSE 'AND c.Component_Id='+cast(@ComponentId as nvarchar)+' ' END +'
order by c.entry_on 
OFFSET '+Cast(@StartPosition as nvarchar)+' ROWS
FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;
			'
			--SELECT @SQL
			EXEC (@SQL)
    END

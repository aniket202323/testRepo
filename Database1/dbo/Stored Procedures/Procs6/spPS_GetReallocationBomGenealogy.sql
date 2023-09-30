
CREATE PROCEDURE [dbo].[spPS_GetReallocationBomGenealogy]
@SourceMaterialLotId Int  = Null
,@WorkOrderId Int  = Null
,@SegmentId Int  = Null
,@BOMItemId Int  = Null
  AS
   BEGIN	
	select 
	              c.event_id EventId,
				  c.source_event_id SourceEventId,
				  w.Component_Id ComponentId,
				  w.work_order_id WorkOrderId,
				  w.bom_item_id BOMItemId,
				  w.segment_id SegmentId,
				  c.Dimension_X DimensionX,
				  es.Dimension_X_Eng_Unit_Id,
				  CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as lotIdentifier,
				  c.entry_on
				  from event_components c
     inner join WorkOrder_Event_Components w on w.Component_Id=c.Component_Id
     inner join events e on e.event_id=c.source_event_id
     left join Event_Configuration ec on ec.PU_Id = e.PU_Id and ec.ET_Id = 1
     left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
		where 
			 c.event_id in (select distinct s.event_id from event_components s where s.source_event_id=@SourceMaterialLotId and s.dimension_x < 0)
			And w.work_order_id=@WorkOrderId
			And w.segment_id=@SegmentId
			And w.bom_item_id=@BOMItemId
			And c.dimension_x > 0
			And e.event_id !=@SourceMaterialLotId
			order by c.entry_on; 
    END

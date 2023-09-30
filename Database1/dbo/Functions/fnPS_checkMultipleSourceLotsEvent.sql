
CREATE FUNCTION  dbo.fnPS_checkMultipleSourceLotsEvent (@OriginMaterialLotId Int, @WorkOrderId Int, @SegmentId Int, @BOMItemId Int)
  RETURNS nvarchar(100)
AS 
BEGIN 
    DECLARE @SourceCount Int;
	select 
	        @SourceCount = count(distinct c.source_event_id)
				  from event_components c
     inner join WorkOrder_Event_Components w on w.Component_Id=c.Component_Id
	 inner join events e on e.event_id=c.source_event_id
     left join Event_Configuration ec on ec.PU_Id = e.PU_Id and ec.ET_Id = 1
     left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
	 where  
	 c.event_id=@originMaterialLotId
			And w.work_order_id=@WorkOrderId
			And w.segment_id=@SegmentId
			And w.bom_item_id=@BOMItemId

	IF @SourceCount = 0
    BEGIN
        RETURN 'NO_SOURCE_LOTS'
	 END
	
	IF @SourceCount > 1
    BEGIN
          RETURN 'true'	
	 END
	 	  RETURN 'false'	
END



CREATE PROCEDURE [dbo].[spPS_ReallocationUpdateInventoryConsumption]
@UserId int
,@EventId int
,@TargetEventId int
,@DimensionX float
,@BOMItemId int
,@SegmentId int
,@WorkOrderId int

  AS
  DECLARE @countFinalDimX int,
          @componentId int,
          @InitialDimensionX float = 0,
          @FinalDimensionX float = 0,
		  @TimeStamp Datetime
  
     SELECT @InitialDimensionX = final_dimension_x FROM Event_details
   	 WHERE event_id=@EventId;

    SET @FinalDimensionX = ((@InitialDimensionX) - @DimensionX);

  BEGIN TRANSACTION
 
   EXECUTE spServer_DBMgrUpdEventDet @UserId,
                                      @EventId,
                                      NULL,
                                      NULL,
                                      1,
                                      105,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      @FinalDimensionX,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL
    IF @@ERROR <> 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('Error in update record in Event_Details table.', 16, 1)
      RETURN
    END
    
    WAITFOR DELAY '00:00:00.010';

	If @TimeStamp Is Null
	BEGIN
		Select @TimeStamp = dbo.fnServer_CmnGetDate(getUTCdate())
	END
    	
    EXECUTE spServer_DBMgrUpdEventComp @UserId,
                                       @TargetEventId,
                                       @componentId OUTPUT,
                                       @EventId ,
                                       @DimensionX,
                                       NULL,
                                       NULL,
                                       NULL,
                                       0,
                                       1,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       @TimeStamp,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL
    IF @@ERROR <> 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('Error in insert record in Event_Components table.', 16, 1)
      RETURN
    END

	IF @componentId is null
	BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('Error in insert record in Event_Components table.', 16, 1)
      RETURN
    END
    
	EXECUTE spPS_UpdWorkOrderEventComponents @componentId, @BOMItemId, @SegmentId, @WorkOrderId

 IF @@ERROR <> 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('Error in insert record in Event_Components table.', 16, 1)
      RETURN
    END


    SELECT
      @countFinalDimX = final_dimension_x
    FROM Event_details
    WHERE final_dimension_x = 0
    AND Event_Id = @EventId;
    IF @countFinalDimX IS NOT NULL
    BEGIN
      UPDATE events
      SET event_status = 8
      WHERE event_id = @EventId;
    END
    IF @@ERROR <> 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('Error in update event_status in Events table.', 16, 1)
      RETURN
    END
    
  COMMIT;
  
	SELECT 
      ec.event_id EventId,
      ec.source_event_id sourceEventId,
      ec.dimension_x DimensionX,
	  woC.BOM_Item_Id BOMItemId,
	  woC.Segment_Id SegmentId,
	  woC.Work_Order_Id WorkOrderId,
	  ec.Component_Id ComponentId,
	  es.Dimension_X_Eng_Unit_Id
    FROM event_components ec
	inner join WorkOrder_Event_Components woC on woC.Component_Id=ec.Component_Id
	left join events e on e.Event_Id =ec.source_event_id
	left join Event_Configuration econ on econ.PU_Id = e.PU_Id and econ.ET_Id = 1
	left join Event_Subtypes es on es.Event_Subtype_Id = econ.Event_Subtype_Id
    WHERE ec.Component_Id = @componentId
    ORDER BY ec.timestamp DESC;


 

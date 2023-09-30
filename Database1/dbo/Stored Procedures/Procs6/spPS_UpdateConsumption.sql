
CREATE PROCEDURE [dbo].[spPS_UpdateConsumption]
@UserId int
,@EventId int
,@DimensionX float

  AS
  DECLARE @countFinalDimX int,
          @componentId int,
          @InitialDimensionX float = 0,
          @FinalDimensionX float = 0,
		  @TimeStamp Datetime

  BEGIN TRANSACTION

     SELECT @FinalDimensionX = final_dimension_x FROM Event_details
   	 WHERE event_id=@EventId;
   	 
   	 SELECT @InitialDimensionX = initial_dimension_x FROM Event_details
   	 WHERE event_id=@EventId;

    SET @FinalDimensionX = (@FinalDimensionX - @DimensionX);
    
    IF @FinalDimensionX > @InitialDimensionX
    BEGIN
          ROLLBACK
                  RAISERROR ('FinalDimensionX value must not be greater than InitialDimensionX .', 16, 1)
           RETURN
    END

    IF @FinalDimensionX < 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('FinalDimensionX value is not valid .', 16, 1)
      RETURN
    END

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
 
 
 SELECT final_dimension_x FROM Event_details  WHERE event_id=@EventId;
 
  COMMIT;
 

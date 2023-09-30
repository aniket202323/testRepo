
CREATE PROCEDURE [dbo].[spPS_UpdateMaterialTracebility]
@UserId int,
@EventId int ,
@ComponentId int output,
@SrcEventId int , 
@DimensionX Float,
@DimensionY Float ,
@DimensionZ Float ,
@DimensionA Float,
@ChildUnitId int,
@Start_Coordinate_X        Float = Null ,
@Start_Coordinate_Y        Float = Null ,
@Start_Coordinate_Z        Float = Null ,
@Start_Coordinate_A        Float = Null ,
@Start_Time        DateTime,
@TimeStamp        DateTime,
@Parent_Component_Id Int = Null,
@Entry_On        DateTime  = Null ,
@Extended_Info        nvarchar(255) = Null,
@PEI_Id                              Int            = Null ,
@ReportAsConsumption Int = Null,
@SignatureId Int = Null,
@SendPost            int = 0
 
   AS
  DECLARE
          @InitialDimensionX float = 0,
          @FinalDimensionX float = 0

BEGIN TRANSACTION

	If @TimeStamp Is Null
	BEGIN
		Select @TimeStamp = dbo.fnServer_CmnGetDate(getUTCdate())
	END

     SELECT @InitialDimensionX = final_dimension_x FROM Event_details
   	 WHERE event_id=@SrcEventId;

    SET @FinalDimensionX = ((@InitialDimensionX) - @DimensionX);

    IF @FinalDimensionX < 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('FinalDimensionX value is not valid .', 16, 1)
      RETURN
    END


   EXECUTE spServer_DBMgrUpdEventDet @UserId,
                                      @SrcEventId,
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
                                      @Entry_On ,
                                      @TimeStamp,
                                      NULL,
                                      @SignatureId,
									  NULL
                           
   IF @@ERROR <> 0
    BEGIN
      -- Rollback the transaction
      ROLLBACK
      -- Raise an error and return
      RAISERROR ('Error in update record in Event_Details table.', 16, 1)
      RETURN
    END

       EXECUTE spServer_DBMgrUpdEventComp @UserId,
                                       @EventId,
                                       @componentId OUTPUT,
                                       @SrcEventId ,
                                       @DimensionX ,
                                       @DimensionY ,
                                       @DimensionZ ,
                                       @DimensionA ,
                                       0,
                                       1,
                                       @ChildUnitId ,
                                       @Start_Coordinate_X ,
                                       @Start_Coordinate_Y ,
                                       @Start_Coordinate_Z ,
                                       @Start_Coordinate_A ,
                                       @Start_Time,
                                       @TimeStamp,
                                       @Parent_Component_Id,
                                       @Entry_On ,
                                       @Extended_Info,
                                       @PEI_Id,
                                       @ReportAsConsumption,
                                       @SignatureId,
                                       @SendPost    
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
	
    	
  COMMIT;	

	SELECT 
      ec.event_id EventId,
      ec.source_event_id sourceEventId, 
	  ec.Component_Id ComponentId,
	  ec.user_id UserId,
	  ec.dimension_x DimensionX,
	  ec.Dimension_Y DimensionY,
	  ec.Dimension_Z DimensionZ,
	  ec.Dimension_A DimensionA, 
	  ec.Entry_On Entry_On,
	  ec.Parent_Component_Id Parent_Component_Id,
	  ec.PEI_Id PEI_Id ,
	  ec.Report_As_Consumption ReportAsConsumption,
	  ec.Signature_Id SignatureId,
	  ec.Timestamp TimeStamp
      FROM event_components ec
	inner join events e on e.Event_Id =ec.source_event_id
    WHERE ec.Component_Id = @componentId
    ORDER BY ec.timestamp DESC; 

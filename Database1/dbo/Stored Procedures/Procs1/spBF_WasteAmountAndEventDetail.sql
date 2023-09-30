CREATE PROCEDURE dbo.spBF_WasteAmountAndEventDetail
 	   @EventId Int
 	 , @Amount Float
 	 , @DimensionX Float
 	 , @Userid Int
AS
DECLARE @WEDIdS TABLE(Id Int Identity(1,1),WasteId Int,Amount Float,PUId Int,WasteTime DateTime)
DECLARE @Start Int
DECLARE @End Int
DECLARE @WedId Int
DECLARE @PUId  Int
DECLARE @WasteTime DateTime
DECLARE @EventCount Int
DECLARE @OldWasteAmt Float
DECLARE @OldInitial  Float
DECLARE @OldFinal    Float
DECLARE @NewInitial  Float
IF @EventId Is Null
BEGIN
 	 SELECT Error = 'Error:Event Id is Required'
 	 RETURN
END
IF NOT EXISTS(SELECT 1 FROM EVENTS WHERE Event_id = @EventId)
BEGIN
 	 SELECT Error = 'Error:Event Id Not Found'
 	 RETURN
END
SELECT @PUId = PU_Id FROM Events WHERE Event_id = @EventId
IF @Amount Is Null and @DimensionX Is Null
BEGIN
 	 SELECT Error = 'Error: Amount or DimensionX required'
 	 RETURN
END
IF @Amount Is Null 
BEGIN
 	 SELECT @Amount = Coalesce(sum(Amount),0) 
 	  	 FROM Waste_Event_Details
 	  	 WHERE Event_Id =  @EventId
END
IF @DimensionX Is Null 
BEGIN
 	 SELECT  @DimensionX = Coalesce(sum(Final_Dimension_X),0)
 	 FROM Event_Details 
 	 WHERE  Event_Id =  @EventId
END
IF @Amount Is Null SET @Amount = 0
IF @DimensionX Is Null SET @DimensionX = 0
INSERT INTO @WEDIdS(WasteId,Amount,PUId,WasteTime)
 	 SELECT WED_Id,Amount,Pu_Id,Timestamp
 	  	 FROM Waste_Event_Details 
 	  	 WHERE Event_Id = @EventId
SET @End = @@ROWCOUNT
BEGIN TRY
 	 BEGIN TRANSACTION
 	 IF @Amount = 0 OR @End > 1-- DELETE
 	 BEGIN
 	  	 IF @Amount = 0
 	  	  	 SET @Start = 1
 	  	 ELSE 
 	  	  	 SET @Start = 2 -- More than 1 record
 	  	 WHILE @Start <= @End
 	  	 BEGIN
 	  	  	 SELECT @WedId = WasteId,@PUId =PUId,@WasteTime = WasteTime FROM @WEDIdS WHERE Id = @Start
 	  	  	 EXECUTE spServer_DBMgrUpdWasteEvent @WedId,@PUId,Null,@WasteTime,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,3,
 	  	  	  	  	  	  	  	  	  	  	  	 0,@Userid,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null
 	  	  	 SET @Start = @Start + 1
 	  	 END
 	 END
 	 IF  @Amount != 0 AND @End > 0 -- UPDATE
 	 BEGIN
 	  	  	 SELECT @WedId = WasteId,@PUId =PUId,@WasteTime = WasteTime,@OldWasteAmt = Coalesce(Amount,0)
 	  	  	  FROM @WEDIdS 
 	  	  	  WHERE Id = 1
 	  	  	  IF @OldWasteAmt != @Amount
 	  	  	  	  	 EXECUTE spServer_DBMgrUpdWasteEvent @WedId,@PUId,Null,@WasteTime,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @EventId,@Amount,Null,Null,2,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 0,@Userid,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null
 	 END
 	 IF  @Amount != 0 AND @End = 0 -- Add
 	 BEGIN
 	  	  	 SELECT @PUId =PU_Id,@WasteTime = TimeStamp FROM EVENTS WHERE Event_id = @EventId
 	  	  	 EXECUTE spServer_DBMgrUpdWasteEvent Null,@PUId,Null,@WasteTime,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 @EventId,@Amount,Null,Null,1,
 	  	  	  	  	  	  	  	  	  	  	  	 0,@Userid,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	 Null,Null
 	 END
 	 /*****************************/
 	 /** Work on Event Dimension **/
 	 /*****************************/
 	 SET @NewInitial = @Amount + @DimensionX
 	 IF NOT EXISTS(SELECT 1 FROM Event_Details WHERE Event_Id = @EventId)
 	 BEGIN
 	  	 EXECUTE spServer_DBMgrUpdEventDet
 	  	  	 @UserId,@EventId,@PUId,Null,1,
 	  	  	 0,Null,Null, @NewInitial,Null, 
 	  	  	 Null,Null,@DimensionX,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null 
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @OldInitial = Coalesce(Initial_Dimension_X,0),@OldFinal = Coalesce(Final_Dimension_X,0)
 	  	  	 FROM Event_Details 
 	  	  	 WHERE Event_Id = @EventId
 	  	 IF @NewInitial != @OldInitial
 	  	 BEGIN
 	  	  	 EXECUTE spServer_DBMgrUpdEventDet
 	  	  	 @UserId,@EventId,@PUId,Null,2,
 	  	  	 101,Null,Null, @NewInitial,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null 
 	  	 END
 	  	 IF @DimensionX != @OldFinal
 	  	 BEGIN
 	  	  	 EXECUTE spServer_DBMgrUpdEventDet
 	  	  	 @UserId,@EventId,@PUId,Null,2,
 	  	  	 105,Null,Null, Null,Null, 
 	  	  	 Null,Null,@DimensionX,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null,Null,Null,Null, 
 	  	  	 Null,Null 
 	  	 END
 	 END
 	 IF @@TRANCOUNT > 0    COMMIT TRANSACTION
 	 SELECT 'Success'
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0    ROLLBACK TRANSACTION
 	 SELECT Error = 'Error: Unknown Error updating'
END CATCH

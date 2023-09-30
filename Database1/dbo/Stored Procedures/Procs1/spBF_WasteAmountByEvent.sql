CREATE PROCEDURE dbo.spBF_WasteAmountByEvent
 	   @EventId Int
 	 , @Amount Float
 	 , @Userid Int
AS
DECLARE @WEDIdS TABLE(Id Int Identity(1,1),WasteId Int,Amount Float,PUId Int,WasteTime DateTime)
DECLARE @Start Int
DECLARE @End Int
DECLARE @WedId Int
DECLARE @PUId  Int
DECLARE @WasteTime DateTime
DECLARE @TotalAmount Float
DECLARE @EventCount Int
IF @EventId Is Null
BEGIN
 	 SELECT Error = 'Error: Event Id is Required'
 	 RETURN
END
IF NOT EXISTS(SELECT 1 FROM EVENTS WHERE Event_id = @EventId)
BEGIN
 	 SELECT Error = 'Error: Event Id Not Found'
 	 RETURN
END
INSERT INTO @WEDIdS(WasteId,Amount,PUId,WasteTime)
 	 SELECT WED_Id,Amount,Pu_Id,Timestamp
 	  	 FROM Waste_Event_Details 
 	  	 WHERE Event_Id = @EventId
SET @End = @@ROWCOUNT
IF @Amount Is Null Or @Amount = 0 OR @End > 1-- DELETE
BEGIN
 	 IF @Amount Is Null Or @Amount = 0
 	  	 SET @Start = 1
 	 ELSE 
 	  	 SET @Start = 2
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
IF  @Amount Is Not Null AND @Amount != 0 AND @End > 0 -- UPDATE
BEGIN
 	  	 SELECT @WedId = WasteId,@PUId =PUId,@WasteTime = WasteTime FROM @WEDIdS WHERE Id = 1
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
IF  @Amount Is Not Null AND @Amount != 0 AND @End = 0 -- Add
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
Select 'Success'

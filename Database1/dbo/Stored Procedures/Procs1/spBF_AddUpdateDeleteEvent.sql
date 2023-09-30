CREATE PROCEDURE dbo.spBF_AddUpdateDeleteEvent
 	   @UnitId Int
 	  ,@EventNum nVarChar(100) = Null
 	  ,@StartTime DateTime = Null   ---Must be UTC
 	  ,@EndTime DateTime = Null
 	  ,@ProdId 	 Int = Null
 	  ,@EventId Int = Null
 	  ,@TransType Int
 	 , @Userid Int = 1
AS
DECLARE @OpenEvents TABLE(Id Int Identity(1,1),EventId Int,EndTime DateTime)
DECLARE @UnitCheck Int
DECLARE @ProdCheck Int
DECLARE @EventCheck DateTime
DECLARE @OpenEventId Int
DECLARE @CurrentTime DateTime
DECLARE @MaxEventTime DateTime
DECLARE @MaxEventStatus Int
DECLARE @MaxEventNum nVarChar(100)
Declare @TimeBuffer Int = 5
DECLARE @EventSpanSeconds Int = 1
DECLARE @OpenStatus Int = 16
DECLARE @ClosedStatus Int = 5
DECLARE @Start Int
DECLARE @End Int
DECLARE @WedId Int
SET @EventNum = rtrim(ltrim(@EventNum))
IF @EventNum = '' SET @EventNum = Null
--select @Userid = coalesce(UserId,1) from [dbo].User_Equipment_Assignment where EquipmentId = @UnitId and EndTime Is null
SELECT @StartTime = DateAdd(millisecond,-Datepart(millisecond,@StartTime),@StartTime)
SELECT @StartTime =  dbo.fnServer_CmnConvertToDbTime(@StartTime,'UTC')
SELECT @CurrentTime = dbo.fnServer_CmnConvertToDbTime(GETUTCDATE(),'UTC')
IF @TransType Not In(1)
BEGIN
 	 SELECT Error = 'Invalid Call'
 	 Return
END
SELECT @UnitCheck = PU_Id From Prod_Units WHERE pu_Id = @UnitId
IF @UnitCheck Is Null
BEGIN
 	 SELECT Error = 'Invalid Equipment Passed In'
 	 Return
END
IF @TransType = 1
BEGIN
/****  eventNum ****/
 	 IF @EventNum Is Null
 	 BEGIN
 	  	 SELECT Error = 'Valid Shop Order Required'
 	  	 Return
 	 END
 	 SELECT @EventCheck = Timestamp
 	 FROM Events
 	 WHERE pu_Id = @UnitId and event_Num =  	 @EventNum
 	 IF @EventCheck Is not Null
 	 BEGIN
 	  	 SELECT Error = 'Shop Order Number is not unique order found at [' + convert(nvarchar(25),@EventCheck) + ']'
 	  	 RETURN
 	 END
/****  Product ****/
 	 SELECT @ProdCheck  = Prod_Id
 	 FROM Products
 	 WHERE Prod_id = @ProdId
 	 IF @ProdCheck Is Null
 	 BEGIN
 	  	 SELECT Error = 'Valid Part Number Required'
 	  	 RETURN
 	 END
/****  StartTime ****/
 	 IF @StartTime Is Null
 	 BEGIN
 	  	 SELECT Error = 'Start Time Required '
 	  	 RETURN
 	 END
 	 IF @StartTime > DateAdd(minute,@TimeBuffer,@CurrentTime)
 	 BEGIN
 	  	 SELECT Error = 'Start Time can not be in the future '
 	  	 RETURN
 	 END
 	 SELECT @EndTime = Dateadd(Second,@EventSpanSeconds,@StartTime)
 	 SET @EventCheck = Null
 	 SELECT @EventCheck = Timestamp
 	 FROM Events
 	 WHERE pu_Id = @UnitId and timestamp =  	 @EndTime
 	 IF @EventCheck Is not Null
 	 BEGIN
 	  	 SELECT Error = 'Shop Order Number Time is not unique'
 	  	 RETURN
 	 END 	 
/***** Open event Work  ****/
 	 SELECT @MaxEventTime = Max(timestamp)
 	  	 FROM Events Where PU_Id  = @UnitId
 	 IF @MaxEventTime Is Not Null
 	 BEGIN
 	  	 SELECT @MaxEventStatus = Event_Status,@MaxEventNum = Event_Num
 	  	  FROM Events Where PU_Id  = @UnitId and TimeStamp = @MaxEventTime
 	  	 IF @MaxEventStatus = @OpenStatus
 	  	 BEGIN
 	  	  	 SELECT Error = 'Shop Order already in progress [' + @MaxEventNum + ']'
 	  	  	 RETURN
 	  	 END
 	 END
 	 INSERT INTO @OpenEvents(EventId,EndTime)
 	  	 SELECT Event_Id,Timestamp
 	  	 FROM Events 
 	  	 WHERE pu_Id = @UnitId and Event_Status = @OpenStatus
 	 SET @End = @@ROWCOUNT 
 	 SET @Start = 1
 	 WHILE @Start <= @End
 	 BEGIN
 	  	 SELECT @OpenEventId = Eventid From @OpenEvents WHERE Id = @Start
 	  	 UPDATE Events SET Event_Status = @ClosedStatus WHERE Event_Id = @OpenEventId
 	  	 SET @Start = @Start + 1
 	 END
 	 SET @OpenEventId = Null
 	 EXECUTE dbo.spServer_DBMgrUpdEvent @OpenEventId  OUTPUT, @EventNum,@UnitId,@EndTime,@ProdId, 
 	  	  	  	  	  	  	  	  	  	 Null, @OpenStatus,1,0,@Userid,
 	  	  	  	  	  	  	  	  	  	 Null,Null,Null,@startTime,@CurrentTime,
 	  	  	  	  	  	  	  	  	  	 0,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	 Null,Null,Null,0,Null
   IF @OpenEventId Is Null
   BEGIN
 	  	 SELECT Error = 'Create Failed'
 	  	 RETURN
   END
   ELSE
   BEGIN
 	  	 SELECT  ShopOrderId = Event_Id,ShopOrder = Event_Num,PartNumberId = Applied_Product,PartNumber = Prod_Desc,StartTime = Start_Time,EndTime = TimeStamp,
 	  	  	 OrderStatus = ProdStatus_Desc
 	  	  	 FROM Events a
 	  	  	 Left Join Products b on b.prod_Id = a. Applied_Product
 	  	  	 Join Production_Status c on c.ProdStatus_Id = a.Event_Status 
 	  	  	 WHERE Event_Id = @OpenEventId
 	  	 RETURN
   END
END
Select Error =  'Unknown'

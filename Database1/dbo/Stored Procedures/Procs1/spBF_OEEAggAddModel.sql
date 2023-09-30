Create Procedure dbo.spBF_OEEAggAddModel
 	  @Active int,
 	  @sInterval nvarchar(100),
 	  @sOffset nVarChar(100)
AS
 	  	  	  	  	  	  	  	  	  	  	 
DECLARE @ECId Int
Declare @Ecvid Int
DECLARE @UserId Int 
DECLARE @ReloadSetback DateTime
DECLARE @CommentId Int
SELECT @ReloadSetback = dbo.fnServer_CmnConvertToDbTime(GETUTCDATE(),'UTC')
SET @ReloadSetback = dateadd(hour,-datepart(hour,@ReloadSetback),@ReloadSetback)
SET @ReloadSetback = dateadd(minute,-datepart(minute,@ReloadSetback),@ReloadSetback)
SET @ReloadSetback = dateadd(second,-datepart(second,@ReloadSetback),@ReloadSetback)
SET @ReloadSetback = dateadd(millisecond,-datepart(millisecond,@ReloadSetback),@ReloadSetback)
SET @UserId = 1
SET @sInterval = 'TINT:' + @sInterval
SELECT @ECId = ec_Id FROM Event_Configuration WHERE ED_Model_Id = 49200
IF @ECId Is Null
BEGIN
 	 EXECUTE spEMEC_CreateNewEC   0,1,'OEE Aggregation Auto Model',7,null,@UserId,@ECId output,@CommentId Output
 	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,49200,@UserId
 	 EXECUTE spEMSEC_PutECData   2884,@ECId, 0,@sInterval, 1,Null,@UserId,null
 	 EXECUTE spEMSEC_PutECData  2885,@ECId,0,'spBF_OEEAggPopulateTable',1,Null,@UserId,Null
 	 EXECUTE spEMSEC_PutECData  2886,@ECId,0,@sOffset,1,Null,@UserId,Null
END
ELSE
BEGIN
 	 select @Ecvid = ECV_iD fROM Event_Configuration_Data WHERE EC_Id = @ECId and ED_Field_Id = 2884
 	 IF (select substring(Value,1,255) From Event_Configuration_Values WHERE ECV_Id = @Ecvid) != @sInterval
 	  	 EXECUTE spEMSEC_PutECData   2884,@ECId, 0,@sInterval, 1,Null,@UserId,@Ecvid
 	 SET 	 @Ecvid = Null
 	 select @Ecvid = ECV_iD fROM Event_Configuration_Data WHERE EC_Id = @ECId and ED_Field_Id = 2886
 	 IF (select substring(Value,1,255) From Event_Configuration_Values WHERE ECV_Id = @Ecvid) != @sOffset
 	  	 EXECUTE spEMSEC_PutECData   2886,@ECId, 0,@sOffset, 1,Null,@UserId,@Ecvid
END
EXECUTE spEMEC_UpdateIsActive  @ECId,@Active,@UserId
EXECUTE spEM_ReloadService   4,@ReloadSetback,2, @UserId,NULL

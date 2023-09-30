Create Procedure dbo.spEM_SystemCompleteActivityAddModel
 	  @Active int
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
Declare @sInterval  nVarChar(100)
--get this from site parameters - default 5 mins 
SET @sInterval = 'TINT:' + '5'
SELECT @ECId = ec_Id FROM Event_Configuration WHERE ED_Model_Id = 49300 -- check the new model created
IF @ECId Is Null
BEGIN
 	 EXECUTE spEMEC_CreateNewEC   0,1,'System Complete Activity Model',7,null,@UserId,@ECId output,@CommentId Output
 	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,49300,@UserId
 	 EXECUTE spEMSEC_PutECData   2887,@ECId, 0,@sInterval, 1,Null,@UserId,null
 	 EXECUTE spEMSEC_PutECData  2888,@ECId,0,'SPEM_SystemCompleteActivities',1,Null,@UserId,Null
 	 EXECUTE spEMSEC_PutECData  2889,@ECId,0,'5',1,Null,@UserId,Null
END
EXECUTE spEMEC_UpdateIsActive  @ECId,@Active,@UserId
EXECUTE spEM_ReloadService   4,@ReloadSetback,2, @UserId,NULL

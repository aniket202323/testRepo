CREATE PROCEDURE [dbo].[spLocal_CmnCalcVB_SimulateGetOldestPallet]
		@OutputValue				varchar(25) OUTPUT,
		@PUId						int,
		@Timestamp					datetime,
		@varidgo					int,
		@Go							bit,
		@CheckInScanId				int


-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_CmnCalcVB_SimulateGetOldestPallet
	@OutputValue				OUTPUT,
	5787,
	'8-May-2019 13:21:23',
	33891,
	'1'


	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON



DECLARE @RC					int
DECLARE @Var_Id				int
DECLARE @User_Id			int
DECLARE @Canceled			int
DECLARE @New_Result			varchar(25)
DECLARE @Result_On			datetime
DECLARE @TransNum			int
DECLARE @CommentId			int
DECLARE @ArrayId			int
DECLARE @EventId			int
DECLARE @PU_Id				int
DECLARE @Test_Id			bigint
DECLARE @Entry_On			datetime
DECLARE @SecondUserId		int
DECLARE @HasHistory			int
DECLARE @SignatureId		int
DECLARE @Locked				tinyint,
		@PathId				int,
		@plid				int,
		@Count				int,
		@WriteTime			datetime,
		@Pallet				varchar(20)


-- TODO: Set parameter values here.
SET @count = 0
IF @go = 1
BEGIN

	--Get oldest Delivered pallet	
	SET @eventId = (	SELECT TOP 1 event_id 
						FROM dbo.events e WITH(NOLOCK)
						JOIN dbo.production_status PS WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
						WHERE e.pu_id = @PUId
							AND ps.prodStatus_Desc = 'Delivered'
						ORDER BY timestamp ASC)		
						
	IF 	@eventId IS NOT NULL
	BEGIN
		--Get event_num truncated to ULID
		SET @Pallet = (SELECT SUBSTRING(event_num,0,CHARINDEX('_',event_num)) FROM dbo.events WITH(NOLOCK) where event_id = @eventId)

		


		SET @User_Id =(SELECT entry_by FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @Timestamp)
		SET @Canceled = 0
		SET @TransNum = 0	


		SELECT 	2,
		@CheckInScanId,
		@puid,
		@User_Id,
		@Canceled,
		@Pallet,
		@Timestamp,
		1,
		0,
		NULL,
		@TransNum,
		@EventId,
		@ArrayId,
		@CommentId,
		@SignatureId,
		@Entry_On,
		@Test_Id,
		NULL,
		NULL,
		NULL


		SELECT	@OutputValue = '@Pallet'

	END
	ELSE
	BEGIN
		SELECT	@OutputValue = 'No delivered pallet'
	END							










END
	  
--	  SET @Var_Id = (SELECT MIN(varid) FROM @Variables WHERE varid > @Var_Id)
--END



SELECT	@OutputValue = CONVERT(varchar(30),@Count) + ' Variable(s) updated'

RETURN
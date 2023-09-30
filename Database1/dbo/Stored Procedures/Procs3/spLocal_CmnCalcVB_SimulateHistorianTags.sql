CREATE PROCEDURE [dbo].[spLocal_CmnCalcVB_SimulateHistorianTags]
		@OutputValue				varchar(25) OUTPUT,
		@pathCode					varchar(30),
		@Zone						varchar(30),
		@PO							varchar(12),
		@TransTime					datetime,
		@Go							bit,
		@varIDGo					int,
		@PUId						int


-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_CmnCalcVB_SimulateHistorianTags
	@OutputValue				OUTPUT,
	'PESCO00',				
	'Zone1',
	'0',
	'6-Oct-2016 16:53',
	1,
	14720

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON



DECLARE @RC int
DECLARE @Var_Id int
DECLARE @User_Id int
DECLARE @Canceled int
DECLARE @New_Result varchar(25)
DECLARE @Result_On datetime
DECLARE @TransNum int
DECLARE @CommentId int
DECLARE @ArrayId int
DECLARE @EventId int
DECLARE @PU_Id int
DECLARE @Test_Id bigint
DECLARE @Entry_On datetime
DECLARE @SecondUserId int
DECLARE @HasHistory int
DECLARE @SignatureId int
DECLARE @Locked tinyint,
		@PathId		int,
		@plid		int,
		@Count		int,
		@WriteTime	datetime


-- TODO: Set parameter values here.
SET @count = 0
IF @go = 1
BEGIN
	SET @Result_On = @TransTime
	SET @Result_On = DATEADD(MS,(-1*DATEPART(ms,@Result_On)),@Result_On)


	DECLARE @Variables TABLE (
	varid				int,
	puid				int
	)

	SET @PathId = (SELECT path_id FROM dbo.prdExec_paths WHERE path_code = @pathcode)

	INSERT @Variables (varid, puid)
	SELECT v.var_id, v.pu_id
	FROM dbo.prdexec_path_units ppu		WITH(NOLOCK)
	JOIN dbo.variables v				WITH(NOLOCK) ON ppu.pu_id = v.pu_id
														AND v.extended_info = @Zone
	WHERE ppu.Path_Id = @PathId

	SET @User_Id =(SELECT entry_by FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @TransTime)
	SET @Canceled = 0
	SET @TransNum = 0

	SET @WriteTime = (SELECT Entry_On FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @TransTime)
	SET @WriteTime = DATEADD(MS,(-1*DATEPART(ms,@WriteTime)),@WriteTime)


	SET @Count = (SELECT COUNT(1) FROM @Variables)
	--SET @Var_Id = (SELECT MIN(varid) FROM @Variables)
	--WHILE @Var_Id IS NOT NULL
	--BEGIN
	--	SELECT @PU_Id = puid from @Variables WHERE varid = @Var_Id

		--EXECUTE @RC = [dbo].[spServer_DBMgrUpdTest2] 
		--   @Var_Id
		--  ,@User_Id
		--  ,@Canceled
		--  ,@PO
		--  ,@Result_On
		--  ,@TransNum
		--  ,@CommentId
		--  ,@ArrayId
		--  ,@EventId OUTPUT
		--  ,@PU_Id OUTPUT
		--  ,@Test_Id OUTPUT
		--  ,@Entry_On OUTPUT
		--  ,@SecondUserId
		--  ,@HasHistory OUTPUT
		--  ,@SignatureId
		--  ,@Locked
	SELECT 	2,
			VarId,
			PUId,
			@User_Id,
			@Canceled,
			@PO,
			@WriteTime,
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
	FROM @Variables
END
	  
--	  SET @Var_Id = (SELECT MIN(varid) FROM @Variables WHERE varid > @Var_Id)
--END



SELECT	@OutputValue = CONVERT(varchar(30),@Count) + ' Variable(s) updated'

RETURN
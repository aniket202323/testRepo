CREATE PROCEDURE [dbo].[spLocal_CmnCalcVB_SimulateFreePosition]
		@OutputValue				varchar(25) OUTPUT,
		@PUId						int,
		@Timestamp					datetime,
		@varidgo					int,
		@Go							int


-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_CmnCalcVB_SimulateFreePosition
	@OutputValue				OUTPUT,
	5787,
	'8-May-2019 13:21:23',
	33891,
	'1'


	
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


	DECLARE @Variables TABLE (
	varid				int,
	Num					int,
	value				varchar(30),
	puid				int
	)


	INSERT @Variables (value,num, puid)
	SELECT t.result, user_defined2, @puid
	FROM	dbo.variables_base v				WITH(NOLOCK) 
	LEFT JOIN	dbo.tests t							WITH(NOLOCK) ON v.var_id = t.var_id
															AND	t.result_on = @Timestamp
	WHERE v.pu_id = @PUId
		AND v.extended_info = 'Source'
														

	SET @User_Id =(SELECT entry_by FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @Timestamp)
	SET @Canceled = 0
	SET @TransNum = 0

	SET @WriteTime = (SELECT Entry_On FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @Timestamp)
	SET @WriteTime = DATEADD(MS,(-1*DATEPART(ms,@WriteTime)),@WriteTime)

	UPDATE v 
	SET varid = v1.var_id
	FROM @Variables v
	JOIN dbo.variables_base v1 ON v.num = v1.user_defined2
								AND v1.pu_id = @puid
								AND v1.extended_info = 'Target'

	DELETE @Variables WHERE value IS NULL

	SET @Count = (SELECT COUNT(1) FROM @Variables WHERE value IS NOT NULL)
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
			value,
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
	FROM @Variables WHERE value IS NOT NULL



END
	  
--	  SET @Var_Id = (SELECT MIN(varid) FROM @Variables WHERE varid > @Var_Id)
--END



SELECT	@OutputValue = CONVERT(varchar(30),@Count) + ' Variable(s) updated'

RETURN
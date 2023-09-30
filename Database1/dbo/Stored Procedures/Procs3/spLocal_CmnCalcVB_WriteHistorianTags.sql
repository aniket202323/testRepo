CREATE PROCEDURE [dbo].[spLocal_CmnCalcVB_WriteHistorianTags]
		@OutputValue				varchar(25) OUTPUT,
		@val						varchar(25),
		@Transtime					datetime,
		@Go							bit,
		@varIDGo					int,
		@varIdDest					int,
		@PUId						int


-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_CmnCalcVB_WriteHistorianTags


	
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
		@WriteTime			datetime


-- TODO: Set parameter values here.
SET @count = 0
IF @go = 1
BEGIN

	SET @User_Id =(SELECT entry_by FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @TransTime)
	SET @Canceled = 0
	SET @TransNum = 0

	SET @WriteTime = (SELECT Entry_On FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidgo and result_on = @TransTime)
	SET @WriteTime = DATEADD(MS,(-1*DATEPART(ms,@WriteTime)),@WriteTime)


	SELECT 	2,
			@varIdDest,
			@PUId,
			@User_Id,
			@Canceled,
			@val,
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
END
	  

SELECT	@OutputValue = @val

RETURN
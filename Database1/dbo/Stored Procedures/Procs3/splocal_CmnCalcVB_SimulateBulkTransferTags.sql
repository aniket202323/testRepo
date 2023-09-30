CREATE PROCEDURE [dbo].[splocal_CmnCalcVB_SimulateBulkTransferTags]
		@outputValue				varchar(25) OUTPUT,
		@timestamp					datetime,
		@puId						int,
		@triggerVarId				int



AS
SET NOCOUNT ON

--Result Sets
DECLARE 
@RC				int,
@Var_Id			int,
@User_Id		int,
@Canceled		int,
@New_Result		varchar(25),
@Result_On		datetime,
@TransNum		int,
@CommentId		int,
@ArrayId		int,
@EventId		int,
@PU_Id			int,
@Test_Id		bigint,
@Entry_On		datetime,
@SecondUserId	int,
@HasHistory		int,
@SignatureId	int,
@Locked			tinyint,
--Other
@Count			int,
@trigger		bit

DECLARE @VariablesSource TABLE (
var_id				int,
Result				varchar(25), 
extended_info		varchar(50)	
)

DECLARE @VariablesDestination TABLE (
var_id				int,
Result				varchar(25), 
extended_info		varchar(50)	
)


--get trigger value
SELECT	@trigger = result,
		@User_Id	= entry_by
FROM dbo.tests WITH(NOLOCK) 
WHERE	var_id = @TriggerVarId
	AND result_on = @Timestamp



SET @Count = 0
--only if triggers is set 
IF @Trigger = 1
BEGIN
	SET @Result_On = @Timestamp

	--Get the source dvariable with their value
	INSERT @VariablesSource ( var_id, result, extended_info)
	SELECT	v.var_id, 
			t.result,
			v.extended_info
	FROM dbo.variables v	WITH(NOLOCK)
		JOIN dbo.tests t	WITH(NOLOCK) ON v.var_id = t.var_id
											AND t.result_on = @timestamp
	WHERE v.pu_id = @puId
		AND v.Extended_Info LIKE 'STOR%'
		AND v.Output_Tag IS NULL
			

	--Push the copied value in the destination variable table
	INSERT @VariablesDestination (var_id, result, extended_info)
	SELECT	v.var_id,
			sv.result, 
			v.extended_info
	FROM @VariablesSource sv
		JOIN dbo.variables v ON sv.extended_info = v.extended_info
								AND v.pu_id = @puId

	SET @Canceled = 0
	SET @TransNum = 0

	SET @Count = (SELECT COUNT(1) FROM @VariablesDestination WHERE result IS NOT NULL)

	SELECT 	2,
			Var_Id,
			@puId,
			@User_Id,
			@Canceled,
			result,
			@timestamp,
			1,
			0,
			NULL,
			@TransNum,
			NULL,
			@ArrayId,
			@CommentId,
			@SignatureId,
			@Entry_On,
			@Test_Id,
			NULL,
			NULL,
			NULL
	FROM @VariablesDestination
	WHERE result IS NOT NULL
END
	  

SELECT	@OutputValue = CONVERT(varchar(30),@Count) + ' Variable(s) updated'

RETURN
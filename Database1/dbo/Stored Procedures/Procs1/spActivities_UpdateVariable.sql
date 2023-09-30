
CREATE PROCEDURE dbo.spActivities_UpdateVariable
@TransactionType Int,
@Activity_Id	int,
@Var_Id			int,
@UserId		int,
@New_Result		Nvarchar(25)


 AS 

DECLARE @Canceled int = 0, @Result_On datetime, @ActivityTypeId int, @KeyId1 int, @Sheet_Id int, @DataTypeId int, @DataType NVarchar(50), @VarPrecision tinyint, 
		@TotalVariables int, @UpdatedVariables int, @PercentComplete float, @TestId bigint, @Sheet_Desc NVarchar(50)
DECLARE @Results Table(Result Nvarchar(25))

SELECT @Result_On = a.Start_Time,
	@ActivityTypeId = a.Activity_Type_Id,
	@KeyId1 = a.KeyId1,
	@Sheet_Desc = SUBSTRING(a.Activity_Desc,2,case when CHARINDEX(e.Event_Num,a.Activity_Desc) > 0 
												then CHARINDEX(e.Event_Num,a.Activity_Desc) - 5 
											else 0 end)
FROM Activities a
LEFT JOIN [Events] e on e.Event_Id = a.KeyId1
WHERE Activity_Id = @Activity_Id

IF @TransactionType = 2 --ADD/UPDATE
BEGIN
	--
	-- Update the % Complete and Tests to Complete Columns on the Activities Table
	--
	--EXECUTE spServer_DBMgrUpdActivities @Activity_Id,NULL,NULL,NULL,NULL/*Status*/,NULL,NULL,NULL,@ActivityTypeId,NULL,NULL,NULL,NULL,NULL,NULL,2,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
	
	--
	-- Return the updated Activity Variable
	--
	EXECUTE  spActivities_GetVariableDetails @Activity_Id, @Var_Id

END


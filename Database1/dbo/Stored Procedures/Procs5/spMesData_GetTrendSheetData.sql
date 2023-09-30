
/*

	Copyright (c) 2019 GE Digital. All Rights Reserved.
	=============================================================================

	=============================================================================
	Author				212517152, Rabindra Kumar
	Create On			12-Aug-2020
	Last Modified		19-Aug-2020
	Description			Returns SPC Variables data.
	Procedure_name		[spMesData_GetTrendSheetData]

	================================================================================
	Input Parameter
	=================================================================================
	@VariableIds								--int--					Mandatory input paramater
	@StartTime									--datetime--			Optional input paramater
	@EndTime									--datetime--			Optional input paramater
	@AlarmTypeId								--int--					Optional input paramater
	@ReturnVariableInfo							--nvarchar(255)--		Optional input paramater

	================================================================================
	Result Set:- 1
	=================================================================================
	--Var_Id
	--Var_Desc


	================================================================================
	Result Set:- 2
	=================================================================================
	


	================================================================================
	Result Set:- 3
	=================================================================================
	


	================================================================================
	Result Set:- 4
	=================================================================================


*/
CREATE PROCEDURE [dbo].[spMesData_GetTrendSheetData] (
		 @VariableIds nvarchar(255) 
		,@StartTime datetime = NULL
		,@EndTime datetime = NULL
		,@AlarmTypeId int = NULL
		,@ReturnVariableInfo nvarchar(255) = NULL
	)
AS
BEGIN

	--variable declaration
	DECLARE @SPC_Calculation_Type_Id INT, @SPC_Group_Variable_Type_Id INT, @SPC_Var_Id INT,
	@SPC_Variable_Based_On_Group_Id INT, @Start_Id INT, @End INT, @Start INT,  @CommaSeparatedVarId NVARCHAR(255);
	
	-- Table value variable declaration
	DECLARE @AllVars TABLE (
		SlNo INT IDENTITY,
		VarId INT 
	)

	-- Table value variable declaration
	DECLARE @SPCVars TABLE (
		SlNo INT IDENTITY,
		VarId INT 
	)
	
	-- Table value variable declaration
	DECLARE @SPCAndCalculatedVars TABLE (
		SlNo INT IDENTITY,
		VarId INT 
	)
	
	-- If null set to default
	SET @ReturnVariableInfo = ISNULL(@ReturnVariableInfo, 1)
	SET @StartTime =  ISNULL(@StartTime, DATEADD(DAY, -168,  GETDATE()))
	SET @EndTime =  ISNULL(@EndTime, GETDATE())

	--Split comma seperated string
	DECLARE @xml XML
	SET @xml = CAST(('<X>'+REPLACE(@VariableIds,',','</X><X>')+'</X>') AS XML)
	INSERT INTO @AllVars(VarId)
	SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)

	--Filter SPC Variable
	INSERT INTO @SPCVars
	SELECT Var_Id FROM Variables_Base WHERE Var_Id IN (SELECT VarId FROM @AllVars) AND SPC_Calculation_Type_Id IS NOT NULL

	SET @Start = 1
	SELECT @End = MAX(SlNo) From @SPCVars 
	WHILE @Start <= @End
	BEGIN
		SET @SPC_Var_Id = (SELECT VarId FROM @SPCVars WHERE SlNo = @Start)
		SELECT @SPC_Calculation_Type_Id = SPC_Calculation_Type_Id, @SPC_Group_Variable_Type_Id = SPC_Group_Variable_Type_Id FROM Variables_Base WHERE Var_Id = @SPC_Var_Id

		-- Inserting actual SPC variable for average calculation
		INSERT INTO @SPCAndCalculatedVars (VarId) VALUES (@SPC_Var_Id);
		
		--logic to find the variable based on calculation type
		SELECT @SPC_Variable_Based_On_Group_Id = CASE 
			WHEN (@SPC_Calculation_Type_Id = 1) THEN @SPC_Var_Id
			WHEN (@SPC_Calculation_Type_Id = 2) THEN @SPC_Var_Id 
			WHEN (@SPC_Calculation_Type_Id = 3) THEN @SPC_Var_Id
			WHEN (@SPC_Calculation_Type_Id = 4) THEN (SELECT Var_Id FROM VARIABLES_base where spc_group_variable_type_id = 2 and Pvar_id = @SPC_Var_Id)
			WHEN (@SPC_Calculation_Type_Id = 5) THEN (SELECT Var_Id FROM VARIABLES_base where spc_group_variable_type_id = 3 and Pvar_id = @SPC_Var_Id)
			WHEN (@SPC_Calculation_Type_Id = 6) THEN (SELECT Var_Id FROM VARIABLES_base where spc_group_variable_type_id = 4 and Pvar_id = @SPC_Var_Id)
			WHEN (@SPC_Calculation_Type_Id = 7) THEN @SPC_Var_Id END

		-- Inserting the variable based on caculation type of SPC variable
		IF(@SPC_Variable_Based_On_Group_Id <> @SPC_Var_Id)
		BEGIN
			INSERT INTO @SPCAndCalculatedVars (VarId) VALUES (@SPC_Variable_Based_On_Group_Id)
		END
				
		SET @Start = @Start + 1
	-- End of while loop
	END
	
		SELECT @CommaSeparatedVarId = COALESCE(@CommaSeparatedVarId + ',' ,'') + convert(varchar(10), VarId) from @SPCAndCalculatedVars
		EXEC spCHT_GetTrendSheetData @StartTime, @EndTime, NULL, @ReturnVariableInfo, @CommaSeparatedVarId, NULL, NULL, NULL, NULL, '.'		
	
END 

GRANT EXECUTE ON [dbo].[spMesData_GetTrendSheetData] TO [ComXClient]
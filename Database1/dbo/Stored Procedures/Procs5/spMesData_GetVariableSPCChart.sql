

/*

	Copyright (c) 2019 GE Digital. All Rights Reserved.
	=============================================================================

	=============================================================================
	Author				212766792, Namrata Yadav
	Create On			21-Aug-2020
	Last Modified		21-Aug-2020
	Description			Returns SPC Variables data.
	Procedure_name		[spMesData_GetVariableSPCChart]

	================================================================================
	Input Parameter
	=================================================================================
	@VariableIds								--int--					Mandatory input paramater
	@StartTime									--datetime--			Optional input paramater
	@EndTime									--datetime--			Optional input paramater
	@NumberOfPoints		                        --int--                 Optional input parameter

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

CREATE PROCEDURE [dbo].[spMesData_GetVariableSPCChart] (
		 @VariableId				nvarchar(255) = NULL
		,@StartTime					datetime = NULL
		,@EndTime					datetime = NULL
		,@NumberOfSamplePoints		int = NULL
		,@Direction					tinyint = NULL, 	 -- 0 = Forward; 1 = Backwards
		@ProductList 	  			nVarChar(1000) = NULL,
		@ShiftList 	  	  			nVarChar(1000) = NULL,
		@CrewList 	  	  			nVarChar(1000) = NULL,
		@OrderList 	  	  			nVarChar(1000) = NULL,
		@EventList  	  	  		varchar(8000) = NULL,
		@NPFilter 	  	  			bit = 0,
		@ChartType 	  	  			smallint = 6,
		@CLType 	  	  	  		smallint = 0, 	 -- 0=Fixed; 1=Calculated
		@SubgroupType 	  			smallint = 0, 	 -- 0=Variable; 1=Time-Series
		@SubgroupSize 	  			int = 1,
		@SigmaFactor 	  			int = 3,
		@GoodValue 	  	  			nVarChar(100) = NULL,
		@InTimeZone 	  	  		nvarchar(200) = NULL 	
	)
AS
BEGIN
    DECLARE @SPCCalcType int
    SELECT @SPCCalcType = SPC_Calculation_Type_Id FROM variables_base WHERE Var_Id = @VariableId;
	-- If null set to default
	SET @StartTime =  ISNULL(@StartTime, DATEADD(DAY, -30, GETUTCDATE()))
	SET @EndTime =  ISNULL(@EndTime, GETUTCDATE())
	--SET @ChartType = ISNULL(@ChartType, 6)
	SET @ChartType = COALESCE(@SPCCalcType, @ChartType, 6)
	SET @Direction = ISNULL(@Direction, 1)
	SET @NPFilter = ISNULL(@NPFilter, 0)
	SET @CLType = ISNULL(@CLType, 0)
	SET @SubgroupType = ISNULL(@SubgroupType, 0)
	SET @SubgroupSize = ISNULL(@SubgroupSize, 1)
	SET @SigmaFactor = ISNULL(@SigmaFactor, 3)
	SET @InTimeZone = ISNULL(@InTimeZone, N'UTC')

	BEGIN TRY
        EXEC spASP_wrVariableSPCChart @VariableId, @StartTime, @EndTime, @NumberOfSamplePoints, @Direction, @ProductList, @ShiftList, @CrewList, @OrderList, @EventList, @NPFilter
        ,@ChartType,@CLType,@SubgroupType, @SubgroupSize, @SigmaFactor, @GoodValue,@InTimeZone
    END TRY
    BEGIN CATCH
        SET @EndTime = ISNULL(DATEADD(SECOND, 1, @EndTime) , GETUTCDATE())
        EXEC spASP_wrVariableSPCChart @VariableId, @StartTime, @EndTime, @NumberOfSamplePoints, @Direction, @ProductList, @ShiftList, @CrewList, @OrderList, @EventList, @NPFilter
            ,@ChartType,@CLType,@SubgroupType, @SubgroupSize, @SigmaFactor, @GoodValue,@InTimeZone
    END CATCH

END
GRANT EXECUTE ON [dbo].[spMesData_GetVariableSPCChart] TO [ComXClient]

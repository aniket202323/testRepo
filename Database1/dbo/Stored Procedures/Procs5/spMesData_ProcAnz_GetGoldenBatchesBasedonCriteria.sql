
/*
	Copyright (c) 2017 GE Digital. All Rights Reserved.
	=============================================================================

	=============================================================================
	Author				212517152, Rabindra Kumar
	Create On			12-April-2018
	Last Modified		12-June-2018
	Description			Returns Production Events.
	Procedure_name		[spMesData_ProcAnz_GetGoldenBatchesBasedonCriteria]

	================================================================================
	Input Parameter
	=================================================================================
	@dept_id                        --int--				Optional input paramater
	@line_id                        --int--				Optional input paramater
	@pu_id                          --int--				Optional input paramater
	@name							--nVARCHAR(255)--	Optional input paramater
	@product						--nVARCHAR(255)--	Optional input paramater
	@asset							--nVARCHAR(255)--	Optional input paramater
	@quantity						--nVARCHAR(255)--	Optional input paramater
	@status							--nVARCHAR(255)--	Optional input paramater
	@bom							--nVARCHAR(255)--	Optional input paramater
	@starttime                      --datetime--		Optional input paramater
	@endtime                        --datetime--		Optional input paramater
	@isIncremental                  --int--				Optional input paramater
	@sortCol						--nVARCHAR(100)--	Optional input paramater
	@sortOrder						--nvarchar(100 )--	Optional input paramater
	@pageNumber                     --bigint--			Optional input paramater
	@pageSize                       --bigint--			Optional input paramater

	================================================================================
	Result Set:- 1
	=================================================================================
	--SL_No
	--golden_batch_id
	--Department
	--Department_Description
	--Line
	--Line_Description
	--Unit
	--Unit_Description
	--Production_Type
	--Production_Variable
	--Product
	--Product_Description
	--Event
	--Event_Num
	--Event_Start_Time
	--Event_End_Time 
	--EventUTCTimeStamp
	--BOM
	--Production_Start_id
	--Production_Start_Time 
	--Production_End_Time
	--ProdUTCTimeStamp
	--Production_Status
	--Production_Status_Description
	--Quantity
	--UOM
	--NbResults
	--CurrentPage
	--PageSize
	--TotalPages

	================================================================================
	Result Set:- 2 (Distinct Plant Model [Asset] based on input parameter)
	=================================================================================
	--Id
	--Name
	--AssetType

	================================================================================
	Result Set:- 3 (Distinct Production Status based on input parameter)
	=================================================================================
	--Id
	--Name

	================================================================================
	Result Set:- 4 (Distinct Product based on input parameter)
	=================================================================================
	--Id
	--Name

*/

CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetGoldenBatchesBasedonCriteria]
	@dept_id						int = NULL
	,@line_id						int = NULL
	,@pu_id                         int = NULL
	,@name							nVARCHAR(255) = NULL
	,@product						nVARCHAR(255) = NULL
	,@asset							nVARCHAR(255) = NULL
	,@quantity						nVARCHAR(255) = NULL
	,@status						nVARCHAR(255) = NULL
	,@bom							nVARCHAR(255) = NULL
	,@starttime                     datetime = NULL
	,@endtime                       datetime = NULL
	,@isIncremental                 int = NULL
	,@sortCol						nVARCHAR(100) = NULL
	,@sortOrder						nVARCHAR(100) = NULL
	,@pageNumber                    bigint = NULL
	,@pageSize                      bigint = NULL 
AS
BEGIN
        SET NOCOUNT ON

		 SET NOCOUNT ON

        IF EXISTS(SELECT 1 FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@dept_id, @line_id, @pu_id))
        BEGIN
            SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@dept_id, @line_id, @pu_id)
            RETURN
        END

		SET @isIncremental = ISNULL(@isIncremental, 0)       
		DECLARE @ConvertedST DateTime = CASE WHEN @starttime IS NULL 
									THEN DATEADD(DAY, -15, GETDATE())
									ELSE dbo.fnServer_CmnConvertToDbTime(@starttime, 'UTC') END
		DECLARE @ConvertedET datetime = CASE WHEN @endtime IS NULL 
									THEN GETDATE() 
									ELSE dbo.fnServer_CmnConvertToDbTime(@endtime, 'UTC') END

		DECLARE @DbTZ nVARCHAR(255) = (SELECT value FROM site_parameters WHERE parm_id = 192)

		SET @PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
		SET @PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 10 ELSE @PageSize END
		
		DECLARE @ParameterDefinitionList NVARCHAR(MAX) = 
			' @dept_id                      int = NULL
			,@line_id                       int = NULL
			,@pu_id                         int = NULL
			,@name							nVARCHAR(255) = NULL
			,@product						nVARCHAR(255) = NULL
			,@asset							nVARCHAR(255) = NULL
			,@quantity						nVARCHAR(255) = NULL
			,@status						nVARCHAR(255) = NULL
			,@bom							nVARCHAR(255) = NULL
			,@ConvertedST                   datetime = NULL
			,@ConvertedET                   datetime = NULL
			,@isIncremental                 int = NULL
			,@sortCol						nVARCHAR(100) = NULL
			,@sortOrder						nVARCHAR(100) = NULL '

		DECLARE @SQLStatement NVARCHAR(MAX) = ' SELECT golden_batch_id = GB.golden_batch_id 
			,Department = D.Dept_Id
            ,Department_Description = D.Dept_Desc
            ,Line = L.PL_Id
            ,Line_Description = L.PL_Desc
            ,Unit = U.PU_Id
            ,Unit_Description = U.PU_Desc
            ,Production_Type = U.Production_Type
            ,Production_Variable = U.Production_variable
            ,Product = GB.Prod_Id
            ,Product_Description = CASE WHEN E.Applied_Product IS NULL THEN P.Prod_Desc ELSE ''**'' + P.Prod_Desc + ''**'' END
            ,[Event] = GB.Event_Id
            ,Event_Num = E.Event_Num
            ,Event_Start_Time = E.Start_Time
			,Event_End_Time = E.Timestamp           
            ,BOM = E.BOM_Formulation_Id
            ,Production_Status = PS.ProdStatus_Id
            ,Production_Status_Description = PS.ProdStatus_Desc
            ,Quantity = ED.Final_Dimension_X
			,UOM = ES.dimension_X_Eng_Units	
			,Applied_Product = E.Applied_Product '

		SET @SQLStatement = @SQLStatement + ' FROM 
			dbo.Departments_Base            D  WITH(NOLOCK)
			JOIN dbo.Prod_Lines_Base        L  WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
			JOIN dbo.Prod_Units_Base        U  WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
			JOIN dbo.Events                 E  WITH(NOLOCK)  ON U.PU_Id = E.PU_Id 
			JOIN dbo.golden_batches         GB WITH(NOLOCK)  ON GB.event_id = E.Event_Id
			JOIN dbo.Production_Status      PS WITH(NOLOCK)  ON E.Event_Status = PS.ProdStatus_Id
			JOIN dbo.products				P  WITH(NOLOCK)  ON GB.Prod_Id= P.Prod_Id
			JOIN Event_Configuration        EC WITH(NOLOCK)  ON E.PU_Id = EC.PU_Id AND EC.event_subtype_id IS NOT NULL
			JOIN Event_Subtypes				ES WITH(NOLOCK)  ON EC.ET_Id = ES.event_subtype_id
			LEFT JOIN dbo.Event_Details     ED WITH(NOLOCK)  ON E.Event_Id = ED.Event_Id WHERE (1=1) '

		IF @dept_id IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND D.Dept_Id = @dept_id '
		IF @line_id IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND L.PL_Id = @line_id '
		IF @pu_id IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND U.PU_Id = @pu_id '
		IF @name IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND E.Event_Num LIKE ''%'' + @name + ''%'' '
		IF @product IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND P.Prod_Desc = @product '
		IF @asset IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND U.PU_Desc LIKE ''%'' + @asset + ''%'' '
		IF @quantity IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND ED.Final_Dimension_X LIKE ''%'' + @quantity + ''%'' '
		IF @status IS NOT NULL
			SET @SQLStatement = @SQLStatement + ' AND PS.ProdStatus_Desc = @status '
		IF @bom IS NOT NULL 
			SET @SQLStatement = @SQLStatement + ' AND E.BOM_Formulation_Id LIKE ''%'' + @bom + ''%'' '

		SET @SQLStatement = @SQLStatement + ' AND (E.TimeStamp BETWEEN @ConvertedST AND @ConvertedET
												OR @ConvertedST BETWEEN E.Start_Time AND E.TimeStamp
												OR @ConvertedET BETWEEN E.Start_Time AND E.TimeStamp) '

		SET @SQLStatement = @SQLStatement + ' ORDER BY ' + CASE WHEN @sortCol = 'Name' THEN ' Event_Num '
			WHEN @sortCol = 'Product' THEN ' Product_Description '
			WHEN @sortCol = 'Asset' THEN ' Unit_Description '
			WHEN @sortCol = 'Start' THEN ' Event_Start_Time '
			WHEN @sortCol = 'End' THEN ' Event_END_Time '
			WHEN @sortCol = 'Quantity' THEN ' Quantity '
			WHEN @sortCol = 'Status' THEN ' Production_Status_Description '
			WHEN @sortCol = 'BoM' THEN ' BoM '
			ELSE ' Unit, Event_End_Time ' END
		+ ISNULL(' ' + @sortOrder, ' DESC ')
			
		DECLARE @tempEvents TABLE (
			golden_batch_id int
			,Department int
			,Department_Description nVARCHAR(255)
			,Line int
			,Line_Description nVARCHAR(255)
			,Unit int
			,Unit_Description nVARCHAR(255)
			,Production_Type tinyint
			,Production_Variable int
			,Product int
			,Product_Description nVARCHAR(255)
			,[Event] int
			,Event_Num nVARCHAR(255)
			,Event_Start_Time datetime
			,Event_End_Time datetime
			,BOM int
			,Production_Status int
			,Production_Status_Description nVARCHAR(100)
			,Quantity float
			,UOM nVARCHAR(50)
			,Applied_Product int
		)

		DECLARE @cloneTempEvents TABLE (
			Id int identity
			,golden_batch_id int
			,Department int
			,Department_Description nVARCHAR(255)
			,Line int
			,Line_Description nVARCHAR(255)
			,Unit int
			,Unit_Description nVARCHAR(255)
			,Production_Type tinyint
			,Production_Variable int
			,Product int
			,Product_Description nVARCHAR(255)
			,[Event] int
			,Event_Num nVARCHAR(255)
			,Event_Start_Time datetime
			,Event_End_Time datetime
			,BOM int
			,Production_Status int
			,Production_Status_Description nVARCHAR(100)
			,Quantity float
			,UOM nVARCHAR(50)
			,Applied_Product int
		)

		--======================================================================
		-- dynamic query execution (starts)
		--====================================================================== 
     	INSERT INTO @tempEvents
		EXECUTE SP_EXECUTESQL @SQLStatement, @ParameterDefinitionList, 		 
			@dept_id                        
			,@line_id                        
			,@pu_id                          
			,@name							
			,@product						
			,@asset							
			,@quantity						
			,@status							
			,@bom							
			,@ConvertedST                      
			,@ConvertedET                        
			,@isIncremental                  
			,@sortCol						
			,@sortOrder
		--======================================================================
		-- Synamic query execution (end)
		--======================================================================	

		IF NOT EXISTS(SELECT 1 FROM @tempEvents)
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		--======================================================================
		-- To support filter on quantity (starts)
		--======================================================================
		DECLARE @EventsQuantity TABLE ([Event] int, Quantity float)
		INSERT INTO @EventsQuantity
			SELECT 
				[Event]
				,Quantity = (SELECT ISNULL(SUM(CONVERT(FLOAT, T.Result)), 0) FROM dbo.Tests T WITH (NOLOCK)
						WHERE T.Var_Id = Production_Variable
						AND T.Result_On >= Event_Start_Time
						AND T.Result_On <= Event_End_Time)
			FROM 
				@tempEvents
			WHERE 
				Production_Type = 1

		UPDATE TE SET TE.Quantity = Q.Quantity
		FROM @tempEvents TE JOIN @EventsQuantity Q ON TE.[Event] = Q.[Event]

		INSERT INTO @cloneTempEvents
		SELECT golden_batch_id, Department, Department_Description, Line, Line_Description, Unit, Unit_Description, Production_Type, Production_Variable 
			,Product, Product_Description, [Event], Event_Num, Event_Start_Time, Event_End_Time, BOM
			,Production_Status, Production_Status_Description, TE.Quantity, UOM, Applied_Product 
		FROM 
			@tempEvents TE
		WHERE
			ISNULL(TE.Quantity, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@quantity) + '%'

		DECLARE @TotalCount bigint = @@ROWCOUNT
		--======================================================================
		-- To support filter on quantity (end)
		--======================================================================

		--======================================================================
		-- To Select records based on page number and page size (starts)
		--======================================================================
		IF @isIncremental != 0
			DECLARE @InitialST DATETIME = (SELECT MIN(E.Event_Start_Time) FROM @tempevents E)
		
		;WITH TempEvent_CTE AS (
			SELECT 
				SL_No = TE.Id
				,TE.golden_batch_id
				,TE.Department
				,TE.Department_Description
				,TE.Line
				,TE.Line_Description
				,TE.Unit
				,TE.Unit_Description
				,TE.Production_Type
				,TE.Production_Variable
				,TE.Product
				,TE.Product_Description
				,TE.[Event]
				,TE.Event_Num
				,Event_Start_Time = COALESCE(TE.Event_Start_Time, (SELECT LAG(E.Timestamp) OVER (PARTITION BY E.PU_Id ORDER BY E.Timestamp) FROM Events E WHERE E.PU_Id = TE.Unit AND E.Event_Id = TE.[Event]), @ConvertedST)
				,Event_End_Time = Event_End_Time
				,TE.BOM
				,TE.Production_Status
				,TE.Production_Status_Description
				,Quantity = TE.Quantity
				,TE.UOM
			FROM
				@cloneTempEvents TE
			WHERE 
				Id BETWEEN((@PageNumber) - 1) * @PageSize + 1 AND @PageNumber * @PageSize
		) SELECT
			SL_No
			,golden_batch_id
			,Department
			,Department_Description
			,Line
			,Line_Description
			,Unit
			,Unit_Description
			,Production_Type
			,Production_Variable
			,Product
			,Product_Description
			,[Event]
			,Event_Num
			,Event_Start_Time = CASE WHEN @isIncremental = 0 
									THEN dbo.fnServer_CmnConvertTime(Event_Start_Time, @DbTZ,'UTC') 
									ELSE dbo.fnServer_CmnConvertTime(@InitialST, @DbTZ,'UTC') END
			,Event_End_Time = dbo.fnServer_CmnConvertTime(Event_End_Time, @DbTZ,'UTC')
			,EventUTCTimeStamp = dbo.fnServer_CmnConvertTime(Event_End_Time, @DbTZ,'UTC')
			,BOM
			,Production_Start_id = NULL			--
			,Production_Start_Time = GETDATE()  -- These columns are only to make service and UI in sync with Batch 
			,Production_End_Time = GETDATE()    -- and are removed here to optimize qery 
			,ProdUTCTimeStamp = GETDATE()		--
			,Production_Status
			,Production_Status_Description
			,Quantity
			,UOM
			,NbResults = @TotalCount
			,CurrentPage = @pageNumber 
			,PageSize = @pageSize 
			,TotalPages = FLOOR(CEILING(Cast(@TotalCount as decimal(18,2))/ @PageSize)) 
		FROM TempEvent_CTE
		--======================================================================
		-- To Select records based on page number and page size (end)
		--======================================================================

		--======================================================================
		-- Distict selection, for the dropdown in UI filter (start)
		--======================================================================
		SELECT DISTINCT 
			id = CASE WHEN @dept_id IS NULL THEN Department 
							WHEN @line_id IS NULL THEN Line
							ELSE Unit END	
			,name = CASE WHEN @dept_id IS NULL THEN Department_Description 
							WHEN @line_id IS NULL THEN Line_Description
							ELSE Unit_Description END
			,AssetType = CASE WHEN @dept_id IS NULL THEN 'Department' 
							WHEN @line_id IS NULL THEN 'Line'
						ELSE 'Unit' END
		FROM 
			@cloneTempEvents

		SELECT DISTINCT 
			id = Production_Status
			,name = Production_Status_Description		
		FROM 
			@cloneTempEvents
		WHERE Production_Status IS NOT NULL

		SELECT DISTINCT 
			id = Product
			,name = Product_Description		
		FROM 
			@cloneTempEvents
		WHERE 
			Product IS NOT NULL AND Applied_Product IS NULL
		--======================================================================
		-- Distict selection, for the dropdown in UI filter (end)
		--======================================================================
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetGoldenBatchesBasedonCriteria] TO [ComXClient]
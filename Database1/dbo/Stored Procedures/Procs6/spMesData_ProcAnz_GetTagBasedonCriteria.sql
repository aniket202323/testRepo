
/*
	Copyright (c) 2017 GE Digital. All Rights Reserved.
	=============================================================================

	=============================================================================
	Author				212517152, Rabindra Kumar
	Create On			12-December-2016
	Last Modified		26-June-2018
	Description			Returns tag list respective ot historian.
	Procedure_name		[spMesData_ProcAnz_GetTagBasedonCriteria]

	================================================================================
	Input Parameter:
	=================================================================================
	@department_id					--int--				Optional input paramater
	@line_id                        --int--				Optional input paramater
	@unit_id                        --int--				Optional input paramater
	@vargrp_id						--int--				Optional input paramater
	@name							--nVARCHAR(255)--	mandatory input paramater (will be a list of tags from service, separated by comma)
	@description					--nVARCHAR(255)--	Optional input paramater
	@asset							--nVARCHAR(255)--	Optional input paramater
	@data_type						--nVARCHAR(255)--	Optional input paramater
	@sample_type					--nVARCHAR(255)--	Optional input paramater
	@interval						--nVARCHAR(255)--	Optional input paramater
	@variables                      --nVARCHAR(255)--	Optional input paramater
	@historianAlias					--nVARCHAR(255)--	mandatory input paramater
	@sortCol						--nVARCHAR(100)--	Optional input paramater
	@sortOrder						--nvarchar(100 )--	Optional input paramater
	@pageNumber                     --bigint--			Optional input paramater
	@pageSize                       --bigint--			Optional input paramater

	================================================================================
	Result Set: - 1
	=================================================================================
	--Department
	--Department_Description
	--Line
	--Line_Description
	--Unit
	--Unit_Description
	--Tag_Name
	--Tag_Description
	--Data_Type_Id
	--Data_Type_Desc
	--Sampling_Type_Id
	--Sampling_Type_Description
	--Interval
	--Variables 
	--TagCount
	--NbResults
	--CurrentPage
	--PageSize
	--TotalPages

	================================================================================
	Result Set: - 2 [Distinct Plant Model [Asset] based on input parameter]
	=================================================================================
	--Id
	--Name
	--AssetType

	================================================================================
	Result Set: - 3 [Distinct Data_Type based on input parameter. Now not in used but exists to keep service in sync]
	=================================================================================
	--Id
	--Name

	================================================================================
	Result Set: - 4 [Distinct Sampling_Type based on input parameter. Now not in used but exists to keep service in sync]
	=================================================================================
	--Id
	--Name

	================================================================================
	Result Set: - 5 [Distinct Variables count based on input parameter. It counts based on same Input_tag associated with variables]
	=================================================================================
	--Id
	--Name
*/

CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetTagBasedonCriteria] 
		@department_id          int = NULL
		,@line_id               int = NULL
		,@unit_id               int = NULL
		,@vargrp_id				int = NULL
		,@name                  nvarchar(MAX) = NULL
		,@description           nVARCHAR(255) = NULL
		,@asset                 nVARCHAR(255) = NULL
		,@data_type             nVARCHAR(255) = NULL
		,@sample_type           nVARCHAR(255) = NULL
		,@interval				nVARCHAR(255) = NULL
		,@variables             nVARCHAR(255) = NULL
		,@historianAlias        nVARCHAR(255) = NULL
		,@sortCol				nVARCHAR(100) = NULL
		,@sortOrder				nVARCHAR(100) = NULL
		,@pageNumber			bigint = NULL
		,@pageSize				bigint = NULL

AS 
BEGIN

	   	SET NOCOUNT ON

		IF EXISTS(select 1 from dbo.fnMesData_ProcAnz_PlantModelValidation(@department_id, @line_id, @unit_id))
		BEGIN
			SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@department_id, @line_id, @unit_id)
		RETURN
		END

		DECLARE @TotalCount INT, @aliasCharacter nVARCHAR(255), @isDefaultHistorian bit, @xml XML
		Declare @Sqlstr nVarchar(max)
		--SET @xml = CAST(('<X>'+REPLACE(@name,',','</X><X>')+'</X>') as xml)

		Create Table #tempTags    (
			Id Int Identity(1,1)
			,Department int
			,Department_Description nVARCHAR(255)
			,Line int
			,Line_Description nVARCHAR(255)
			,Unit int
			,Unit_Description nVARCHAR(255)
			,Tag_Name nVARCHAR(255)
			,Tag_Description nVARCHAR(255)
			,Data_Type_Id int
            ,Data_Type_Desc nVARCHAR(255)
			,Sampling_Type_Id int
			,Sampling_Type_Description nVARCHAR(255)
			,Interval int
			,Variables int
			,TagCount int
			,Total int
		)

		create table  #histTags  (
			ID int Identity(1,1),
			Historian_Tag_Name nVARCHAR(255)
		)

		INSERT INTO #histTags(Historian_Tag_Name)
		--SELECT N.value('.', 'nVARCHAR(100)') FROM @xml.nodes('X') AS T(N)
		Select Col1 from dbo.fn_SplitString(@name,',')
		SET @PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
		SET @PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 10 ELSE @PageSize END

		SELECT @isDefaultHistorian = Hist_Default FROM Historians WHERE Alias = @historianAlias
		IF(@isDefaultHistorian = 0)
			SET @aliasCharacter = '\\' + @historianAlias + '\'
		ELSE
			SET @aliasCharacter = ''
	

SET
@Sqlstr = '
;WITH CTE AS( 
SELECT 
Department = D.Dept_Id
,Department_Description = D.Dept_Desc
,Line = L.PL_Id
,Line_Description = L.PL_Desc
,Unit = U.PU_Id
,Unit_Description = U.pu_desc
,Tag_Name = REPLACE(V.Input_Tag, '''+@aliasCharacter+''', '''')				
,Tag_Description = V.Input_Tag 
,Data_Type_Id = NULL 
,Data_Type_Desc = NULL
,Sampling_Type_Id = NULL
,Sampling_Type_Description = NULL
,Interval = NULL
,Variables = COUNT(*) OVER(PARTITION BY V.Input_tag)
,TagCount = ROW_NUMBER() OVER(PARTITION BY V.Input_tag ORDER BY V.Input_tag ASC)
,Tag_name1 = 
REPLACE(REPLACE(REPLACE(REPLACE(IsNULL(REPLACE(V.Input_Tag, '''+@aliasCharacter+''', ''''),''''), ''['', ''[[]''), ''_'', ''[_]''), ''%'', ''[%]''), ''*'', ''[*]'')
FROM
	Departments_Base D WITH (NOLOCK)
'
SET @Sqlstr = @Sqlstr + ' 
JOIN Prod_Lines_Base L WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id' 
IF @line_id IS NOT NULL 
	SET @Sqlstr = @Sqlstr + ' AND L.PL_Id = '+cast(@line_id as nvarchar)

SET @Sqlstr = @Sqlstr + ' 
JOIN prod_units U WITH(NOLOCK)  ON L.PL_Id = U.PL_Id' 
IF @unit_id IS NOT NULL 
	SET @Sqlstr = @Sqlstr + ' AND U.PU_Id = '+cast(@unit_id as nvarchar)
IF @asset IS NOT NULL
	SET @Sqlstr = @Sqlstr + ' ISNULL(U.PU_Desc, '''') LIKE ''%'''+REPLACE(REPLACE(REPLACE(REPLACE(IsNULL(@asset,''), '[', '[[]'), '_', '[_]'), '%', '[%]'), '*', '[*]')+'''%'''


SET @Sqlstr = @Sqlstr + ' 
JOIN pu_groups G WITH(NOLOCK)  ON U.PU_Id = G.PU_Id' 
IF @vargrp_id IS NOT NULL 
	SET @Sqlstr = @Sqlstr + ' AND G.PUG_Id = '+cast(@vargrp_id as nvarchar)

SET @Sqlstr = @Sqlstr + ' 
JOIN Variables_Base V WITH(NOLOCK)  ON G.PUG_Id = V.PUG_Id AND V.Input_Tag IS NOT NULL AND V.Input_Tag NOT LIKE ' 
IF @isDefaultHistorian = 1
	SET @Sqlstr = @Sqlstr + '''\\%'''
Else
	SET @Sqlstr = @Sqlstr + ''''''

IF @department_id IS NOT NULL
	SET @Sqlstr = @Sqlstr + ' WHERE D.Dept_Id = '+cast(@department_id as nvarchar)
	
SET @Sqlstr = @Sqlstr + ')
INSERT INTO #tempTags(Department,Department_Description,Line,Line_Description,Unit,Unit_Description,Tag_Name,Tag_Description,Data_Type_Id,Data_Type_Desc,Sampling_Type_Id,Sampling_Type_Description,Interval,Variables,TagCount,Total)
SELECT CTE.Department,CTE.Department_Description,CTE.Line,CTE.Line_Description,CTE.Unit,CTE.Unit_Description,CTE.Tag_Name,CTE.Tag_Description,CTE.Data_Type_Id,CTE.Data_Type_Desc,CTE.Sampling_Type_Id,CTE.Sampling_Type_Description,CTE.Interval,CTE.Variables,CTE.TagCount,COUNT(0) OVER() FROM CTE
INNER JOIN #histTags HT ON CTE.Tag_Name = HT.Historian_Tag_Name
WHERE 
			Tag_Description LIKE CASE '+cast(@isDefaultHistorian as nvarchar)+' WHEN 1 THEN Tag_Description ELSE '''+@aliasCharacter+''' + ''%'' +
			Tag_name1
			END
			AND TagCount = 1
'
IF @variables IS NOT NULL
SET @Sqlstr = @Sqlstr + ' AND Variables = '+cast(@variables as nvarchar)



IF @sortCol IN ('DataType','SampleType','Interval')
	SET @Sqlstr = @Sqlstr + ' ORDER By HT.ID'
ELSE 
	SET @Sqlstr = @Sqlstr + ' ORDER By 1'

--SET @Sqlstr = @Sqlstr +' OFFSET '+Cast(@pageSize as nVarchar)+' * ('+cast((@PageNumber -1 )as nvarchar)+' ) ROWS FETCH NEXT '+cast(@pageSize as nvarchar)+' ROWS ONLY;'
 
EXEC( @SqlStr)


		IF NOT EXISTS(SELECT 1 FROM #tempTags)
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
		SELECT @TotalCount = Total FROM #tempTags
		--======================================================================
		-- To Select records based on page number and page size (starts)
		--======================================================================
		SELECT 
			TT.*
			,NbResults = @TotalCount
			,CurrentPage = @pageNumber 
			,PageSize = @pageSize 
			,TotalPages = FLOOR(CEILING(Cast(@TotalCount as decimal(18,2))/ @PageSize))
		FROM 
			#tempTags TT
		ORDER BY 
			-- for Name 
			CASE WHEN @sortCol='Name' AND @sortOrder = 'ASC' THEN Tag_Name END ASC,
			CASE WHEN @sortCol='Name' AND @sortOrder = 'DESC' THEN Tag_Name END DESC,
			-- for Description 
			CASE WHEN @sortCol='Description' AND @sortOrder = 'ASC' THEN Tag_Description END ASC,
			CASE WHEN @sortCol='Description' AND @sortOrder = 'DESC' THEN Tag_Description END DESC,
			-- for Asset 
			CASE WHEN @sortCol='Asset' AND @sortOrder = 'ASC' THEN Unit_Description END ASC,
			CASE WHEN @sortCol='Asset' AND @sortOrder = 'DESC' THEN Unit_Description END DESC,
			-- for Variables 
			CASE WHEN @sortCol='Variables' AND @sortOrder = 'ASC' THEN Variables END ASC,
			CASE WHEN @sortCol='Variables' AND @sortOrder = 'DESC' THEN Variables END DESC
				
		OFFSET ((@pageNumber - 1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY
		--======================================================================
		-- To Select records based on page number and page size (end)
		--======================================================================
		--======================================================================
		-- Distict selection, for the dropdown in UI filter (start)
		--======================================================================
		SELECT DISTINCT 
			id = CASE WHEN @department_id IS NULL THEN Department 
							WHEN @line_id IS NULL THEN Line
							ELSE Unit END 
			,name = CASE WHEN @department_id IS NULL THEN Department_Description 
							WHEN @line_id IS NULL THEN Line_Description
							ELSE Unit_Description END
			,AssetType = CASE WHEN @department_id IS NULL THEN 'Department' 
							WHEN @line_id IS NULL THEN 'Line'
							ELSE 'Unit' END
		FROM 
			#tempTags
				
		SELECT DISTINCT 
			id = Data_Type_Id 
			,name = Data_Type_Desc		
		FROM #tempTags
		WHERE 
			Data_Type_Desc IS NOT NULL
		SELECT DISTINCT 
			id = Sampling_Type_Id
			,name = Sampling_Type_Description		
		FROM #tempTags
		WHERE 
			Sampling_Type_Description IS NOT NULL
		SELECT DISTINCT 
			id = Variables
			,name = Variables		
		FROM 
			#tempTags
		WHERE Variables IS NOT NULL
		--======================================================================
		-- Distict selection, for the dropdown in UI filter (start)
		--======================================================================
END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetTagBasedonCriteria] TO [ComXClient]

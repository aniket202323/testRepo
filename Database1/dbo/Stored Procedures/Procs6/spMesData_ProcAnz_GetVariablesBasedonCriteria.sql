


CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetVariablesBasedonCriteria] 
       @department_id                    int = NULL
       ,@line_id                         int = NULL
       ,@unit_id                         int = NULL
       ,@vargrp_id                       int = NULL
       ,@name                            nvarchar(255) = NULL
       ,@source                          nvarchar(255) = NULL
       ,@asset                           nvarchar(255) = NULL
       ,@type                            nvarchar(255) = NULL
       ,@sample                          nvarchar(255) = NULL
       ,@interval                        nvarchar(255) = NULL
       ,@tagIn                           nvarchar(255) = NULL
       ,@tagOut                          nvarchar(255) = NULL
	   ,@sortCol                         nvarchar(255) = NULL
       ,@sortOrder                       nvarchar(255) = NULL
       ,@pageNumber						 bigint = NULL
       ,@pageSize						 bigint = NULL

AS 
BEGIN
       
		SET NOCOUNT ON

		IF EXISTS(select 1 from dbo.fnMesData_ProcAnz_PlantModelValidation(@department_id, @line_id, @unit_id))
		BEGIN
			SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@department_id, @line_id, @unit_id)
		RETURN
		END

		DECLARE @SQLStatement nvarchar(MAX), @ParameterDefinitionList nvarchar(MAX)

		SET @ParameterDefinitionList = 
			' @department_id                 int
			,@line_id                       int
			,@unit_id                       int 
			,@vargrp_id                     int 
			,@name                          nvarchar(255)
			,@source						nvarchar(255)
			,@asset                         nvarchar(255)
			,@type                          nvarchar(255)
			,@sample                        nvarchar(255)
			,@interval                      nvarchar(255)
			,@tagIn                         nvarchar(255)
			,@tagOut                        nvarchar(255)
			,@sortCol                       nvarchar(255)
			,@sortOrder                     nvarchar(255)
			,@pageNumber					bigint
			,@pageSize						bigint '

		SET @SQLStatement = ' SELECT 
				D.Dept_Id
				,D.Dept_Desc
				,L.PL_Id
				,L.PL_Desc
				,U.PU_Id
				,U.pu_desc
				,G.PUG_Id
				,G.pug_desc
				,V.var_id
				,V.Var_Desc
				,V.Input_tag
				,V.Output_Tag
				,V.Eng_Units
				,V.Sampling_Interval
				,DT.Data_Type_Id
				,DT.Data_Type_Desc
				,DS.DS_Id
				,DS.DS_Desc
				,ST.ST_Id
				,ST.ST_Desc '

		SET @SQLStatement = @SQLStatement + ' FROM 
            Departments_Base                D WITH(NOLOCK)
            JOIN Prod_Lines_Base			L WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
            JOIN Prod_Units_Base            U WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
            JOIN pu_groups                  G WITH(NOLOCK)  ON U.PU_Id = G.PU_Id
            JOIN Variables_Base             V WITH(NOLOCK)  ON G.PUG_Id = V.PUG_Id
            JOIN Data_Type                  DT WITH(NOLOCK) ON V.Data_Type_Id = DT.Data_Type_Id 
			JOIN Data_Source				DS WITH(NOLOCK) ON V.DS_Id = DS.DS_Id
            LEFT JOIN Sampling_Type         ST WITH(NOLOCK) ON V.Sampling_Type = ST.ST_Id WHERE (1=1) '

			IF @department_id IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND D.Dept_Id = @department_id '
			IF @line_id IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND L.PL_Id = @line_id '
			IF @unit_id IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND U.PU_Id = @unit_id '
			IF @vargrp_id IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND G.PUG_Id = @vargrp_id '
			IF @source IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND DS.DS_Desc = @source '
			IF @type IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND DT.Data_Type_Desc = @type '
			IF @interval IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND V.Sampling_Interval = @interval '
			IF @sample IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND ST.ST_Desc = @sample '
			IF @name IS NOT NULL 
				SET @SQLStatement = @SQLStatement + ' AND V.Var_Desc LIKE ''%'' + @name + ''%'' {escape ''\''} '
			IF @asset IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND U.PU_Desc LIKE ''%'' + @asset + ''%'' '
			IF @tagIn IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND V.Input_tag LIKE ''%'' + @tagIn + ''%'' {escape ''\''}'
			IF @tagOut IS NOT NULL
				SET @SQLStatement = @SQLStatement + ' AND V.Output_Tag LIKE ''%'' + @tagOut + ''%'' {escape ''\''}'


			SET @SQLStatement = ';WITH CTE AS ('+@SQLStatement+' ),CTE1 As (Select Count(0) Total from CTE) Select *,(SELECT Total From CTE1) From CTE '

			SET @SQLStatement = @SQLStatement + ' ORDER BY ' + CASE WHEN @sortCol = 'Source' THEN ' DS_Desc '
													  WHEN @sortCol = 'Asset' THEN ' pu_desc '
													  WHEN @sortCol = 'Type' THEN ' Data_Type_Desc '
													  WHEN @sortCol = 'Sample' THEN ' ST_Desc '
													  WHEN @sortCol = 'Interval' THEN ' Sampling_Interval '
													  WHEN @sortCol = 'TagIn' THEN ' Input_tag '
													  WHEN @sortCol = 'TagsOut' THEN ' Output_Tag '
													  ELSE ' Var_Desc ' END
												+ ISNULL(' ' + @sortOrder, ' ASC ')
			SET @SQLStatement = @SQLStatement + '
							OFFSET '+CAST(@PageSize as nvarchar)+' * ('+CAST(@pageNumber as nvarchar)+' - 1) ROWS
							FETCH NEXT '+CAST(@PageSize as nvarchar)+' ROWS ONLY OPTION (RECOMPILE);'

		--SET @PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
		--SET @PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 10 ELSE @PageSize END
		DECLARE @tempVariables TABLE (
			Id Int Identity(1,1)
			,Department int
			,Department_Description nvarchar(255)
			,Line int
			,Line_Description nvarchar(255)
			,Unit int
			,Unit_Description nvarchar(255)
			,[Group] int
			,Group_Description nvarchar(255)
			,Variable int
			,Variable_Description nvarchar(255)
			,Input_tag nvarchar(255)
			,Output_Tag nvarchar(255)
            ,Eng_Units nvarchar(255)
            ,Sampling_Interval smallint
			,Data_Type_Id int
            ,Data_Type_Desc nvarchar(255)
            ,Data_Source_Id int
            ,Data_Source_Description nvarchar(255)
			,Sampling_Type_Id int
			,Sampling_Type_Description nvarchar(255)
			,Total Int
		)
		
		INSERT INTO @tempVariables
		EXECUTE SP_EXECUTESQL @SQLStatement, @ParameterDefinitionList, 		 
			@department_id
			,@line_id     
			,@unit_id     
			,@vargrp_id                 
			,@name                      
			,@source                   
			,@asset                         
			,@type                          
			,@sample                        
			,@interval                      
			,@tagIn                         
			,@tagOut                        
			,@sortCol                       
			,@sortOrder                     
			,@pageNumber						
			,@pageSize

		DECLARE @TotalCount INT 
		
		SELECT top 1  @TotalCount = Total From @tempVariables	

		IF NOT EXISTS(SELECT 1 FROM @tempVariables  )
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
			   
		SELECT 
			Sl_No = Id 
			,Department 
			,Department_Description 
			,Line 
			,Line_Description 
			,Unit 
			,Unit_Description 
			,[Group]
			,Group_Description 
			,Variable 
			,Variable_Description 
			,Input_tag 
			,Output_Tag 
			,Eng_Units 
			,Sampling_Interval
			,Data_Type_Id 
			,Data_Type_Desc 
			,Data_Source_Id 
			,Data_Source_Description
			,Sampling_Type_Id 
			,Sampling_Type_Description 
			,NbResults = @TotalCount
			,CurrentPage = @pageNumber 
			,PageSize = @pageSize 
			,TotalPages = FLOOR(CEILING(Cast(@TotalCount as decimal(18,2))/ @PageSize)) 
			
		FROM 
			@tempVariables  TV
		--WHERE Id BETWEEN((@PageNumber) - 1) * @PageSize + 1 AND @PageNumber * @PageSize   
			
		 
		sELECT Distinct id = DS_Id, name = DS_desc from Data_Source

		;WITH S AS (
		Select Dept_Id Id, dept_Desc Name from Departments_Base Where @department_id IS NULL
		UNION ALL
		SELECT pl_Id, Pl_Desc from Prod_Lines_Base where Dept_Id = @department_id and @department_id IS NOT NULL
		UNION ALL
		SELECT pu_Id, Pu_Desc From Prod_Units Where Pl_Id = @line_id and @line_id IS NOT NULL
		)
		Select *,CASE WHEN @department_id IS NULL THEN 'Department' WHEN @line_id IS NULL THEN 'Line' ELSE 'Unit' END AssetType  from S

		Select Distinct id = Data_Type_Id,name = Data_Type_Desc from Data_Type

		Select DISTINCT id = ST_Id,name = ST_Desc	 from Sampling_Type

END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetVariablesBasedonCriteria] TO [ComXClient]


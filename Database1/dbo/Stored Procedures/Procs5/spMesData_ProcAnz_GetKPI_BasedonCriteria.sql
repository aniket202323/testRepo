
 CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetKPI_BasedonCriteria] (
	@line			int = NULL
	,@unit			int = NULL
	,@name			nVARCHAR(255) = NULL
	,@interval		nVARCHAR(255) = NULL
	,@asset			nVARCHAR(255) = NULL
	,@line_des		nVARCHAR(255) = NULL
	,@OEE_Type		nVARCHAR(255) = NULL
	,@sortCol		nVARCHAR(100) = NULL
	,@sortOrder		nVARCHAR(100) = NULL
	,@pageNumber	int = NULL
	,@pageSize		int = NULL
)

AS
BEGIN
		SET NOCOUNT ON 

		IF EXISTS(select 1 from dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, @line, @unit))
		BEGIN
			SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, @line, @unit)
			RETURN
		END

		DECLARE @totalCount int, @innerStart int, @innerEnd int, @OuterStart int
		,@Dept int, @department_desc nVARCHAR(255), @line_id int, @line_desc nVARCHAR(255)
		,@unit_id int, @unit_desc nVARCHAR(255), @totalRows int, @LineOEEMode int
		,@OEE_Interval int

		SET @OEE_Interval = (SELECT VALUE FROM Site_Parameters  WHERE Parm_Id = 602)

		/* This table is to store 4 respective values for each line and unit */
		DECLARE @tempKPI TABLE (
			SlNo int identity
			,Department int
			,Department_Description nVARCHAR(255)
			,Line int
			,Line_Description nVARCHAR(255)
			,Unit int
			,Unit_Description nVARCHAR(255)
			,Name nVARCHAR(255) 
			,Interval int
			,OEE_Type nVARCHAR(255)
		)

		/* This table is to achieve pagination based on search criteria */
		DECLARE @tempKPI2 TABLE (
			SlNo int
			,Department int
			,Department_Description nVARCHAR(255)
			,Line int
			,Line_Description nVARCHAR(255)
			,Unit int
			,Unit_Description nVARCHAR(255)
			,Name nVARCHAR(255) 
			,Interval int
			,OEE_Type nVARCHAR(255)
		)

		DECLARE @tempAsset TABLE (
			SlNo int identity
			,AssetId int
			,AssetDesc nVARCHAR(255)
			,AssetType nVARCHAR(255)
		)

		SELECT TOP 1 
			@Dept = D.Dept_Id, @department_desc = D.Dept_Desc, @line_id = L.PL_Id, @line_desc = L.PL_Desc, @LineOEEMode = ISNULL(L.LineOEEMode, 1)
		FROM  
			dbo.Departments_Base            D  WITH(NOLOCK)
			JOIN dbo.Prod_Lines_Base        L  WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
			JOIN dbo.Prod_Units_Base        U  WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
		WHERE 
			D.Dept_Id = D.Dept_Id
			AND L.PL_Id = ISNULL(@line, L.PL_Id)
			AND U.PU_Id = ISNULL(@unit, U.PU_Id)
	
		SET @PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
		SET @PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 10 ELSE @PageSize END

		IF(@unit IS NOT NULL)
		BEGIN
			INSERT INTO @tempAsset
			SELECT PU_Id, PU_Desc, 'Unit' FROM Prod_Units_Base WITH(NOLOCK) WHERE PU_Id = @unit
		END
		ELSE IF(@line IS NOT NULL) 
		BEGIN
			INSERT INTO @tempAsset 
			SELECT PL_Id, PL_Desc, 'Line' FROM dbo.Prod_Lines_Base WITH(NOLOCK) WHERE PL_Id = @line

			INSERT INTO @tempAsset
			SELECT PU_Id, PU_Desc, 'Unit' FROM dbo.Prod_Units_Base  WITH(NOLOCK) WHERE PL_Id = @line
		END

		/* If we have a unit generate only 4 rows for that particular unit */
		/* else generate 4 for line and 4 for each respective units */
		/* Base on the number of rows in @tempAsset generate the 4-dummy row for each */
		SET @totalRows = (SELECT COUNT(*) FROM @tempAsset)
		SET @OuterStart = 0
	
		WHILE(@OuterStart < @totalRows)
		BEGIN 
			SET @OuterStart = @OuterStart + 1
			SET @innerStart = 0
			IF((SELECT AssetType FROM @tempAsset WHERE SlNo = @OuterStart) = 'line')
			BEGIN
				WHILE(@innerStart < 4)
				BEGIN
					SET @innerStart = @innerStart + 1
					INSERT INTO @tempKPI
					SELECT Department = @Dept
						,Department_Description = @department_desc
						,Line = @line_id
						,Line_Description = @line_desc
						,Unit = NULL
						,Unit_Description = NULL
						,Name = CASE WHEN @innerStart = 1 THEN 'OEE'
										WHEN @innerStart = 2 THEN 'Availability'
										WHEN @innerStart = 3 THEN 'Quality'
										WHEN @innerStart = 4 THEN 'Performance' END
						,Interval = @OEE_Interval
						,OEE_Type = CASE WHEN @LineOEEMode IN(1,2,3) THEN 'Parallel '
										 WHEN  @LineOEEMode IN(4, 5) THEN 'Serial' END
									
				END
			END
			ELSE
			BEGIN
				SELECT @unit_id = AssetId, @unit_desc = AssetDesc FROM @tempAsset WHERE SlNo = @OuterStart
				WHILE(@innerStart < 4)
				BEGIN
					SET @innerStart = @innerStart + 1
					INSERT INTO @tempKPI
					SELECT Department = @Dept
						,Department_Description = @department_desc
						,Line = @line_id
						,Line_Description = @line_desc
						,Unit = @unit_id
						,Unit_Description = @unit_desc
						,Name = CASE WHEN @innerStart = 1 THEN 'OEE'
										WHEN @innerStart = 2 THEN 'Availability'
										WHEN @innerStart = 3 THEN 'Quality'
										WHEN @innerStart = 4 THEN 'Performance' END
						,Interval = @OEE_Interval
						,OEE_Type = NULL
				END
			END
		END

		INSERT INTO @tempKPI2
		SELECT 
			T.*
		FROM 
			@tempKPI T
		WHERE 
		T.Interval = ISNULL(@interval, T.Interval)
		AND ISNULL(T.Name, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@name) + '%'
		--AND ISNULL(T.Interval, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@interval) + '%'
		AND ISNULL(T.Unit_Description, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@asset) + '%'
		AND ISNULL(T.Line_Description, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@line_des) + '%'
		AND ISNULL(T.OEE_Type, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@OEE_Type) + '%'
		
		SET @totalCount = (SELECT COUNT(*) FROM @tempKPI2)

		IF(@totalCount = 0)
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		SELECT 
			T.*
			,NbResults = @TotalCount
			,CurrentPage = @pageNumber 
			,PageSize = @pageSize 
			,TotalPages = FLOOR(CEILING(Cast(@TotalCount as decimal(18,2))/ @PageSize)) 
		FROM 
			@tempKPI2 T
		ORDER BY 
					-- for Name 
				CASE WHEN @sortCol='Name'  AND @sortOrder = 'ASC' THEN Name END ASC,
				CASE WHEN @sortCol='Name'  AND @sortOrder = 'DESC' THEN Name END DESC,
			   -- for Interval 
				CASE WHEN @sortCol='Interval'  AND @sortOrder = 'ASC' THEN Interval END ASC,
				CASE WHEN @sortCol='Interval'  AND @sortOrder = 'DESC' THEN Interval END DESC,
				 -- for Asset 
				CASE WHEN @sortCol='Asset'  AND @sortOrder = 'ASC' THEN Unit_Description END ASC,
				CASE WHEN @sortCol='Asset'  AND @sortOrder = 'DESC' THEN Unit_Description END DESC,
				 -- for Start
				CASE WHEN @sortCol='OEEtype'  AND @sortOrder = 'ASC' THEN OEE_Type END ASC,
				CASE WHEN @sortCol='OEEtype'  AND @sortOrder = 'DESC' THEN OEE_Type END DESC
			
			OFFSET @pageSize * (@PageNumber - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;

			SELECT DISTINCT 
				id = CASE WHEN @line_id IS NULL THEN Line
						  ELSE Unit END	
				,name = CASE WHEN @line_id IS NULL THEN Line_Description
						 ELSE Unit_Description END
				,AssetType = CASE WHEN @line_id IS NULL THEN 'Line'
							ELSE 'Unit' END
			FROM 
				@tempKPI
			WHERE Unit IS NOT NULL

			SELECT DISTINCT 
				id = Interval
				,name = Interval		
			FROM 
				@tempKPI
			WHERE 
				Interval IS NOT NULL 

END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetKPI_BasedonCriteria] TO [ComXClient]
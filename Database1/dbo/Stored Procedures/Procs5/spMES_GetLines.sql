

CREATE PROCEDURE dbo.spMES_GetLines
	@LineId						INT,					-- Get a specific line
	@DepartmentId				INT,					-- Get all lines for a specific department
	@DepartmentList				nvarchar(max),			-- Get all lines for list of departments
	@ExtendedInfoFilterType		INT = NULL,				-- Controls how ExtendedInfo is used to filter results
	@ExtendedInfoValue			nvarchar(255) = NULL,	-- Filter value
	@IsRouteEnabledLineFilter	INT = 0,				-- Filter by IsRouteEnabledLine
	@PageNumber					INT = 1,
	@PageSize					INT = 20
AS

DECLARE @ProdLinesTableId int = 18 -- See Tables table

DECLARE @Lines Table (
	RowNumber Int IDENTITY(1,1),
	LineId Int, LineName nvarchar(100), DepartmentId Int,	DepartmentName nvarchar(100),
	ExtendedInfo nvarchar(255), IsRouteEnabledLine bit)

DECLARE @Departments Table (RowNumber Int IDENTITY(1,1), DepartmentId Int)

if (@DepartmentList IS NOT NULL)
Begin
    INSERT INTO @Departments (DepartmentId)
		SELECT Id FROM dbo.fnCMN_IdListToTable('Departments', @DepartmentList, ',')
End

-- Normalize the filter type to 0 - disabled.
SET @ExtendedInfoFilterType = COALESCE(@ExtendedInfoFilterType, 0)
-- Normalize the compare value to empty string (never null)
SET @ExtendedInfoValue = COALESCE(@ExtendedInfoValue, '')

INSERT INTO @Lines(LineId, LineName, DepartmentId, DepartmentName, ExtendedInfo, IsRouteEnabledLine)
	SELECT	line.PL_Id,
			line.PL_Desc,
			department.Dept_Id,
			department.Dept_Desc,
			line.Extended_Info,
			CAST(CASE WHEN tfv.Value is null THEN 0 ELSE tfv.Value END AS BIT)
	FROM	Departments_Base department
	JOIN	Prod_Lines_Base line ON line.Dept_Id = department.Dept_Id
	left join dbo.Table_Fields tf on tf.TableId = @ProdLinesTableId and tf.Table_Field_Desc = 'IsRouteEnabled'
	left join dbo.Table_Fields_Values tfv on tfv.TableId = tf.TableId and tfv.Table_Field_Id = tf.Table_Field_Id and tfv.KeyId = line.PL_Id
	WHERE	((@LineId is NULL AND @DepartmentId IS NULL AND @DepartmentList IS NULL)
		OR	(@LineId is NULL AND @DepartmentId IS NULL AND @DepartmentList IS NOT NULL AND department.Dept_Id in (Select DepartmentId from @Departments))
		OR	(@LineId is NULL AND department.Dept_Id = @DepartmentId)
		OR	(@LineId = line.PL_Id))
		AND	(@ExtendedInfoFilterType = 0
		 OR (@ExtendedInfoFilterType = 1 AND COALESCE(line.Extended_Info,'') = @ExtendedInfoValue)
		 OR (@ExtendedInfoFilterType = 2 AND COALESCE(line.Extended_Info,'') <> @ExtendedInfoValue))
		AND (@IsRouteEnabledLineFilter = 0
		 OR (@IsRouteEnabledLineFilter = 1 AND tfv.Value = 1)
		 OR (@IsRouteEnabledLineFilter = 2 AND (tfv.Value is null or tfv.Value = 0)))
	ORDER BY department.Dept_Id,line.PL_Id

-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

-- Return the selected page of results.
SELECT RowNumber, LineId, LineName, DepartmentId, DepartmentName, ExtendedInfo, IsRouteEnabledLine
FROM @Lines
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

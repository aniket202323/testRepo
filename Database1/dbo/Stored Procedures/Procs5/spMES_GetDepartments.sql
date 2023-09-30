

CREATE PROCEDURE dbo.spMES_GetDepartments
	@DepartmentId				INT,					-- Get a specific department
	@ExtendedInfoFilterType		INT = NULL,				-- Controls how ExtendedInfo is used to filter results
	@ExtendedInfoValue			NVARCHAR(255) = NULL,	-- Filter value
	@PageNumber					INT = 1,
	@PageSize					INT = 20
AS

DECLARE @Departments Table (
	RowNumber Int IDENTITY(1,1),
	DepartmentId Int,	DepartmentName nvarchar(100), ExtendedInfo nvarchar(255)
)

-- Normalize the filter type to 0 - disabled.
SET @ExtendedInfoFilterType = COALESCE(@ExtendedInfoFilterType, 0)
-- Normalize the compare value to empty string (never null)
SET @ExtendedInfoValue = COALESCE(@ExtendedInfoValue, '')

INSERT INTO @Departments(DepartmentId, DepartmentName, ExtendedInfo)
	SELECT	department.Dept_Id,
			department.Dept_Desc,
			department.Extended_Info
	FROM	Departments_Base department
	WHERE	(@DepartmentId is NULL OR @DepartmentId = department.Dept_Id)
		AND (@ExtendedInfoFilterType = 0
		 OR (@ExtendedInfoFilterType = 1 AND COALESCE(department.Extended_Info,'') = @ExtendedInfoValue)
		 OR (@ExtendedInfoFilterType = 2 AND COALESCE(department.Extended_Info,'') <> @ExtendedInfoValue))
	ORDER BY department.Dept_Id

-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

-- Return the selected page of results.
SELECT RowNumber, DepartmentId, DepartmentName, ExtendedInfo
FROM @Departments
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

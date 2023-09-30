

CREATE PROCEDURE dbo.spMES_GetUnitGroups
	@GroupId					INT,					-- Get a specific group
	@UnitId						INT,					-- Get all groups for a specific unit
	@UnitList					nvarchar(max),			-- Get all groups for list of units
	@PageNumber					INT = 1,
	@PageSize					INT = 20
AS

DECLARE @Groups Table (
	RowNumber Int IDENTITY(1,1),
	GroupId Int, GroupName nvarchar(100), UnitId Int, UnitName nvarchar(100))

DECLARE @Units Table (RowNumber Int IDENTITY(1,1), UnitId Int)

if (@UnitList IS NOT NULL)
Begin
    INSERT INTO @Units (UnitId)
		SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units', @UnitList, ',')
End

INSERT INTO @Groups(GroupId, GroupName, UnitId, UnitName)
	SELECT	unitgroup.PUG_Id,
			unitgroup.PUG_Desc,
			unit.PU_Id,
			unit.PU_Desc
	FROM	Prod_Units_Base unit
	JOIN	PU_Groups unitgroup ON unitgroup.PU_Id = unit.PU_Id
	WHERE	((@GroupId is NULL AND @UnitId IS NULL AND @UnitList IS NULL)
		OR	(@GroupId is NULL AND @UnitId IS NULL AND @UnitList IS NOT NULL AND unit.PU_Id in (Select UnitId from @Units))
		OR	(@GroupId is NULL AND unit.PU_Id = @UnitId)
		OR	(@GroupId = unitgroup.PUG_Id))
	ORDER BY unit.PU_Id,unitgroup.PUG_Id

-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

-- Return the selected page of results.
SELECT RowNumber, GroupId, GroupName, UnitId, UnitName
FROM @Groups
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

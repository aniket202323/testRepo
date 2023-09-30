

CREATE PROCEDURE dbo.spMES_GetAssetChildren
	@ParentId		INT,		-- Get all asset of type parented by this ID. Requires AssetId is NULL
	@AssetId		INT,		-- Get a specific asset with children
	@AssetType		INT,		-- Asset type to return.
	@ExtendedInfoFilterType	INT = NULL,	   -- Controls how ExtendedInfo is used to filter results
	@ExtendedInfoValue NVARCHAR(255) = NULL, -- Filter value
	@PageNumber		INT = 1,
	@PageSize		INT = 20
AS

DECLARE @Assets Table (
	RowNumber Int IDENTITY(1,1),
	ParentAssetType Int, ParentAssetName nvarchar(100), ParentAssetId Int,
	AssetType Int, AssetName nvarchar(100), AssetId Int,
	ExtendedInfo nvarchar(255)
)

-- Normalize the filter type to 0 - disabled.
SET @ExtendedInfoFilterType = COALESCE(@ExtendedInfoFilterType, 0)
-- Normalize the compare value to empty string (never null)
SET @ExtendedInfoValue = COALESCE(@ExtendedInfoValue, '')

IF @AssetType = 1 -- Department
BEGIN
	-- Get the top level in first.
	-- A department does not have a parent so leave those nulls.
	INSERT INTO @Assets(AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT AssetType = @AssetType,
			AssetName = department.Dept_Desc,
			AssetId = department.Dept_Id,
			ExtendedInfo = department.Extended_Info
		FROM Departments_Base department
		WHERE (@AssetId is NULL
					 OR @AssetId = department.Dept_Id)
			AND (@ExtendedInfoFilterType = 0
					OR (@ExtendedInfoFilterType = 1 AND
              COALESCE(department.Extended_Info,'') = @ExtendedInfoValue)
					OR (@ExtendedInfoFilterType = 2 AND
							COALESCE(department.Extended_Info,'') <> @ExtendedInfoValue))
		ORDER BY department.Dept_Id

	-- Get the line children of the department
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType,
			ParentAssetName = asset.AssetName,
			ParentAssetId = asset.AssetId,
			AssetType = @AssetType + 1,
			AssetName = child.PL_Desc,
			AssetId = child.PL_Id,
			ExtendedInfo = child.Extended_Info
		FROM @Assets asset
		JOIN Prod_Lines_Base child
		ON child.Dept_Id = asset.AssetId
		ORDER BY asset.RowNumber,child.PL_Id
END

IF @AssetType = 2 -- Line
BEGIN
	-- Get the top level lines in first.
	-- Department is the parent of line
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType - 1,
			ParentAssetName = department.Dept_Desc,
			ParentAssetId = department.Dept_Id,
			AssetType = @AssetType,
			AssetName = line.PL_Desc,
			AssetId = line.PL_Id,
			ExtendedInfo = line.Extended_Info
		FROM Departments_Base department
		JOIN Prod_Lines_Base line
		ON line.Dept_Id = department.Dept_Id
		WHERE ((@AssetId is NULL AND @ParentId IS NULL)
			OR (@AssetId is NULL AND department.Dept_Id = @ParentId)
			OR (@AssetId = line.PL_Id))
		  AND (@ExtendedInfoFilterType = 0
        OR (@ExtendedInfoFilterType = 1 AND
            COALESCE(line.Extended_Info,'') = @ExtendedInfoValue)
        OR (@ExtendedInfoFilterType = 2 AND
            COALESCE(line.Extended_Info,'') <> @ExtendedInfoValue))
		ORDER BY department.Dept_Id,line.PL_Id

	-- For each line, add the child units
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType,
			ParentAssetName = asset.AssetName,
			ParentAssetId = asset.AssetId,
			AssetType = @AssetType + 1,
			AssetName = child.PU_Desc,
			AssetId = child.PU_Id,
			ExtendedInfo = child.Extended_Info
		FROM @Assets asset
		JOIN Prod_Units_Base child
		ON child.PL_Id = asset.AssetId
		-- Units have an order that should be respected when set.
		ORDER BY asset.RowNumber,child.PU_Order,child.PU_Id
END

IF @AssetType = 3 -- Unit
BEGIN
	-- Get the top level units in first.
	-- Line is the parent of unit
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType - 1,
			ParentAssetName = line.PL_Desc,
			ParentAssetId = line.PL_Id,
			AssetType = @AssetType,
			AssetName = unit.PU_Desc,
			AssetId = unit.PU_Id,
			ExtendedInfo = unit.Extended_Info
		FROM Prod_Lines_Base line
		JOIN Prod_Units unit
		ON unit.PL_Id = line.PL_Id
		WHERE ((@AssetId is NULL AND @ParentId IS NULL)
			OR (@AssetId is NULL AND line.PL_Id = @ParentId)
			OR (@AssetId = unit.PU_Id))
		  AND (@ExtendedInfoFilterType = 0
        OR (@ExtendedInfoFilterType = 1 AND
            COALESCE(unit.Extended_Info,'') = @ExtendedInfoValue)
        OR (@ExtendedInfoFilterType = 2 AND
            COALESCE(unit.Extended_Info,'') <> @ExtendedInfoValue))
		-- Units have an order that should be respected when set.
		ORDER BY line.PL_Id,unit.PU_Order,unit.PU_Id

	-- For each unit, add the child groups
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType,
			ParentAssetName = asset.AssetName,
			ParentAssetId = asset.AssetId,
			AssetType = @AssetType + 1,
			AssetName = child.PUG_Desc,
			AssetId = child.PUG_Id,
			ExtendedInfo = NULL
		FROM @Assets asset
		JOIN PU_Groups child
		ON child.PU_Id = asset.AssetId
		ORDER BY asset.RowNumber,child.PUG_Id
END

IF @AssetType = 4 -- Unit Group
BEGIN
	-- Get the top level unit groups in first.
	-- Unit is the parent of Unit Group
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType - 1,
			ParentAssetName = unit.PU_Desc,
			ParentAssetId = unit.PU_Id,
			AssetType = @AssetType,
			AssetName = unitgroup.PUG_Desc,
			AssetId = unitgroup.PUG_Id,
			ExtendedInfo = NULL
		FROM Prod_Units unit
		JOIN PU_Groups unitgroup
		ON unitgroup.PU_Id = unit.PU_Id
		WHERE ((@AssetId is NULL AND @ParentId IS NULL)
			OR (@AssetId is NULL AND unit.PU_Id = @ParentId)
			OR (@AssetId = unitgroup.PUG_Id))
		ORDER BY unit.PU_Id,unitgroup.PUG_Id

	-- For each unit group, add the child variables
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType,
			ParentAssetName = asset.AssetName,
			ParentAssetId = asset.AssetId,
			AssetType = @AssetType + 1,
			AssetName = child.Var_Desc,
			AssetId = child.Var_Id,
			ExtendedInfo = child.Extended_Info
		FROM @Assets asset
		JOIN Variables child
		ON child.PUG_Id = asset.AssetId
		ORDER BY asset.RowNumber,child.Var_Id
END

IF @AssetType = 5 -- Variables
BEGIN
	-- Get the top level variables in first.
	-- Unit Group is the parent of Variable
	INSERT INTO @Assets(ParentAssetType,ParentAssetName,ParentAssetId,AssetType,AssetName,AssetId,ExtendedInfo)
		SELECT ParentAssetType = @AssetType - 1,
			ParentAssetName = unitgroup.PUG_Desc,
			ParentAssetId = unitgroup.PUG_Id,
			AssetType = @AssetType,
			AssetName = variable.Var_Desc,
			AssetId = variable.Var_Id,
			ExtendedInfo = variable.Extended_Info
		FROM PU_Groups unitgroup
		JOIN Variables_Base variable
		ON variable.PUG_Id = unitgroup.PUG_Id
		WHERE ((@AssetId is NULL AND @ParentId IS NULL)
			OR (@AssetId is NULL AND unitgroup.PUG_Id = @ParentId)
			OR (@AssetId = variable.Var_Id))
		  AND (@ExtendedInfoFilterType = 0
        OR (@ExtendedInfoFilterType = 1 AND
            COALESCE(variable.Extended_Info,'') = @ExtendedInfoValue)
        OR (@ExtendedInfoFilterType = 2 AND
            COALESCE(variable.Extended_Info,'') <> @ExtendedInfoValue))
		ORDER BY unitgroup.PUG_Id,variable.Var_Id
END


-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

-- Return the selected page of results.
SELECT *
FROM @Assets
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

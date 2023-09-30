

CREATE PROCEDURE dbo.spMES_GetUnits
	@UnitId						INT,					-- Get a specific unit
	@LineId						INT,					-- Get all units for a specific line
	@LineList					nvarchar(max),			-- Get all units for list of lines
	@ExtendedInfoFilterType		INT = NULL,				-- Controls how ExtendedInfo is used to filter results
	@ExtendedInfoValue			nvarchar(255) = NULL,	-- Filter value
	@InventoryFilterType		INT = 0,				-- Controls how InventoryUnit is used to filter results 
	@PageNumber					INT = 1,
	@PageSize					INT = 20
AS

DECLARE @Units Table (
	RowNumber Int IDENTITY(1,1),
	UnitId Int, UnitName nvarchar(100), LineId Int, LineName nvarchar(100),
	ExtendedInfo nvarchar(255), IsInventoryUnit bit)

DECLARE @Lines Table (RowNumber Int IDENTITY(1,1), LineId Int)

if (@LineList IS NOT NULL)
Begin
    INSERT INTO @Lines (LineId)
		SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines', @LineList, ',')
End

-- Normalize the filter type to 0 - disabled.
SET @ExtendedInfoFilterType = COALESCE(@ExtendedInfoFilterType, 0)
-- Normalize the compare value to empty string (never null)
SET @ExtendedInfoValue = COALESCE(@ExtendedInfoValue, '')
-- Normalize the filter type to 0 (never null)
SET @InventoryFilterType = COALESCE(@InventoryFilterType, 0)

INSERT INTO @Units(UnitId, UnitName, LineId, LineName, ExtendedInfo, IsInventoryUnit)
	SELECT	unit.PU_Id,
			unit.PU_Desc,
			line.PL_Id,
			line.PL_Desc,
			unit.Extended_Info,
			CAST(CASE WHEN unit.unit_type_id=3 THEN 1 ELSE 0 END AS BIT)
	FROM	Prod_Lines_Base line
	JOIN	Prod_Units_Base unit ON unit.PL_Id = line.PL_Id
	WHERE	((@UnitId is NULL AND @LineId IS NULL AND @LineList IS NULL)
		OR	(@UnitId is NULL AND @LineId IS NULL AND @LineList IS NOT NULL AND line.PL_Id in (Select LineId from @Lines))
		OR	(@UnitId is NULL AND line.PL_Id = @LineId)
		OR	(@UnitId = unit.PU_Id))
		AND	(@ExtendedInfoFilterType = 0
		 OR (@ExtendedInfoFilterType = 1 AND COALESCE(unit.Extended_Info,'') = @ExtendedInfoValue)
		 OR (@ExtendedInfoFilterType = 2 AND COALESCE(unit.Extended_Info,'') <> @ExtendedInfoValue))
		AND (@InventoryFilterType = 0 
		 OR (@InventoryFilterType = 1 AND unit.unit_type_id = 3) 
		 OR (@InventoryFilterType = 2 AND unit.unit_type_id != 3))    
	-- Units have an order that should be respected when set.
	ORDER BY line.PL_Id,unit.PU_Order,unit.PU_Id

-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

-- Return the selected page of results.
SELECT RowNumber, UnitId, UnitName, LineId, LineName, ExtendedInfo, IsInventoryUnit
FROM @Units
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

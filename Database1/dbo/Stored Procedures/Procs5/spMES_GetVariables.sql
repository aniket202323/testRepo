

CREATE PROCEDURE dbo.spMES_GetVariables
	@VariableId					INT,					-- Get a specific variable
	@GroupId					INT,					-- Get all variables for a specific group
	@GroupList					nvarchar(max),			-- Get all variables for list of groups
	@ExtendedInfoFilterType		INT = NULL,				-- Controls how ExtendedInfo is used to filter results
	@ExtendedInfoValue			nvarchar(255) = NULL,	-- Filter value
	@PageNumber					INT = 1,
	@PageSize					INT = 20
AS

DECLARE @Variables Table (
	RowNumber Int IDENTITY(1,1),
	VariableId Int, VariableName nvarchar(100), GroupId Int, GroupName nvarchar(100), ExtendedInfo nvarchar(255),
	InputDataSourceSystemType nvarchar(100), InputDataSourceSystemName nvarchar(100), InputDataSourceNodeId nvarchar(255))

DECLARE @Groups Table (RowNumber Int IDENTITY(1,1), GroupId Int)

if (@GroupList IS NOT NULL)
Begin
    INSERT INTO @Groups (GroupId)
		SELECT Id FROM dbo.fnCMN_IdListToTable('PU_Groups', @GroupList, ',')
End

-- Normalize the filter type to 0 - disabled.
SET @ExtendedInfoFilterType = COALESCE(@ExtendedInfoFilterType, 0)
-- Normalize the compare value to empty string (never null)
SET @ExtendedInfoValue = COALESCE(@ExtendedInfoValue, '')

DECLARE @DefaultHistorian nvarchar(100)
SELECT @DefaultHistorian = hist.Alias From Historians hist WHERE hist.Hist_Default = 1
INSERT INTO @Variables(VariableId, VariableName, GroupId, GroupName, ExtendedInfo, InputDataSourceNodeId)
	SELECT	variable.Var_Id,
			variable.Var_Desc,
			unitgroup.PUG_Id,
			unitgroup.PUG_Desc,
			variable.Extended_Info,
			dbo.fnEM_ConvertVarIdToTag(variable.input_tag)
	FROM	PU_Groups unitgroup
	JOIN	Variables_Base variable	ON variable.PUG_Id = unitgroup.PUG_Id
	WHERE	((@VariableId is NULL AND @GroupId IS NULL AND @GroupList IS NULL)
		OR	(@VariableId is NULL AND @GroupId IS NULL AND @GroupList IS NOT NULL AND unitgroup.PUG_Id in (Select GroupId from @Groups))
		OR	(@VariableId is NULL AND unitgroup.PUG_Id = @GroupId)
		OR	(@VariableId = variable.Var_Id))
		AND	(@ExtendedInfoFilterType = 0
		 OR (@ExtendedInfoFilterType = 1 AND COALESCE(variable.Extended_Info,'') = @ExtendedInfoValue)
		 OR (@ExtendedInfoFilterType = 2 AND COALESCE(variable.Extended_Info,'') <> @ExtendedInfoValue))
	ORDER BY unitgroup.PUG_Id,variable.Var_Id

UPDATE @Variables SET
	InputDataSourceSystemName =  case
		WHEN (CharIndex('\\',InputDataSourceNodeId) = 0)
			THEN @DefaultHistorian
	    WHEN (CharIndex('\\',InputDataSourceNodeId) = 1)
			THEN SubString(InputDataSourceNodeId,3,CharIndex('\',SubString(InputDataSourceNodeId,3,1000)) - 1)
		END

UPDATE @Variables SET
	InputDataSourceSystemName = hist.Hist_Servername,
	InputDataSourceSystemType = histType.Hist_Type_Desc
FROM @Variables varDetails
JOIN Historians hist
ON hist.Alias = varDetails.InputDataSourceSystemName
JOIN Historian_Types histType
ON histType.Hist_Type_Id = hist.Hist_Type_Id

UPDATE @Variables
SET InputDataSourceNodeId = RIGHT(InputDataSourceNodeId, LEN(InputDataSourceNodeId) - CHARINDEX('\', InputDataSourceNodeId, 3))

-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

-- Return the selected page of results.
SELECT RowNumber, VariableId, VariableName, GroupId, GroupName, ExtendedInfo, InputDataSourceSystemType,
       InputDataSourceSystemName, InputDataSourceNodeId
FROM @Variables
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

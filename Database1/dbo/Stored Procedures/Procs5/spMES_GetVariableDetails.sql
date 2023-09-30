

CREATE PROCEDURE dbo.spMES_GetVariableDetails 
	@GroupId		INT,	-- Group to return variables details for. Requires VariableId is NULL
	@VariableId		INT		-- Get a specific variable
AS

DECLARE @Variables Table (GroupName  nvarchar(100),GroupId Int,VariableName nvarchar(100), VariableId Int,
	InputDataSourceSystemType nvarchar(100), InputDataSourceSystemName nvarchar(100), InputDataSourceNodeId nvarchar(255))

DECLARE @DefaultHistorian nvarchar(100)
SELECT @DefaultHistorian = hist.Alias From Historians hist WHERE hist.Hist_Default = 1
INSERT INTO @Variables(GroupName,GroupId,VariableName,VariableId,InputDataSourceNodeId)
	SELECT	GroupName 			= pug.PUG_Desc, 
			GroupId				= pug.PUG_Id,
			VariableName 		= v.Var_Desc, 
			VariableId			= v.Var_Id,
			InputDataSourceNodeId = dbo.fnEM_ConvertVarIdToTag(v.input_tag)
	FROM PU_Groups pug
	JOIN Variables_Base v
	ON	v.PUG_Id = pug.PUG_Id	
		AND	(v.System Is Null Or v.System = 0) 
		AND v.DS_Id = 3 
		AND v.PUG_iD > 0
		AND v.Input_Tag Is not Null 
	WHERE (@VariableId is NULL AND @GroupId IS NULL)
		OR (@VariableId is NULL AND pug.PUG_Id = @GroupId)
		OR (@VariableId = v.Var_Id)

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

select * from @Variables

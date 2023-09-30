-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- Return the version for the specified datamodel from the DataModelInfo table.
-- Returns 0 if version does not exist.

 --DROP FUNCTION [dbo].[ReadDataModel] 
 --GO

 CREATE FUNCTION [dbo].[ufn_GetDataModelVersion] (
	@DataModelName  NVARCHAR(255)     -- the name of the data model to read
)
RETURNS INT
BEGIN
	DECLARE @dataModelVersion bigint

	SELECT @dataModelVersion = [Version]
	FROM [dbo].DataModelInfo
	WHERE DataModel = @DataModelName
		
	RETURN COALESCE(@dataModelVersion,-1)

END
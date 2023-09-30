-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- Return the version for the specified schema from the SchemaVersion table.
-- Returns -1 if version does not exist.

 --DROP FUNCTION [PR_Version].[ReadVersion] 
 --GO

 CREATE FUNCTION [PR_Version].[ufn_GetSchemaVersion] (
	@SchemaName  NVARCHAR(50)     -- the name of the schema to update/create
)
RETURNS INT
BEGIN
	DECLARE @schemaVersion INT
	
	SELECT @schemaVersion = [SchemaVersion]
	FROM [PR_Version].SchemaVersion
	WHERE SchemaName = @SchemaName

	RETURN COALESCE(@schemaVersion,-1)

END
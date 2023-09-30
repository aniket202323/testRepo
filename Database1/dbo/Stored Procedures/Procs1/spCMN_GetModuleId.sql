CREATE PROCEDURE [dbo].[spCMN_GetModuleId]
  @AppId INT
AS
Raiserror('Internal Error: spCMN_GetModuleId Was Called, But Is Obsolete', 16, 1)
return
/*
DECLARE @ModuleId INT
SELECT @ModuleId = Module_Id
FROM AppVersions a
WHERE a.App_Id = @AppId
PRINT @ModuleId
IF @ModuleId IS NULL
  RETURN -1
ELSE
  RETURN @ModuleId
*/

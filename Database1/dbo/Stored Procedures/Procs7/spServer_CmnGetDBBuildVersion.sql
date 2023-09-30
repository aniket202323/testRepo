CREATE PROCEDURE dbo.spServer_CmnGetDBBuildVersion
@Version nvarchar(50) OUTPUT
 AS
Select @Version=App_Version From AppVersions where App_Id = 2 
If @Version Is Null
  Select @Version = ''

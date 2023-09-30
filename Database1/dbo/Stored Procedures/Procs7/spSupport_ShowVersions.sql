CREATE PROCEDURE dbo.spSupport_ShowVersions
AS
  Select App_Id,Modified_On,App_Version,App_Name From AppVersions Order By App_Id

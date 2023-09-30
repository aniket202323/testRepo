CREATE PROCEDURE dbo.spEM_GetLicenseInformation
 AS
Select  app_Id,App_Name,App_ValidationKey
 	  From AppVersions where app_Id not in (0,1,12)

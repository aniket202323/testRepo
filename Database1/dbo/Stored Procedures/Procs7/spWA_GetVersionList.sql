create procedure [dbo].[spWA_GetVersionList]
  @Database nvarchar(10) OUTPUT,
  @WebServer nvarchar(10) OUTPUT
AS
SELECT @Database = App_Version
FROM Appversions
WHERE App_Id = 34
SELECT @WebServer = App_Version
FROM AppVersions
WHERE App_Id = 11

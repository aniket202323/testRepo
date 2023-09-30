
CREATE PROCEDURE [dbo].[splocal_AppVersionUpdater]
		@SP_Name varchar(100),
		@Version varchar(100)
AS

DECLARE @AppId INT

SELECT @AppId = MAX(App_Id) + 1 
		FROM dbo.AppVersions WITH(NOLOCK)                            
--=====================================================================================================================
--	Update table AppVersions
--=====================================================================================================================
IF (SELECT COUNT(*) 
		FROM dbo.AppVersions  WITH(NOLOCK)
		WHERE app_name like '%' + @SP_Name) > 0
BEGIN 
	If (SELECT COUNT(*)
		from dbo.appversions with(NOLOCK)
		where app_name = @SP_Name) > 0
		DELETE from AppVersions where App_Name like 'Release-%' + @SP_Name
	UPDATE dbo.AppVersions
		SET app_name = 'Release- ' + @Version + ' - ' + @SP_Name,   --app_version = app_version,
   	    Modified_on = GETDATE ( )  
		WHERE app_name like '%' + @SP_Name 
END
ELSE
BEGIN
	INSERT INTO dbo.AppVersions (
		App_Id,
		App_name,
		App_version)
	VALUES (
		@AppId, 
		'Release- ' + @Version + ' - ' + @SP_Name,
		@Version)
END

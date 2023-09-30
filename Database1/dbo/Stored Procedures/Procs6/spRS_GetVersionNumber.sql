CREATE PROCEDURE [dbo].[spRS_GetVersionNumber] 
AS
Declare @DataBase varchar(20)
Declare @WebServer varchar(20)
Select @Database = App_Version From AppVersions Where App_id = 2
Select @WebServer = App_Version From AppVersions Where App_id = 11
Select @Database 'Proficy', @WebServer 'WebServer'

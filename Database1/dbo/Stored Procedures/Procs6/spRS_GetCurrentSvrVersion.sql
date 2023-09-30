CREATE PROCEDURE [dbo].[spRS_GetCurrentSvrVersion]
@App_Id int = Null
AS
IF @App_Id IS Null
 	 SELECT  	 App_Id, App_Name, App_Version 
 	 FROM  	 AppVersions
ELSE
 	 SELECT  	 App_Id, App_Name, App_Version 
 	 FROM  	 AppVersions
 	 WHERE  	 App_Id = @App_Id

-------------------------------------------------------------------------------------------------  
----------------------------------------[Creation Of SP]-----------------------------------------  
CREATE PROCEDURE [dbo].[spLocal_Register_SP_Version]  
/*  
-------------------------------------------------------------------------------------------------------  
Altered by  : Normand Carbonneau, Solutions et Technologies Industrielles inc.  
Date   : 2006-03-23  
Version  : 1.2.1  
Purpose  : Added Modified_On field to the INSERT clause.  
-------------------------------------------------------------------------------------------------------  
Altered by  : Normand Carbonneau, Solutions et Technologies Industrielles inc.  
Date   : 2005-11-22  
Version  : 1.2.0  
Purpose  : Added @ReturnValue parameter to return an error message if the App_Id is  
     already used to register another stored procedure.  
-------------------------------------------------------------------------------------------------------  
Altered by  : Normand Carbonneau, Solutions et Technologies Industrielles inc.  
Date   : 2005-10-26  
Version  : 1.1.0  
Purpose  : Added update of Modified_On field on updates.  
     Added [dbo] template when referencing objects.  
-------------------------------------------------------------------------------------------------------  
Created by  : Normand Carbonneau, Solutions et Technologies Industrielles inc.  
Date   : 2005-09-22  
Version  : 1.0.0  
Purpose  : Register the version of a Stored Procedure in the AppVersions table  
-------------------------------------------------------------------------------------------------------  
*/  
@App_Id     int,  
@App_Name   varchar(100),  
@App_Version  varchar(25),  
@Min_Prompt   int,  
@Max_Prompt   int  
AS  
SET NOCOUNT ON  
Declare  
@ExistingAppName varchar(100)  
SET @ExistingAppName = (SELECT [APP_Name] FROM dbo.AppVersions WHERE App_id = @App_Id)  
IF (@ExistingAppName IS NOT NULL) AND (@ExistingAppName <> @App_Name)  
 BEGIN  
  PRINT 'Error registering ' +  @App_Name + ' : App_Id ' + convert(varchar,@App_Id) + ' already used by : ' + @ExistingAppName  
  RETURN  
 END  
IF NOT @ExistingAppName IS NULL  
 UPDATE [dbo].[AppVersions]  
 SET  Modified_On = getdate(),  
    App_Version = @App_Version,  
    [App_Name] = @App_Name,  
    Min_prompt = @Min_Prompt,  
    Max_Prompt = @Max_Prompt  
 WHERE  App_Id = @App_Id  
ELSE  
 INSERT INTO [dbo].[AppVersions]  
    (App_Id, App_Version, [App_Name], Min_Prompt, Max_Prompt, Modified_On)  
 VALUES (@App_Id, @App_Version, @App_Name, @Min_Prompt, @Max_Prompt, getdate())  
SET NOCOUNT OFF  

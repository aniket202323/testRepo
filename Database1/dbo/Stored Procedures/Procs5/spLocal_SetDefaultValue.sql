 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetDefaultValue  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
Returns the passed default value for the passed variable.  Allows you to specify a default value on a manual entry autolog variable.  
If you do it on the variable directly, then you have to apply security at the variable level to get around the presence of a calculation  
so this procedure bypasses that and makes it easier to manage security.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
CREATE procedure dbo.spLocal_SetDefaultValue  
@Output_Value  varchar(25) OUTPUT,  
@Var_Id  int,  
@TimeStamp datetime,  
@Value  varchar(25)  
As  
SET NOCOUNT ON  
  
Declare @Current_Value varchar(25),  
   @User_id   int,  
   @AppVersion   varchar(30)  
   
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
Select @Current_Value = Null  
  
Select @Current_Value = Result  
From [dbo].tests  
Where Var_Id = @Var_Id And Result_On = @TimeStamp  
  
If @Current_Value Is Null  
 BEGIN  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    Select 2, Var_Id, PU_Id, @User_id, 0, @Value, @TimeStamp, 1, 0,  
       NULL,NULL,NULL,NULL,NULL  
        From [dbo].Variables  
        Where Var_Id = @Var_Id  
   END  
  ELSE  
   BEGIN  
        Select 2, Var_Id, PU_Id, @User_id, 0, @Value, @TimeStamp, 1, 0  
        From [dbo].Variables  
        Where Var_Id = @Var_Id  
   END  
 END  
  
Select @Output_Value = @Value  
  
SET NOCOUNT OFF  
  

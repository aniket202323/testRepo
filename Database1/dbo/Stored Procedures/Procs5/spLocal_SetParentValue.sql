     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetParentValue  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
CREATE PROCEDURE dbo.spLocal_SetParentValue  
@OutputValue varchar(25) OUTPUT,  
@Event_Id int,  
@Result varchar(50),  
@Position_Result varchar(50),  
@Parent_Var_Id1 int,  
@Parent_Var_Id2 int,  
@Parent_Var_Id3 int,  
@Parent_Var_Id4 int,  
@Parent_Var_Id5 int,  
@Parent_Var_Id6 int,  
@Parent_Var_Id7 int,  
@Parent_Var_Id8 int  
AS  
SET NOCOUNT ON  
Declare @Source_Event_Id int,  
 @TimeStamp  datetime,  
 @Position  int,  
 @User_id   int,  
 @StrSQL   varchar(8000),  
 @AppVersion  varchar(30)  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
/*  
Insert Into Local_TestSetParentValue (Event_Id, Result, Position_Result, Parent_Var_Id1, Parent_Var_Id2)  
Values (@Event_Id, @Result, @Position_Result, @Parent_Var_Id1, @Parent_Var_Id2)  
*/  
/* Initialization */  
Select @Source_Event_Id = Null  
  
Select @Position = convert(int, @Position_Result)  
Select @Source_Event_Id = Source_Event_Id From [dbo].Event_Components Where Event_Id = @Event_Id  
  
If @Source_Event_Id Is Not Null  
Begin  
     Select @TimeStamp = TimeStamp From [dbo].Events Where Event_Id = @Source_Event_Id  
  
  SELECT @strSQL ='Select 2, Var_Id, PU_Id, ' + convert(varchar(10),@User_id) + ', 0, ''' + @Result + ''', ''' + @TimeStamp + ''', 1, 0'  
    
  IF @AppVersion LIKE '4%'  
   BEGIN  
    SELECT @strSQL = @strsql + ',NULL,NULL,NULL,NULL,NULL'  
   END  
   
     If @Position = 1  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id1)  
     Else If @Position = 2  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id2)  
     Else If @Position = 3  
    SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id3)  
     Else If @Position = 4  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id4)  
     Else If @Position = 5  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id5)  
     Else If @Position = 6  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id6)  
     Else If @Position = 7  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id7)  
     Else If @Position = 8  
          SELECT @strSQL = @strSQL + ' From [dbo].Variables   
          Where Var_Id = ' + convert(varchar(10),@Parent_Var_Id8)  
  
  EXEC (@strSQL)  
End  
  
Select @OutputValue = @Result  
  
SET NOCOUNT OFF  

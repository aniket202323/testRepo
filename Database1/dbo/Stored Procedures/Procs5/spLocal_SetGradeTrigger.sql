 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE procedure dbo.spLocal_SetGradeTrigger  
@Output_Value varchar(25) OUTPUT,  
@Var_Id1  int,  
@Var_Id2 int,  
@Result varchar(25),  
@TimeStamp datetime  
AS  
SET NOCOUNT ON  
DECLARE  
 @AppVersion   varchar(30),  
 @User_id   int  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
  
/* Change time to Product/Time timestamp */  
Select @TimeStamp = DateAdd(ss, -(Datepart(ss, @TimeStamp)+1), @TimeStamp)  
  
  
IF @AppVersion LIKE '4%'  
 BEGIN  
  /* Return variable updates */  
  Select 2, Var_Id, PU_Id, @User_id, 0, @Result, @TimeStamp, 0, 0, NULL,NULL,NULL,NULL,NULL  
  From Variables  
  Where Var_Id = @Var_Id1  
    
  Select 2, Var_Id, PU_Id, @User_id, 0, @Result, @TimeStamp, 0, 0, NULL,NULL,NULL,NULL,NULL  
  From Variables  
  Where Var_Id = @Var_Id2  
 END  
ELSE  
 BEGIN  
  /* Return variable updates */  
  Select 2, Var_Id, PU_Id, @User_id, 0, @Result, @TimeStamp, 0  
  From Variables  
  Where Var_Id = @Var_Id1  
    
  Select 2, Var_Id, PU_Id, @User_id, 0, @Result, @TimeStamp, 0  
  From Variables  
  Where Var_Id = @Var_Id2  
 END  
  
SET NOCOUNT OFF  
  

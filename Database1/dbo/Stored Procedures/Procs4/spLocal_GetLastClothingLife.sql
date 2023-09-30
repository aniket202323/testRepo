   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetLastClothingLife  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
  
CREATE procedure dbo.spLocal_GetLastClothingLife  
@Output_Value varchar(25) OUTPUT,  
@Wire_Id varchar(25),  
@Wire_Var_Id int,  
@Life_Var_Id int,  
@TimeStamp  datetime  
AS  
SET NOCOUNT ON  
  
Declare @Result_On datetime  
  
Select @Result_On = Max(Result_On)  
From [dbo].tests  
Where Var_Id = @Wire_Var_Id And LTrim(RTrim(Result)) = LTrim(RTrim(@Wire_Id)) And Result_On < @TimeStamp  
  
Select @Output_Value = Result  
From [dbo].tests  
Where Var_Id = @Life_Var_Id And Result_On = @Result_On  
  
SET NOCOUNT OFF  
  

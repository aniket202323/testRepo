     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetProfileRange  
Author:   Matthew Wells (MSI)  
Date Created:  11/29/01  
  
Description:  
=========  
Calculates the range for a manual profile.  
  
Change Date Who What  
=========== ==== =====  
11/29/01 MKW Created procedure  
*/  
CREATE Procedure dbo.spLocal_GetProfileRange  
@Output_Value  varchar(25) OUTPUT,  
@Var_Id  int,  
@TimeStamp  datetime  
As  
SET NOCOUNT ON  
/* Testing   
Select  @Var_Id  = 7386,  
 @TimeStamp  = '27-Nov-01 18:36:42',  
 @Element_Str  = '2'  
*/  
  
DECLARE @Profile TABLE(  
 Result   float  
)  
  
/* Initialize */  
Insert Into @Profile (Result)  
Select convert(float, t.Result)  
From [dbo].Calculation_Instance_Dependencies cid  
     Inner Join [dbo].tests t On t.Var_Id = cid.Var_Id   
Where cid.Result_Var_Id = @Var_Id And t.Result_On = @TimeStamp And t.Result Is Not Null  
  
Select @Output_Value = convert(varchar(25), max(Result) - min(Result))  
From @Profile  
  
SET NOCOUNT OFF  
  

   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GetTurnoverValue  
Author:   Matthew Wells (MSI)  
Date Created:  01/28/02  
  
Description:  
=========  
Returns the Turnover Value but if Null, get the next value for itself (b/c all rolls are 1 sec apart).  
  
Change Date Who What  
=========== ==== =====  
01/28/02 MKW Created.  
*/  
  
  
CREATE procedure dbo.spLocal_GetTurnoverValue  
@OutputValue   varchar(25) OUTPUT,  
@Var_Id   int,  
@Value   varchar(30),  
@Next_Value  varchar(30),  
@TimeStamp   varchar(30)  
AS  
  
SET NOCOUNT ON  
  
Declare @Turnover_TimeStamp datetime,  
 @PU_Id  int  
  
If @Value = 'Null'  
     Begin  
     Select @PU_Id = PU_Id  
     From [dbo].Variables  
     Where Var_Id = @Var_Id  
  
     Select @PU_Id = coalesce(Master_Unit, PU_Id)  
     From [dbo].Prod_Units  
     Where PU_Id = @PU_Id  
  
     Select Top 1 @Turnover_TimeStamp = TimeStamp  
     From [dbo].Events  
     Where PU_Id = @PU_Id And TimeStamp >= @TimeStamp  
     Order By TimeStamp Asc  
  
     Select @OutputValue = Result  
     From [dbo].tests  
     Where Var_Id = @Var_Id And Result_On = @Turnover_TimeStamp  
     End  
Else  
     Select @OutputValue = @Value  
  
SET NOCOUNT OFF  
  

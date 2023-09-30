/*  
Stored Procedure: spLocal_GetTurnoverValueByDependent  
Author:   Matthew Wells (MSI)  
Date Created:  03/04/02  
  
Description:  
=========  
Returns the Turnover Value but if Null, get the next value for itself (b/c all rolls are 1 sec apart).  
  
Change Date Who What  
=========== ==== =====  
03/04/02 MKW Created.  
*/  
  
  
CREATE procedure dbo.spLocal_GetTurnoverValueByDependent  
@OutputValue   varchar(25) OUTPUT,  
@Var_Id   int,  
@Value   varchar(30),  
@TimeStamp   varchar(30)  
AS  
  
Declare @Turnover_TimeStamp datetime,  
 @PU_Id  int  
  
If @Value = 'Null'  
     Begin      Select @PU_Id = PU_Id  
     From Variables  
     Where Var_Id = @Var_Id  
  
     Select @PU_Id = coalesce(Master_Unit, PU_Id)  
     From Prod_Units  
     Where PU_Id = @PU_Id  
  
     Select Top 1 @Turnover_TimeStamp = TimeStamp  
     From Events  
     Where PU_Id = @PU_Id And TimeStamp >= @TimeStamp  
     Order By TimeStamp Asc  
  
     Select @OutputValue = Result  
     From tests  
     Where Var_Id = @Var_Id And Result_On = @Turnover_TimeStamp  
     End  
Else  
     Select @OutputValue = @Value

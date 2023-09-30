   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetTurnoverValueByPosition  
Author:   Matthew Wells (MSI)  
Date Created:  01/28/02  
  
Description:  
=========  
Returns the Turnover Value by position but if Null, get the next value for itself (b/c all rolls are 1 sec apart).  
  
Change Date Who What  
=========== ==== =====  
01/28/02 MKW Created.  
*/  
  
  
CREATE procedure dbo.spLocal_GetTurnoverValueByPosition  
@OutputValue  varchar(25) OUTPUT,  
@TimeStamp  varchar(30),  
@Position_Str  varchar(30),  
@Var_Id_A  int,  
@Value_A  varchar(30),  
@Next_Value_A  varchar(30),  
@Var_Id_B  int,  
@Value_B  varchar(30),  
@Next_Value_B  varchar(30),  
@Var_Id_C  int,  
@Value_C  varchar(30),  
@Next_Value_C  varchar(30),  
@Var_Id_D  int,  
@Value_D  varchar(30),  
@Next_Value_D varchar(30),  
@Var_Id_E  int,  
@Value_E  varchar(30),  
@Next_Value_E  varchar(30),  
@Var_Id_F  int,  
@Value_F  varchar(30),  
@Next_Value_F  varchar(30),  
@Var_Id_G  int,  
@Value_G  varchar(30),  
@Next_Value_G varchar(30),  
@Var_Id_H  int,  
@Value_H  varchar(30),  
@Next_Value_H varchar(30)  
AS  
  
SET NOCOUNT ON  
  
Declare @Var_Id  int,  
 @Value   varchar(30),  
 @Next_Value  varchar(30),  
 @Turnover_TimeStamp datetime,  
 @PU_Id  int,  
 @Position  int  
  
If IsNumeric(@Position_Str) = 1  
     Begin  
     Select @Position = convert(int, @Position_Str)  
  
     Select @Var_Id = Case @Position  
   When 1 Then @Var_Id_A  
   When 2 Then @Var_Id_B  
   When 3 Then @Var_Id_C  
   When 4 Then @Var_Id_D  
   When 5 Then @Var_Id_E  
   When 6 Then @Var_Id_F  
   When 7 Then @Var_Id_G  
   When 8 Then @Var_Id_H  
     End  
  
     Select @Value = Case @Position  
   When 1 Then @Value_A  
   When 2 Then @Value_B  
   When 3 Then @Value_C  
   When 4 Then @Value_D  
   When 5 Then @Value_E  
   When 6 Then @Value_F  
   When 7 Then @Value_G  
   When 8 Then @Value_H  
     End  
  
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
     End  
  
SET NOCOUNT OFF  
  

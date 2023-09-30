/*  
Stored Procedure: spLocal_GetLastRollValueByBackstand  
Author:   Matthew Wells (MSI)  
Date Created:  04/08/02  
  
Description:  
=========  
This stored procedure looks up the last or running roll value for a particular timestamp (ie. a stop) and particular backstand.  
  
Change Date Who What  
=========== ==== =====  
04/08/02 MKW Created.  
*/  
  
CREATE PROCEDURE spLocal_GetLastRollValueByBackstand  
@Output_Value  varchar(30) OUTPUT,  
@Stop_TimeStamp  datetime,  
@Roll_PU_Id  int,  
@Backstand_Desc varchar(30),  
@Backstand_Var_Id int,  
@Result_Var_Id  int  
AS  
  
/* Testing   
Select  @Stop_TimeStamp  = getdate(),  
 @Roll_PU_Id  = 97,  
 @Backstand_Desc  = 'Internal',  
 @Backstand_Var_Id = 3789,  
 @Result_Var_Id  = 5066  
*/  
  
Declare @Roll_TimeStamp datetime  
  
Select TOP 1 @Roll_TimeStamp = Result_On  
From tests t  
     Inner Join Events e On t.Result_On = e.TimeStamp And e.PU_Id = @Roll_PU_Id And e.Event_Status <> 3 And e.Event_Status <> 19  
Where Var_Id = @Backstand_Var_Id And Result_On < @Stop_TimeStamp And Result = @Backstand_Desc  
Order By Result_On Desc  
  
Select @Output_Value = convert(varchar(30), Result)  
From tests  
Where Var_Id = @Result_Var_Id And Result_On = @Roll_TimeStamp  
  
  
  

     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_DynamicAverage  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
I think this has been covered in a VBScript calc.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
CREATE procedure dbo.spLocal_DynamicAverage  
@OutputValue varchar(25) OUTPUT,  
@PU_Id int,  
@Var_Id int,  
@Ev_Time varchar(30)  
AS  
  
SET NOCOUNT ON  
  
Declare @spCalc_Id int   
Declare @Result varchar(25)   
Declare @SpDVar_Id int   
Declare @Sum float   
Declare @Divisor int   
Declare @SpDResult float   
Declare @Entry_By int   
  
/*  
select @spCalc_Id = spCalc_Id  
from spCalcs  
where Rslt_var_id = @Var_Id   
  
select @Entry_By = Entry_By from tests where var_id = @Var_Id and result_on = @Ev_Time  
  
create table #SpDVars (  
  SpDVar_Id int NULL,  
  SpDResult float NULL  
)  
  
  
Insert Into #SPDVars(SPDVar_Id)    
    select Var_ID  
    from spcalcs_depends  
    where spCalc_Id = @spCalc_Id  
*/  
  
select @Entry_By = Entry_By from [dbo].tests where var_id = @Var_Id and result_on = @Ev_Time  
  
DECLARE @SpDVars TABLE(  
  SpDVar_Id int NULL,  
  SpDResult float NULL  
)  
  
INSERT into @SPDVars(SPDVar_Id,SpDResult)  
 SELECT CID.var_id, convert(float,t.Result)  
 FROM [dbo].Calculation_Instance_Dependencies CID  
   join [dbo].Tests t ON T.var_id = CID.var_id AND t.result_on = @Ev_Time  
 WHERE CID.Result_Var_Id = @Var_Id  
  
-- Insert Into @SPDVars(SPDVar_Id)    
--     Select Var_ID  
--     from [dbo].Calculation_Instance_Dependencies  
--     where Result_Var_Id = @Var_Id  
--   
-- DECLARE SpDepends_Cursor CURSOR  
--     FOR SELECT SpDVar_Id,SpDResult FROM @SPDVars    For UPDATE  
--     OPEN SpDepends_Cursor  
--     Fetch_Next_SpDedpends:  
--     FETCH NEXT FROM SpDepends_Cursor INTO @SpDVar_Id,@SpDResult   
--     IF @@FETCH_STATUS = 0  
--     BEGIN  
--         Select @Result = result from tests where Var_Id = @SpDVar_Id and Result_On = @Ev_Time  
--  update #SpDVars  
--  set SpDResult = Convert(float,@Result)  
--         WHERE CURRENT OF SpDepends_Cursor  
--         GOTO Fetch_Next_SpDedpends  
--     END  
-- DEALLOCATE SpDepends_Cursor  
  
Select @Sum = sum(SpDResult)  
   From @SPDVars  
  
If (@Sum is NULL or @Sum = 0)  
  Begin  
    If @Entry_By is Null  
      select @OutPutValue = 'DONOTHING'  
    Else  
      select @OutPutValue = ''  
    Return  End  
Select @Divisor = count(SpDResult)  
   From @SPDVars  
   Where SpDResult is not Null  
  
If (@Divisor = 0 or @Divisor is NULL)  
  Begin  
    If @Entry_By is Null  
      select @OutPutValue = 'DONOTHING'  
    Else  
      select @OutPutValue = ''  
    Return    
  End  
Select @OutputValue = convert(varchar(25),(@Sum/@Divisor))  
  
SET NOCOUNT OFF  
  

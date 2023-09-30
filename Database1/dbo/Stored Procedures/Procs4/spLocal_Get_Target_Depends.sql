 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.1  
Purpose  : Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE procedure dbo.spLocal_Get_Target_Depends  
@OutputValue varchar(25) OUTPUT,  
@PU_Id int,  
@Var_Id int,  
@Ev_Time varchar(30)  
AS  
  
SET NOCOUNT ON  
  
Declare @As_Id int  
Declare @Prod_Id int  
Declare @spCalc_Id int  
Declare @spDepndVar_Id int  
  
select @spCalc_Id = spCalc_Id  
from [dbo].spCalcs  
where Rslt_var_id = @Var_Id   
  
  
select @spDepndVar_Id = Var_ID  
    from [dbo].spcalcs_depends  
    where spCalc_Id = @spCalc_Id  
  
select @Prod_Id = Prod_Id  
from [dbo].production_starts  
where pu_id = @pu_id and  
Start_Time <= @Ev_Time and    
            ((End_Time > @Ev_Time) or (End_Time Is Null))       
  
  
select @OutPutValue = Target  
from [dbo].var_specs  
where var_id = @spDepndVar_Id and  
      prod_id = @prod_id and  
      Effective_Date <= @Ev_Time and    
            ((Expiration_Date > @Ev_Time) or (Expiration_Date Is Null))  
  
  
If @OutPutValue = NULL  
Begin  
   Select @OutPutValue = 'DONOTHING'  
End  
  
SET NOCOUNT OFF  
  

﻿  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
  
--This Procedure places values into the Local_RealTimeChemFlow table for reporting on  
--Chemical items.  DO NOT use this routine for Furnish Dry Flow or Stock Flow items.  
--Use spLocal_PutRealTimeDryFlow for Furnish Dry Flow items, and   
--Use spLocal_PutRealTimeStockFlow for Machine Stock Flow items.  
*/  
  
CREATE PROCEDURE spLocal_PutRealTimeChemUsage  
@OutputVal float OUTPUT,  
@Result_On datetime,   -- Use the time of the Flow 1 variable  
@Density float,    -- Use the value of the Density variable  
@Conversion float,   -- Use the default value of 1, leave blank  
@Concentration float,   -- Use the value of the Concentration variable  
@Flow1 float,    -- Use the value of the Flow 1 variable  
@Flow2 float,    -- Use the value of the Flow 2 variable  
@Flow3 float,    -- Use the value of the Flow 3 variable  
@Flow4 float,    -- Use the value of the Flow 4 variable  
@Concentration_Var_Id int,  -- Use the variable Id of the Concentration variable  
@MassFlow_Var_Id int,   -- Use the variable Id of the Mass Flow variable  
@PoundTon_Var_Id int   -- Use the variable Id of the #/Ton variable  
  
AS  
SET NOCOUNT ON  
  
declare   
@PL_Id as int,  
@PU_Id as int,  
@PUG_Id as int,  
@RepVar_Id as int  
  
select  @PL_Id = pl.pl_id, @PU_Id = v.pu_id  
from [dbo].prod_lines pl   
 JOIN [dbo].prod_units pu ON pl.pl_id = pu.pl_id  
 JOIN [dbo].variables v ON v.pu_id = pu.pu_id  
where v.var_id = @MassFlow_Var_Id  
  
  
select @PUG_Id = pug_id, @RepVar_Id = convert(int,ltrim(rtrim(extended_info)))  
from [dbo].variables  
where var_id = @MassFlow_Var_Id  
  
  
Insert into [dbo].Local_RealTimeDryFlow (pl_id, pu_id, pug_id,   
  consist_var_id, dryflow_var_id, pctsheet_var_id,  
  repvar_id, result_on,   
  consistency1, density, conversion,  
  flow1, flow2, flow3, flow4)  
 values (@PL_Id, @PU_Id, @PUG_Id,   
  @Concentration_Var_Id, @MassFlow_Var_Id, @PoundTon_Var_Id,  
  @RepVar_Id, @Result_On,  
  @Concentration, @Density, @Conversion,   
  @Flow1, @Flow2, @Flow3, @Flow4)  
  
if @@error <> 0   
begin  
 insert into [dbo].local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in spLocal_PutRealTimeChemUsage')  
end  
  
set @OutputVal = 1.0  
  
Delete from [dbo].Local_RealTimeDryFlow  
where result_on < dateadd(minute,-65, getdate())  
  
  
SET NOCOUNT OFF  
  

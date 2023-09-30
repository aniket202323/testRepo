    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
--This Procedure places values into the Local_RealTimeDryFlow table for reporting on  
--Furnish items.  DO NOT use this routine for Stock Flow or Chemical Flow items.  
--Use spLocal_PutRealTimeStockFlow for Machine Stock Flow items, and   
--Use spLocal_PutRealTimeChemFlow for Chemical Flow items.  
*/  
  
CREATE PROCEDURE spLocal_PutRealTimeDryFlow  
@OutputVal float OUTPUT,  
@Result_On datetime,   -- The time of the Flow 1 variable  
@Consistency float,   -- The value of the Consistency  
@Density float,    -- The value of the Furnish/Stock Density  
@Conversion float,   -- Use default value of 1, leave blank  
@Flow1 float,    -- The value of the Flow 1 variable  
@Flow2 float,    -- The value of the Flow 2 variable (or blank)  
@Flow3 float,    -- The value of the Flow 3 variable (or blank)  
@Flow4 float,    -- The value of the Flow 4 variable (or blank)  
@Consist_Var_Id int,   -- The variable Id of the Consistency variable  
@QuickMix1_Var_Id int,   -- The variable Id of the Flow 1 Quick Mix % Limit  
@QuickMix2_Var_Id int,   -- The variable Id of the Flow 2 Quick Mix % Limit (or blank)  
@QuickMix3_Var_Id int,   -- The variable Id of the Flow 3 Quick Mix % Limit (or blank)  
@QuickMix4_Var_Id int,   -- The variable Id of the Flow 4 Quick Mix % Limit (or blank)  
@DryFlow_Var_Id int,   -- The variable Id of the Dry Flow variable (This variable)  
@PctSheet_Var_Id int   -- The variable Id of the DrySheet % Limit variable  
  
  
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
where v.var_id = @DryFlow_Var_Id  
  
select @PUG_Id = pug_id, @RepVar_Id = convert(int,ltrim(rtrim(extended_info)))  
from [dbo].variables  
where var_id = @DryFlow_Var_Id  
  
Insert into [dbo].Local_RealTimeDryFlow (pl_id, pu_id, pug_id,   
  quickmix1_var_id, quickmix2_var_id, quickmix3_var_id, quickmix4_var_id,   
  consist_var_id,  
  pctsheet_var_id, dryflow_var_id, repvar_id,   
  result_on, consistency1, density, conversion,   
  flow1, flow2, flow3, flow4)  
 values (@PL_Id, @PU_Id, @PUG_Id,   
  @QuickMix1_Var_Id, @QuickMix2_Var_Id, @QuickMix3_Var_Id, @QuickMix4_Var_Id,   
  @Consist_Var_Id,   
  @PctSheet_Var_Id, @DryFlow_Var_Id, @RepVar_Id,   
  @Result_On, @Consistency, @Density, @Conversion,  
  @Flow1, @Flow2, @Flow3, @Flow4)  
  
if @@error <> 0   
begin  
 insert into local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in splocal_putrealtimeDryFlow')  
end  
  
set @OutputVal = 1.0  
  
Delete from [dbo].Local_RealTimeDryFlow  
where result_on < dateadd(minute,-65, getdate())  
  
SET NOCOUNT OFF  
  

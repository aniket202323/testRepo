  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE spLocal_PutRealTimeVar  
@OutputVal float OUTPUT,  
@Var_Id int,  
@PU_Id int,  
@Result_On datetime,  
@Result float  
  
AS  
  
SET NOCOUNT ON  
  
declare   
@PL_Id as int,  
@PUG_Id as int,  
@RepVar_Id as int  
  
  
if @Result is not null  
begin  
  
   select  @PL_Id = pl.pl_id  
   from [dbo].prod_lines pl  
  join [dbo].prod_units pu on pl.pl_id = pu.pl_id  
   where pu.pu_id = @PU_Id  
  
   if @@error <> 0   
   begin  
 insert into [dbo].local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in splocal_putrealtimevar, selecting prod_lines')  
   end  
  
   select @PUG_Id = pug_id, @RepVar_Id = convert(int,ltrim(rtrim(user_defined1)))  
   from [dbo].variables  
   where var_id = @Var_Id  
  
   if @@error <> 0   
   begin  
 insert into [dbo].local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in splocal_putrealtimevar, selecting pug_id, repvar_id')  
   end  
  
   Insert into [dbo].Local_RealTimeVar (var_id, pu_id, pug_id, pl_id, repvar_id, result_on, result)  
   values (@Var_Id, @PU_Id, @PUG_Id, @PL_Id, @RepVar_Id, @Result_On, @Result)  
  
   if @@error <> 0   
   begin  
 insert into [dbo].local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in splocal_putrealtimevar, insert to local_realtimevar')  
   end  
  
   set @OutputVal = 1.0  
end  
  
if @Result is null  
begin  
 insert into [dbo].local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Null Result in local_realtimevar')  
end  
  
Delete from [dbo].Local_RealTimeVar  
where result_on < dateadd(hour,-1, getdate())  
  
if @@error <> 0   
   begin  
 insert into [dbo].local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in splocal_putrealtimevar, delete from local_realtimevar')  
   end  
  
SET NOCOUNT OFF  
  

Create Procedure dbo.spDBR_Get_Master_Unit
@varid int = 55
as
 	 declare @puid int
 	 set @puid = (select p.Master_Unit from prod_units p, variables v where v.var_id = @varid and p.pu_id = v.pu_id)
 	 if (@puid is null)
 	 begin
 	  	 set @puid = (select pu_id from variables where var_id = @varid)
 	 end
 	 select @puid as pu_id

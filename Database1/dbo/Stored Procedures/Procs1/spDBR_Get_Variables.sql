Create Procedure dbo.spDBR_Get_Variables
@line_id int,
@unit_id int
as
 	 if (@line_id = 0 and @unit_id = 0)
 	 begin
 	  	 select var_id, Var_desc from variables where not var_id = 0
 	 end
 	 else
 	 begin
 	  	 if (@unit_id = 0)
 	  	 begin
 	  	  	 select v.var_id, v.var_desc from variables v, prod_units p where v.pu_id = p.pu_id and p.pl_id = @line_id and not v.var_id = 0
 	  	  	 
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 select var_id, var_desc from variables where pu_id = @unit_id and not var_id = 0 	 
 	  	 end
 	 end

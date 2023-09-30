Create Procedure dbo.spDBR_Get_Variable_Name
@var_id int
as
 	 insert into #sp_name_results select Var_desc from variables where var_id = @var_id

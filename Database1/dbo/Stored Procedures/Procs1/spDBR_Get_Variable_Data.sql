Create Procedure dbo.spDBR_Get_Variable_Data
@varid int,
@param1 varchar(100),
@param2 varchar(100)
AS
select v.var_id, v.var_Desc, t.Result_on, t.Result, @param1, @param2 from 
Variables v, Tests t 
where v.var_id = @varid
and t.var_id = v.var_id 
and t.Result_On = (select max(Result_on) from Tests where var_id = @varid)
select * from dashboard_reports where dashboard_report_id = 0
select v.var_id, v.var_Desc, t.Result_on, t.Result from 
Variables v, Tests t 
where v.var_id = @varid
and t.var_id = v.var_id 
and t.Result_On = (select max(Result_on) from Tests where var_id = @varid)

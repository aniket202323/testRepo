Create Procedure dbo.spGBO_GetVariables 
  @UnitID int     AS
/*
  select a.*, b.pug_desc 
    from variables a 
    join pu_groups b on b.pug_id = a.pug_id
    where a.pu_id = @UnitID
    order by b.pug_order,a.pug_order
*/
  select a.*, b.pug_desc 
    into #GBOperVars
    from variables a 
    join pu_groups b on b.pug_id = a.pug_id
    where a.pu_id = @UnitID
    order by b.pug_order,a.pug_order
Update #GBOperVars Set Data_Type_Id = 3 Where Data_Type_Id > 50
  select *
    from #GBOperVars
drop table #GBOperVars

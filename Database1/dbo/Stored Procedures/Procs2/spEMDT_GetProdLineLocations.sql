Create Procedure dbo.spEMDT_GetProdLineLocations 
@PU_Id int,
@ET_Id int = 2,
@User_Id int
AS
create table #ProdLineLocations(
  PU_Order int,
  PU_Desc nvarchar(50),
  Reason_Tree nvarchar(50) ,
  PU_Id int,
  Reason_Tree_Id int
)
insert into #ProdLineLocations
select prod_units.pu_order, prod_units.pu_desc,
Reason_Tree = CASE
  WHEN event_reason_tree.tree_name <> '' THEN event_reason_tree.tree_name
  ELSE '<Unassigned>'
END,
prod_units.pu_id, prod_events.name_id
from prod_units
left outer join prod_events on prod_events.pu_id = prod_units.pu_id and prod_events.event_type = @ET_Id
left outer join event_reason_tree on event_reason_tree.tree_name_id = prod_events.name_Id
where (prod_units.master_unit = @PU_Id or prod_units.pu_id = @PU_Id) 
and prod_units.timed_event_association > 0
order by prod_units.pu_order
select * from #ProdLineLocations
drop table #ProdLineLocations

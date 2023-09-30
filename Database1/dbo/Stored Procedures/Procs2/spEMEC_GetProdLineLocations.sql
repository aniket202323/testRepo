Create Procedure dbo.spEMEC_GetProdLineLocations 
@PU_Id int,
@ET_Id int = 2,
@Case tinyint = 1,
@User_Id int
AS
create table #ProdLineLocations(
  PU_Order int,
  PU_Desc nvarchar(50),
  Reason_Tree nvarchar(50) ,
  PU_Id int,
  Reason_Tree_Id int,
  Timed_Event_Association nVarChar(10),
  Waste_Event_Association nVarChar(10),
  Waste_EventorTime nVarChar(10)
)
if @Case = 1 and @ET_Id = 2
  Begin
 	  	 if (select count(*) 
 	  	  	 from prod_units
 	  	  	 where (master_unit = @PU_Id or pu_id = @PU_Id)
 	  	  	 and timed_event_association > 0) = 0
 	  	  	  	 update prod_units set timed_event_association = 1 where master_unit = @PU_Id or pu_id = @PU_Id
    insert into #ProdLineLocations
    select prod_units.pu_order, prod_units.pu_desc, NULL, prod_units.pu_id, prod_events.name_id, 
     Timed_Event_Association = CASE 
       WHEN prod_units.timed_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Waste_Event_Association = CASE 
       WHEN prod_units.waste_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Timed_EventorTime = CASE 
       WHEN prod_units.waste_event_association = 1  THEN 'Event'
       WHEN prod_units.waste_event_association = 2 THEN 'Time'
       ELSE ''
     END
    from prod_units
    left outer join prod_events on prod_events.pu_id = prod_units.pu_id and prod_events.event_type = @ET_Id
    where prod_units.master_unit = @PU_Id or prod_units.pu_id = @PU_Id
    order by prod_units.pu_order
    update #ProdLineLocations set #ProdLineLocations.Reason_Tree = event_reason_tree.tree_name
    from event_reason_tree
    where event_reason_tree.tree_name_id = #ProdLineLocations.Reason_Tree_Id
    and #ProdLineLocations.Timed_Event_Association = 'Yes'
  End
else if @Case = 1 and @ET_Id = 3
  Begin
 	  	 if (select count(*) 
 	  	  	 from prod_units
 	  	  	 where (master_unit = @PU_Id or pu_id = @PU_Id)
 	  	  	 and waste_event_association > 0) = 0
 	  	  	  	 update prod_units set waste_event_association = (Select Case When Count(*) > 0 Then 1 Else 2 End From Event_Configuration Where PU_Id = @PU_Id and ET_Id = 1) where master_unit = @PU_Id or pu_id = @PU_Id
    insert into #ProdLineLocations
    select prod_units.pu_order, prod_units.pu_desc, NULL, prod_units.pu_id, prod_events.name_id, 
     Timed_Event_Association = CASE 
       WHEN prod_units.timed_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Waste_Event_Association = CASE 
       WHEN prod_units.waste_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Timed_EventorTime = CASE 
       WHEN prod_units.waste_event_association = 1  THEN 'Event'
       WHEN prod_units.waste_event_association = 2 THEN 'Time'
       ELSE ''
     END
    from prod_units
    left outer join prod_events on prod_events.pu_id = prod_units.pu_id and prod_events.event_type = @ET_Id
    where prod_units.master_unit = @PU_Id or prod_units.pu_id = @PU_Id
    order by prod_units.pu_order
    update #ProdLineLocations set #ProdLineLocations.Reason_Tree = event_reason_tree.tree_name
    from event_reason_tree
    where event_reason_tree.tree_name_id = #ProdLineLocations.Reason_Tree_Id
    and  #ProdLineLocations.Waste_Event_Association = 'Yes'
  End
else if @Case = 2 and @ET_Id = 2
  Begin
    insert into #ProdLineLocations
    select prod_units.pu_order, prod_units.pu_desc, NULL, prod_units.pu_id, prod_events.name_id, 
     Timed_Event_Association = CASE 
       WHEN prod_units.timed_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Waste_Event_Association = CASE 
       WHEN prod_units.waste_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Timed_EventorTime = CASE 
       WHEN prod_units.waste_event_association = 1  THEN 'Event'
       WHEN prod_units.waste_event_association = 2 THEN 'Time'
       ELSE ''
     END
    from prod_units
    left outer join prod_events on prod_events.pu_id = prod_units.pu_id and prod_events.event_type = @ET_Id
    where (prod_units.master_unit = @PU_Id or prod_units.pu_id = @PU_Id)
    and prod_units.timed_event_association > 0
    order by prod_units.pu_order
    update #ProdLineLocations set #ProdLineLocations.Reason_Tree = event_reason_tree.tree_name
    from event_reason_tree
    where event_reason_tree.tree_name_id = #ProdLineLocations.Reason_Tree_Id
    and #ProdLineLocations.Timed_Event_Association = 'Yes'
  End
else if @Case = 2 and @ET_Id = 3
  Begin
    insert into #ProdLineLocations
    select prod_units.pu_order, prod_units.pu_desc, NULL, prod_units.pu_id, prod_events.name_id, 
     Timed_Event_Association = CASE 
       WHEN prod_units.timed_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Waste_Event_Association = CASE 
       WHEN prod_units.waste_event_association > 0  THEN 'Yes'
       ELSE 'No'
     END,
     Timed_EventorTime = CASE 
       WHEN prod_units.waste_event_association = 1  THEN 'Event'
       WHEN prod_units.waste_event_association = 2 THEN 'Time'
       ELSE ''
     END
    from prod_units
    left outer join prod_events on prod_events.pu_id = prod_units.pu_id and prod_events.event_type = @ET_Id
    where (prod_units.master_unit = @PU_Id or prod_units.pu_id = @PU_Id)
    and prod_units.waste_event_association > 0
    order by prod_units.pu_order
    update #ProdLineLocations set #ProdLineLocations.Reason_Tree = event_reason_tree.tree_name
    from event_reason_tree
    where event_reason_tree.tree_name_id = #ProdLineLocations.Reason_Tree_Id
    and  #ProdLineLocations.Waste_Event_Association = 'Yes'
  End
select * from #ProdLineLocations
drop table #ProdLineLocations

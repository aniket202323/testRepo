CREATE FUNCTION dbo.fnSDK_DEI_GetReasonTreeItems(
@ReasonTreeId int,
@Level int,
@Level1Id int,
@Level2Id int,
@Level3Id int,
@Level4Id int
)
returns @ReasonTreeItems table
(
  ItemId int,
  ItemOrder int,
  ItemDisplayValue nvarchar(100),
  ItemValue nvarchar(100)
)
AS
begin
if (@ReasonTreeId is null)
  return;
 	 
if (@Level = 1)
begin
  insert into @ReasonTreeItems
  select rea.Event_Reason_Id, coalesce(tree.ERT_Data_Order, rea.Event_Reason_Order), rea.Event_Reason_Name, rea.Event_Reason_Name
    from Event_Reason_Tree_Data tree
    join Event_Reasons rea on rea.Event_Reason_Id = tree.Level1_Id
    where tree.Tree_Name_Id = @ReasonTreeId and tree.Event_Reason_Level = 1
end
else if ((@Level = 2) and (@Level1Id is not null))
begin
  insert into @ReasonTreeItems
  select rea.Event_Reason_Id, coalesce(tree.ERT_Data_Order, rea.Event_Reason_Order), rea.Event_Reason_Name, rea.Event_Reason_Name
    from Event_Reason_Tree_Data tree
    join Event_Reasons rea on rea.Event_Reason_Id = tree.Level2_Id
    where tree.Tree_Name_Id = @ReasonTreeId and tree.Event_Reason_Level = 2
      and tree.Level1_Id = @Level1Id
end
else if ((@Level = 3) and (@Level1Id is not null) and (@Level2Id is not null))
begin
  insert into @ReasonTreeItems
  select rea.Event_Reason_Id, coalesce(tree.ERT_Data_Order, rea.Event_Reason_Order), rea.Event_Reason_Name, rea.Event_Reason_Name
    from Event_Reason_Tree_Data tree
    join Event_Reasons rea on rea.Event_Reason_Id = tree.Level3_Id
    where tree.Tree_Name_Id = @ReasonTreeId and tree.Event_Reason_Level = 3
      and tree.Level1_Id = @Level1Id
      and tree.Level2_Id = @Level2Id
end
else if ((@Level = 4) and (@Level1Id is not null) and (@Level2Id is not null) and (@Level3Id is not null))
begin
  insert into @ReasonTreeItems
  select rea.Event_Reason_Id, coalesce(tree.ERT_Data_Order, rea.Event_Reason_Order), rea.Event_Reason_Name, rea.Event_Reason_Name
    from Event_Reason_Tree_Data tree
    join Event_Reasons rea on rea.Event_Reason_Id = tree.Level4_Id
    where tree.Tree_Name_Id = @ReasonTreeId and tree.Event_Reason_Level = 4
      and tree.Level1_Id = @Level1Id
      and tree.Level2_Id = @Level2Id
      and tree.Level3_Id = @Level3Id
end
return
 	 
end

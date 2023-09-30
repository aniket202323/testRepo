CREATE FUNCTION dbo.fnSDK_Esig_GetItemLists(
  @ESigLevel int,
  @GroupId int
)
returns @Items table
(
  PropertyName nvarchar(100),
  ItemValue nvarchar(100),
  ItemId int,
  ItemDisplayValue nvarchar(100)
)
AS
begin
if (@ESigLevel is null) or (@ESigLevel = 0)
  return
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
declare @UserTreeId int
select @UserTreeId = Value from Site_Parameters where parm_id = 440
insert into @PropertyItems
select 'UserReasons', r.Event_Reason_Id, null, r.Event_Reason_Name, r.Event_Reason_Name
  from Event_Reason_Tree_Data t
  join Event_Reasons r on r.Event_Reason_Id = t.Level1_Id
  where t.Tree_Name_Id = @UserTreeId and t.Event_Reason_Level = 1
if (@ESigLevel = 2)
  begin
    insert into @PropertyItems
    select 'ApproverUsers', u.User_Id, null, u.Username, u.Username
      from Users u
      join User_Security s on s.User_Id = u.User_Id
      where s.Group_Id in (1, @GroupId) and s.Access_Level >= 3
    declare @ApproverTreeId int
    select @ApproverTreeId = Value from Site_Parameters where parm_id = 438
    insert into @PropertyItems
    select 'ApproverReasons', r.Event_Reason_Id, null, r.Event_Reason_Name, r.Event_Reason_Name
      from Event_Reason_Tree_Data t
      join Event_Reasons r on r.Event_Reason_Id = t.Level1_Id
      where t.Tree_Name_Id = @ApproverTreeId and t.Event_Reason_Level = 1
  end
insert into @Items
  select PropertyName, ItemValue, ItemId, ItemDisplayValue
   from @PropertyItems
   order by PropertyName, ItemOrder, ItemDisplayValue
return
 	 
end

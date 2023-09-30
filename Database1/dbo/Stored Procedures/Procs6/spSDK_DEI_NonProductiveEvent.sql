CREATE procedure [dbo].[spSDK_DEI_NonProductiveEvent]
 	 @TransactionType int,
 	 @FirstTime bit,
 	 @SDKUserId int,
 	 @DepartmentId int output,
 	 @DepartmentIdChanged bit,
 	 @ProductionLineId int output,
 	 @ProductionLineIdChanged bit,
 	 @ProductionUnitId int output,
 	 @ProductionUnitIdChanged bit,
 	 @Reason1Id int output,
 	 @Reason1IdChanged bit,
 	 @Reason2Id int output,
 	 @Reason2IdChanged bit,
 	 @Reason3Id int output,
 	 @Reason3IdChanged bit,
 	 @Reason4Id int output,
 	 @Reason4IdChanged bit,
 	 @UserId int output,
 	 @UserIdChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL real, UEL real, Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @EventType int
Declare @ReasonTreeId int
set @EventType = 2 -- Downtime
set @ReasonTreeId = null
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                     '',                       null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'Department',             'DepartmentId',           null,             1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionLine',         'ProductionLineId',       'Line',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionUnit',         'ProductionUnitId',       'Unit',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'StartTime',              '',                       'Start Time',     1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'EndTime',                '',                       'End Time',       1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'EntryOn',                '',                       'Entry On',       1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'ReasonTreeDataId',       '',                       null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'Reason1',                'Reason1Id',              'Reason 1',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'Reason2',                'Reason2Id',              'Reason 2',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'Reason3',                'Reason3Id',              'Reason 3',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'Reason4',                'Reason4Id',              'Reason 4',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'CommentText',            'CommentId',              'Reason Comment', 1, 'comment',  0, null, null, null, null, null
insert into @Properties select 'Username',               'UserId',                 'User Name',      1, 'list',     0, null, null, null, null, null
------------------------------------------------------------------------------------------------------------------
-- Force dependant fields to null if their parent has been modified
------------------------------------------------------------------------------------------------------------------
if (@DepartmentIdChanged = 1)
  begin
    set @ProductionLineId = null
    set @ProductionLineIdChanged = 1
  end
if (@ProductionLineIdChanged = 1)
  begin
    set @ProductionUnitId = null
    set @ProductionUnitIdChanged = 1
  end
if (@ProductionUnitIdChanged = 1)
begin
  set @Reason1Id = null
  set @Reason1IdChanged = 1
end
if (@Reason1IdChanged = 1)
begin
  set @Reason2Id = null
  set @Reason2IdChanged = 1
end
if (@Reason2IdChanged = 1)
begin
  set @Reason3Id = null
  set @Reason3IdChanged = 1
end
if (@Reason3IdChanged = 1)
begin
  set @Reason4Id = null
  set @Reason4IdChanged = 1
end
------------------------------------------------------------------------------------------------------------------
-- Build picking lists
------------------------------------------------------------------------------------------------------------------
Declare @ValidUnits table (Dept_Id int, Dept_Desc nvarchar(100), PL_Id int, PL_Desc nvarchar(100), PU_Id int, PU_Order int, PU_Desc nvarchar(100), group_id int, accessLevel int, isCurVal bit)
Declare @defaultLevel int
Declare @nullGroupIdLevel int
Declare @HasAdminRWLevel int
Set @defaultLevel = 0     --denied
Set @nullGroupIdLevel = 2 --if group_id is null, this is the access level 
Set @HasAdminRWLevel = 0
if (@FirstTime = 1 or @DepartmentIdChanged = 1 or @ProductionLineIdChanged = 1 or @ProductionUnitIdChanged = 1)
  begin
    insert into @ValidUnits (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Order, PU_Desc, group_id, accessLevel, isCurVal)
      Select dept.Dept_Id, dept.Dept_Desc, pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Order, pu.PU_Desc, coalesce(pu.group_id,pl.group_id), @defaultLevel, 0
        from Departments_Base dept
        join Prod_Lines_Base pl on pl.Dept_Id = dept.Dept_Id
        join Prod_Units_Base pu on pu.PL_Id = pl.PL_Id
        where dept.Dept_Id > 0
 	 update vs set accessLevel=@nullGroupIdLevel
 	 from @ValidUnits vs
 	 where vs.group_id is null
 	 update vs set accessLevel=us.Access_Level
 	 from @ValidUnits vs
 	 join User_Security us  on vs.group_id=us.Group_Id  
 	 where us.User_Id=@SDKUserId
 	 
 	 select @HasAdminRWLevel=count(*) from user_security where user_id=@SDKUserId and access_Level>=2 and group_id=1
 	 if @HasAdminRWLevel > 0 
 	 begin
 	  	 update vs set vs.accessLevel = @nullGroupIdLevel  from @ValidUnits vs
 	 end 
 	 update @ValidUnits set isCurVal = 1
 	   where (@DepartmentId = Dept_Id and @ProductionLineId = PL_Id and @ProductionUnitId = PU_Id)
 	   
 	 delete from @ValidUnits where accessLevel < 2 and isCurVal = 0
  end
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select distinct 'Department', Dept_Id, null, Dept_Desc, Dept_Desc from @ValidUnits
    insert into @PropertyItems select 'Department', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if (@FirstTime = 1 or @DepartmentIdChanged = 1)
  begin
    if (@DepartmentId is not null)
      begin
        insert into @PropertyItems select distinct 'ProductionLine', PL_Id, null, PL_Desc, PL_Desc from @ValidUnits where Dept_Id = @DepartmentId
        insert into @PropertyItems select 'ProductionLine', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end 	 
    else
      insert into @PropertyItems select 'ProductionLine', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @ProductionLineIdChanged = 1)
  begin
    if (@ProductionLineId is not null)
      begin
        insert into @PropertyItems select distinct 'ProductionUnit', PU_Id, PU_Order, PU_Desc, PU_Desc from @ValidUnits where PL_Id = @ProductionLineId
        insert into @PropertyItems select 'ProductionUnit', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ProductionUnit', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select 'Username', User_Id, null, Username, Username from Users where User_Id > 50
    insert into @PropertyItems select 'Username', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if (@ProductionUnitId is not null)
  begin
    select @ReasonTreeId = Name_Id from Prod_Events where PU_Id = @ProductionUnitId and Event_Type = @EventType
  end
if (@FirstTime = 1 or @ProductionUnitIdChanged = 1 or @ProductionUnitId is not null)
  begin
    if (@ProductionUnitId is not null)
      begin
        insert into @PropertyItems select 'Reason1', * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 1, @Reason1Id, @Reason2Id, @Reason3Id, @Reason4Id)
        insert into @PropertyItems select 'Reason1', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Reason1', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Reason1IdChanged = 1 or @Reason1Id is not null)
  begin
    if (@Reason1Id is not null)
      begin
        insert into @PropertyItems select 'Reason2', * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 2, @Reason1Id, @Reason2Id, @Reason3Id, @Reason4Id)
        insert into @PropertyItems select 'Reason2', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Reason2', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Reason2IdChanged = 1 or @Reason2Id is not null)
  begin
    if (@Reason2Id is not null)
      begin
        insert into @PropertyItems select 'Reason3', * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 3, @Reason1Id, @Reason2Id, @Reason3Id, @Reason4Id)
        insert into @PropertyItems select 'Reason3', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Reason3', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Reason3IdChanged = 1 or @Reason3Id is not null)
  begin
    if (@Reason3Id is not null)
      begin
        insert into @PropertyItems select 'Reason4', * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 4, @Reason1Id, @Reason2Id, @Reason3Id, @Reason4Id)
        insert into @PropertyItems select 'Reason4', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Reason4', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@ReasonTreeId is not null)
  begin
    declare @TreeNames table (TreeId int, TreeLevel int, LevelName varchar(100))
    insert into @TreeNames (TreeId, TreeLevel, LevelName)
      select Tree_Name_Id, Reason_Level, Level_Name
        from Event_Reason_Level_Headers
        where Tree_Name_Id = @ReasonTreeId
    update @Properties set PropertyDisplayName = '[PropName][-Num] - ' + (select LevelName from @TreeNames where TreeId = @ReasonTreeId and TreeLevel = 1) where PropertyName = 'Reason1'
    update @Properties set PropertyDisplayName = '[PropName][-Num] - ' + (select LevelName from @TreeNames where TreeId = @ReasonTreeId and TreeLevel = 2) where PropertyName = 'Reason2'
    update @Properties set PropertyDisplayName = '[PropName][-Num] - ' + (select LevelName from @TreeNames where TreeId = @ReasonTreeId and TreeLevel = 3) where PropertyName = 'Reason3'
    update @Properties set PropertyDisplayName = '[PropName][-Num] - ' + (select LevelName from @TreeNames where TreeId = @ReasonTreeId and TreeLevel = 4) where PropertyName = 'Reason4'
 	  	 update @Properties set IsEnabled = 0 where PropertyName like 'Reason%' and PropertyType = 'List' and PropertyDisplayName is null
  end
else
  begin
    update @Properties set IsEnabled = 0 where PropertyName like 'Reason%' and PropertyType = 'List'
  end
------------------------------------------------------------------------------------------------------------------
-- Clean up properties for transactions
------------------------------------------------------------------------------------------------------------------
Declare @RequiredProperties table(PropertyName nvarchar(100))
Declare @ValidProperties table(PropertyName nvarchar(100))
Declare @DisabledProperties table(PropertyName nvarchar(100))
if (@TransactionType <> 2) -- Not Delete
begin
 	 insert into @ValidProperties (PropertyName) values('Department')
 	 insert into @ValidProperties (PropertyName) values('ProductionLine')
 	 insert into @ValidProperties (PropertyName) values('ProductionUnit')
 	 insert into @ValidProperties (PropertyName) values('StartTime')
 	 insert into @ValidProperties (PropertyName) values('EndTime')
 	 insert into @ValidProperties (PropertyName) values('Reason1')
 	 insert into @ValidProperties (PropertyName) values('Reason2')
 	 insert into @ValidProperties (PropertyName) values('Reason3')
 	 insert into @ValidProperties (PropertyName) values('Reason4')
 	 insert into @ValidProperties (PropertyName) values('CommentText')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('Department')
 	 insert into @RequiredProperties (PropertyName) values('ProductionLine')
 	 insert into @RequiredProperties (PropertyName) values('ProductionUnit')
 	 insert into @RequiredProperties (PropertyName) values('StartTime')
 	 insert into @RequiredProperties (PropertyName) values('EndTime')
 	 if (@Reason1Id is not null)
 	 begin
 	  	 if (exists(select * from @PropertyItems where PropertyName like 'Reason1' and ItemId is not null))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Reason1')
 	  	 if ((@Reason2Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Reason2' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Reason2')
 	  	 if ((@Reason3Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Reason3' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Reason3')
 	  	 if ((@Reason4Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Reason4' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Reason4')
 	 end
end
if (@TransactionType = 1) -- Update
begin
 	 insert into @DisabledProperties (PropertyName) values('Department')
 	 insert into @DisabledProperties (PropertyName) values('ProductionLine')
 	 insert into @DisabledProperties (PropertyName) values('ProductionUnit')
end
if (@TransactionType in (1,2)) -- Update or Delete
begin
 	 insert into @RequiredProperties (PropertyName) values('Id')
 	 insert into @ValidProperties (PropertyName) values('Id')
end
if (@TransactionType = 3) -- Query
begin
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('EntryOn')
 	 insert into @ValidProperties (PropertyName) values('ReasonTreeDataId')
end
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

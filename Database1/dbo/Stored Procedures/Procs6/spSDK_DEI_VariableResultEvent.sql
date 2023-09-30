CREATE procedure [dbo].[spSDK_DEI_VariableResultEvent]
 	 @TransactionType int,
 	 @FirstTime bit,
 	 @SDKUserId int,
 	 @DepartmentId int output,
 	 @DepartmentIdChanged bit,
 	 @ProductionLineId int output,
 	 @ProductionLineIdChanged bit,
 	 @ProductionUnitId int output,
 	 @ProductionUnitIdChanged bit,
 	 @EventTypeId int output,
 	 @EventTypeIdChanged bit,
 	 @VariableId int output,
 	 @VariableIdChanged bit,
 	 @UserId int output,
 	 @UserIdChanged bit,
 	 @SecondUserId int output,
 	 @SecondUserIdChanged bit,
 	 @ProductId int output,
 	 @ProductIdChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL real, UEL real, Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                         '',                         null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'Department',                 'DepartmentId',             null,             1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionLine',             'ProductionLineId',         'Line',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionUnit',             'ProductionUnitId',         'Unit',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'EventType',                  'EventTypeId',              'Event Type',     1, 'list',     0, null, null, null, null, null
insert into @Properties select 'Variable',                   'VariableId',               null,             1, 'list',     0, null, null, null, null, null
insert into @Properties select 'Canceled',                   '',                         null,             1, 'bool',     0, null, null, null, null, null
insert into @Properties select 'ResultOn',                   '',                         'Result On',      1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'EntryOn',                    '',                         'Entry On',       1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'ArrayId',                    '',                         null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'CommentText',                'CommentId',                'Comment',        1, 'comment',  0, null, null, null, null, null
insert into @Properties select 'Username',                   'UserId',                   'User Name',      1, 'list',     0, null, null, null, null, null
insert into @Properties select 'EventName',                  '',                         'Event',          1, 'text',     0, null, null, null, null, null
insert into @Properties select 'EventId',                    '',                         null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'Value',                      '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'SecondUsername',             'SecondUserId',             null,             1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ShouldArchive',              '',                         null,             1, 'bool',     0, null, null, null, null, null
insert into @Properties select 'TestFrequency',              '',                         'Test Frequency', 1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'TestName',                   '',                         'Test Name',      1, 'text',     0, null, null, null, null, null
insert into @Properties select 'ProductCode',                'ProductId',                'Product',        1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionPlanId',           '',                         null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'ProductionPlanStartId',      '',                         null,             1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'UEL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'URL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'UWL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'UUL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'TGT',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'LUL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'LWL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'LRL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'LEL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'UCL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'TCL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'LCL',                        '',                         null,             1, 'text',     0, null, null, null, null, null
insert into @Properties select 'ESignatureId',               '',                         null,             1, 'integer',  0, null, null, null, null, null
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
  set @EventTypeId = null
  set @EventTypeIdChanged = 1
  set @ProductId = null
  set @ProductIdChanged = 1
end
if (@EventTypeIdChanged = 1)
begin
  set @VariableId = null
  set @VariableIdChanged = 1
end
------------------------------------------------------------------------------------------------------------------
-- Build picking lists
------------------------------------------------------------------------------------------------------------------
Declare @Units table (Dept_Id int, Dept_Desc nvarchar(100), PL_Id int, PL_Desc nvarchar(100), PU_Id int, PU_Order int, PU_Desc nvarchar(100), group_id int, accessLevel int, isCurVal bit)
Declare @defaultLevel int
Declare @nullGroupIdLevel int
Declare @HasAdminRWLevel int
Set @defaultLevel = 0     --denied
Set @nullGroupIdLevel = 2 --if group_id is null, this is the access level 
Set @HasAdminRWLevel = 0
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select 'Username',       User_Id, null, Username, Username from Users where User_Id > 50
    insert into @PropertyItems select 'Username',       * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
    insert into @PropertyItems select 'SecondUsername', User_Id, null, Username, Username from Users where User_Id > 50
    insert into @PropertyItems select 'SecondUsername', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if (@FirstTime = 1 or @DepartmentIdChanged = 1 or @ProductionLineIdChanged = 1 or @ProductionUnitIdChanged = 1)
  begin
    insert into @Units (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Order, PU_Desc, group_id, accessLevel, isCurVal)
    Select dept.Dept_Id, dept.Dept_Desc, pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Order, pu.PU_Desc, coalesce(pu.group_id,pl.group_id), @defaultLevel, 0
      from Prod_Units_Base pu
      join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
      join Departments_Base dept on dept.Dept_Id = pl.Dept_Id and dept.Dept_Id > 0
 	     where pu.PU_Id in (select distinct PU_Id from Variables_Base as Variables)
 	 update vs set accessLevel=@nullGroupIdLevel
 	 from @Units vs
 	 where vs.group_id is null
 	 update vs set accessLevel=us.Access_Level
 	 from @Units vs
 	 join User_Security us  on vs.group_id=us.Group_Id  
 	 where us.User_Id=@SDKUserId
 	 
 	 select @HasAdminRWLevel=count(*) from user_security where user_id=@SDKUserId and access_Level>=2 and group_id=1
 	 if @HasAdminRWLevel > 0 
 	 begin
 	  	 update vs set vs.accessLevel = @nullGroupIdLevel  from @Units vs
 	 end 
 	 update @Units set isCurVal = 1
 	   where (@DepartmentId = Dept_Id and @ProductionLineId = PL_Id and @ProductionUnitId = PU_Id)
 	   
 	 delete from @Units where accessLevel < 2 and isCurVal = 0
    insert into @PropertyItems select distinct 'Department', Dept_Id, null, Dept_Desc, Dept_Desc from @Units where Dept_Id > 0
    insert into @PropertyItems select 'Department', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
    if (@DepartmentId is not null)
      begin
        insert into @PropertyItems select distinct 'ProductionLine', PL_Id, null, PL_Desc, PL_Desc from @Units where Dept_Id = @DepartmentId
        insert into @PropertyItems select 'ProductionLine', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ProductionLine', * from fnSDK_DEI_InsertEmptyList (0)
    if (@ProductionLineId is not null)
      begin
        insert into @PropertyItems select distinct 'ProductionUnit', PU_Id, PU_Order, PU_Desc, PU_Desc from @Units where PL_Id = @ProductionLineId
        insert into @PropertyItems select 'ProductionUnit', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ProductionUnit', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @ProductionUnitIdChanged = 1)
  begin
    if (@ProductionUnitId is not null)
      begin
        insert into @PropertyItems
          select 'EventType', ET_Id, null, ET_Desc, ET_Desc
            from Event_Types
            where Variables_Assoc = 1 and ET_Id in (select distinct Event_Type from Variables_Base as Variables where PU_Id = @ProductionUnitId)
        insert into @PropertyItems select 'EventType', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
        insert into @PropertyItems
          select 'ProductCode', p.Prod_Id, null, p.Prod_Code, p.Prod_Code
            from PU_Products pup
            join Products p on p.Prod_Id = pup.Prod_id
            where pup.PU_Id = @ProductionUnitId and (p.Is_Active_Product is null or p.Is_Active_Product = 1)
        insert into @PropertyItems select 'ProductCode', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      begin
        insert into @PropertyItems select 'EventType',   * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'ProductCode', * from fnSDK_DEI_InsertEmptyList (0)
      end
  end
if (@FirstTime = 1 or @EventTypeIdChanged = 1)
  begin
    if ((@ProductionUnitId is not null) and (@EventTypeId is not null))
      begin
        insert into @PropertyItems
          select 'Variable', Var_Id, null, Var_Desc, Var_Desc
            from Variables_Base as Variables
            where PU_Id = @ProductionUnitId and Event_Type = @EventTypeId and Is_Active = 1
        insert into @PropertyItems select 'Variable', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      begin
        insert into @PropertyItems select 'Variable', * from fnSDK_DEI_InsertEmptyList (0)
      end
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
 	 insert into @ValidProperties (PropertyName) values('EventType')
 	 insert into @ValidProperties (PropertyName) values('Variable')
 	 insert into @ValidProperties (PropertyName) values('ResultOn')
 	 insert into @ValidProperties (PropertyName) values('Value')
 	 insert into @ValidProperties (PropertyName) values('CommentText')
 	 insert into @ValidProperties (PropertyName) values('ArrayId')
 	 insert into @ValidProperties (PropertyName) values('EventId')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('Department')
 	 insert into @RequiredProperties (PropertyName) values('ProductionLine')
 	 insert into @RequiredProperties (PropertyName) values('ProductionUnit')
 	 insert into @RequiredProperties (PropertyName) values('Variable')
 	 insert into @RequiredProperties (PropertyName) values('ResultOn')
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
 	 insert into @ValidProperties (PropertyName) values('EntryOn')
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('SecondUsername')
 	 insert into @ValidProperties (PropertyName) values('ESignatureId')
 	 insert into @ValidProperties (PropertyName) values('LCL')
 	 insert into @ValidProperties (PropertyName) values('LEL')
 	 insert into @ValidProperties (PropertyName) values('LRL')
 	 insert into @ValidProperties (PropertyName) values('LUL')
 	 insert into @ValidProperties (PropertyName) values('LWL')
 	 insert into @ValidProperties (PropertyName) values('TCL')
 	 insert into @ValidProperties (PropertyName) values('TGT')
 	 insert into @ValidProperties (PropertyName) values('UCL')
 	 insert into @ValidProperties (PropertyName) values('UEL')
 	 insert into @ValidProperties (PropertyName) values('URL')
 	 insert into @ValidProperties (PropertyName) values('UUL')
 	 insert into @ValidProperties (PropertyName) values('UWL')
 	 insert into @ValidProperties (PropertyName) values('Canceled')
 	 insert into @ValidProperties (PropertyName) values('EventName')
 	 insert into @ValidProperties (PropertyName) values('ShouldArchive')
 	 insert into @ValidProperties (PropertyName) values('TestFrequency')
 	 insert into @ValidProperties (PropertyName) values('TestName')
 	 insert into @ValidProperties (PropertyName) values('ProductCode')
 	 insert into @ValidProperties (PropertyName) values('ProductionPlanId')
 	 insert into @ValidProperties (PropertyName) values('ProductionPlanStartId')
end
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

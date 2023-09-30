CREATE procedure [dbo].[spSDK_DEI_ProductionPlanStartEvent]
 	 @TransactionType int,
 	 @FirstTime bit,
 	 @SDKUserId int,
 	 @DepartmentId int output,
 	 @DepartmentIdChanged bit,
 	 @ProductionLineId int output,
 	 @ProductionLineIdChanged bit,
 	 @ProductionUnitId int output,
 	 @ProductionUnitIdChanged bit,
 	 @PathId int output,
 	 @PathIdChanged bit,
 	 @ProductId int output,
 	 @ProductIdChanged bit,
 	 @ProductionPlanId int output,
 	 @ProductionPlanIdChanged bit,
 	 @ProductionSetupId int output,
 	 @ProductionSetupIdChanged bit,
 	 @UserId int output,
 	 @UserIdChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL real, UEL real, Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @EventType int
set @EventType = 19 -- Process Order ???
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                         '',                         null,         1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'Department',                 'DepartmentId',             null,         1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionLine',             'ProductionLineId',         'Line',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionUnit',             'ProductionUnitId',         'Unit',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'StartTime',                  '',                         'Start Time', 1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'EndTime',                    '',                         'End Time',   1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'IsProduction',               '',                         null,         1, 'bool',     0, null, null, null, null, null
insert into @Properties select 'PathCode',                   'PathId',                   'Path',       1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductCode',                'ProductId',                'Product',    1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProcessOrder',               'ProductionPlanId',         'Order',      1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ProductionSetup',            'ProductionSetupId',        'Setup',      1, 'list',     0, null, null, null, null, null
insert into @Properties select 'PatternCode',                '',                         'Pattern',    1, 'text',     0, null, null, null, null, null
insert into @Properties select 'CommentText',                'CommentId',                'Comment',    1, 'comment',  0, null, null, null, null, null
insert into @Properties select 'Username',                   'UserId',                   'User Name',  1, 'list',     0, null, null, null, null, null
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
  set @PathId = null
  set @PathIdChanged = 1
  set @ProductId = null
  set @ProductIdChanged = 1
end
if ((@PathIdChanged = 1) or (@ProductIdChanged = 1))
begin
  set @ProductionPlanId = null
  set @ProductionPlanIdChanged = 1
end
if (@ProductionUnitIdChanged = 1)
begin
  set @ProductionSetupId = null
  set @ProductionSetupIdChanged = 1
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
if (@FirstTime = 1 or @DepartmentIdChanged = 1 or @ProductionLineIdChanged = 1 or @ProductionUnitIdChanged = 1)
  begin
    insert into @Units (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Order, PU_Desc, group_id, accessLevel, isCurVal)
    Select dept.Dept_Id, dept.Dept_Desc, pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Order, pu.PU_Desc, coalesce(pu.group_id,pl.group_id), @defaultLevel, 0
      from Prod_Units_Base pu
      join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
      join Departments_Base dept on dept.Dept_Id = pl.Dept_Id and dept.Dept_Id > 0
 	     where pu.PU_Id in (select distinct pepu.PU_Id from PrdExec_Path_Units pepu join Production_Plan pp on pp.PP_Id = pepu.Path_Id where pepu.Is_Production_Point = 1)
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
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select 'Username',             User_Id, null, Username, Username from Users where User_Id > 50
    insert into @PropertyItems select 'Username',             * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if (@FirstTime = 1 or @ProductionUnitIdChanged = 1 or @PathIdChanged = 1 or @ProductIdChanged = 1)
  begin
    if (@ProductionUnitId is not null)
      begin
        insert into @PropertyItems
        select 'PathCode', p.Path_Id, null, p.Path_Code, p.Path_Code
          from PrdExec_Paths p
          where p.Path_Id in (select distinct Path_Id from PrdExec_Path_Units where PU_Id = @ProductionUnitId)
        insert into @PropertyItems select 'PathCode', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
        insert into @PropertyItems
          select 'ProductCode', p.Prod_Id, null, p.Prod_Code, p.Prod_Code
            from PU_Products pup
            join Products p on p.Prod_Id = pup.Prod_id
            where pup.PU_Id = @ProductionUnitId and (p.Is_Active_Product is null or p.Is_Active_Product = 1)
        insert into @PropertyItems select 'ProductCode', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
        insert into @PropertyItems
          select 'ProcessOrder', pp.pp_Id, null, pp.Process_Order, pp.Process_Order
            from Production_Plan pp
            join PrdExec_Path_Units pepu on pepu.Path_Id = pp.Path_Id
            where pepu.PU_Id = @ProductionUnitId and
                  ((@ProductId is null) or (pp.Prod_Id = @ProductId)) and
                  ((@PathId is null) or (pp.Path_Id = @PathId))
        insert into @PropertyItems select 'ProcessOrder', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      begin
        insert into @PropertyItems select 'PathCode',     * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'ProductCode',  * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'ProcessOrder', * from fnSDK_DEI_InsertEmptyList (0)
      end
  end
if (@FirstTime = 1 or @ProductionPlanIdChanged = 1)
  begin
    if (@ProductionPlanId is not null)
      begin
        insert into @PropertyItems select 'ProductionSetup', PP_Setup_Id, null, Pattern_Code, Pattern_Code from Production_Setup where PP_Id = @ProductionPlanId
        insert into @PropertyItems select 'ProductionSetup', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      begin
        insert into @PropertyItems select 'ProductionSetup', * from fnSDK_DEI_InsertEmptyList (0)
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
 	 insert into @ValidProperties (PropertyName) values('StartTime')
 	 insert into @ValidProperties (PropertyName) values('EndTime')
 	 insert into @ValidProperties (PropertyName) values('IsProduction')
 	 insert into @ValidProperties (PropertyName) values('PathCode')
 	 insert into @ValidProperties (PropertyName) values('ProductCode')
 	 insert into @ValidProperties (PropertyName) values('ProcessOrder')
 	 insert into @ValidProperties (PropertyName) values('ProductionSetup')
 	 insert into @ValidProperties (PropertyName) values('CommentText')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('Department')
 	 insert into @RequiredProperties (PropertyName) values('ProductionLine')
 	 insert into @RequiredProperties (PropertyName) values('ProductionUnit')
 	 insert into @RequiredProperties (PropertyName) values('StartTime')
 	 insert into @RequiredProperties (PropertyName) values('ProcessOrder')
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
 	 insert into @ValidProperties (PropertyName) values('PatternCode')
end
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

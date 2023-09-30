CREATE procedure [dbo].[spSDK_DEI_GenealogyEvent]
 	 @TransactionType int,
 	 @FirstTime bit,
 	 @SDKUserId int,
 	 @ParentDepartmentId int output,
 	 @ParentDepartmentIdChanged bit,
 	 @ParentProductionLineId int output,
 	 @ParentProductionLineIdChanged bit,
 	 @ParentProductionUnitId int output,
 	 @ParentProductionUnitIdChanged bit,
 	 @ParentEventSubTypeId int output,
 	 @ParentEventSubTypeIdChanged bit,
 	 @ParentEventId int output,
 	 @ParentEventIdChanged bit,
 	 @ChildDepartmentId int output,
 	 @ChildDepartmentIdChanged bit,
 	 @ChildProductionLineId int output,
 	 @ChildProductionLineIdChanged bit,
 	 @ChildProductionUnitId int output,
 	 @ChildProductionUnitIdChanged bit,
 	 @ChildEventSubTypeId int output,
 	 @ChildEventSubTypeIdChanged bit,
 	 @ChildEventId int output,
 	 @ChildEventIdChanged bit,
 	 @PathInputId int output,
 	 @PathInputIdChanged bit,
 	 @UserId int output,
 	 @UserIdChanged bit,
 	 @StartTime datetime output,
 	 @StartTimeChanged bit,
 	 @EndTime datetime output,
 	 @EndTimeChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL real, UEL real, Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @EventType int
declare @Now datetime
set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
set @EventType = 1 -- Production
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                     '',                       null,                    1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'ParentDepartment',       'ParentDepartmentId',     'Parent Department',     1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ParentProductionLine',   'ParentProductionLineId', 'Parent Line',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ParentProductionUnit',   'ParentProductionUnitId', 'Parent Unit',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ParentEventSubType',     'ParentEventSubTypeId',   'Parent Event Sub Type', 1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ParentEvent',            'ParentEventId',          'Parent Event',          1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ChildDepartment',        'ChildDepartmentId',      'Child Department',      1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ChildProductionLine',    'ChildProductionLineId',  'Child Line',            1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ChildProductionUnit',    'ChildProductionUnitId',  'Child Unit',            1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ChildEventSubType',      'ChildEventSubTypeId',    'Child Event Sub Type',  1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ChildEvent',             'ChildEventId',           'Child Event',           1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ParentGenealogyEventId', '',                       null,                    1, 'integer',  0, null, null, null, null, null
insert into @Properties select 'PathInput',              'PathInputId',            'Path',                  1, 'list',     0, null, null, null, null, null
insert into @Properties select 'StartTime',              '',                       'Start Time',            1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'EndTime',                '',                       'End Time',              1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'EntryOn',                '',                       'Entry On',              1, 'datetime', 0, null, null, null, null, null
insert into @Properties select 'Username',               'UserId',                 'User Name',             1, 'list',     0, null, null, null, null, null
insert into @Properties select 'ExtendedInfo',           '',                       null,                    1, 'text',     0, null, null, null, null, null
insert into @Properties select 'ReportAsConsumption',    '',                       null,                    1, 'bool',     0, null, null, null, null, null
insert into @Properties select 'DimensionA',             '',                       'Dim A',                 1, 'float',    0, null, null, null, null, null
insert into @Properties select 'DimensionX',             '',                       'Dim X',                 1, 'float',    0, null, null, null, null, null
insert into @Properties select 'DimensionY',             '',                       'Dim Y',                 1, 'float',    0, null, null, null, null, null
insert into @Properties select 'DimensionZ',             '',                       'Dim Z',                 1, 'float',    0, null, null, null, null, null
insert into @Properties select 'StartCoordinateA',       '',                       'Start Coord A',         1, 'float',    0, null, null, null, null, null
insert into @Properties select 'StartCoordinateX',       '',                       'Start Coord X',         1, 'float',    0, null, null, null, null, null
insert into @Properties select 'StartCoordinateY',       '',                       'Start Coord Y',         1, 'float',    0, null, null, null, null, null
insert into @Properties select 'StartCoordinateZ',       '',                       'Start Coord Z',         1, 'float',    0, null, null, null, null, null
------------------------------------------------------------------------------------------------------------------
-- Force dependant fields to null if their parent has been modified
------------------------------------------------------------------------------------------------------------------
if (@ParentDepartmentIdChanged = 1)
  begin
    set @ParentProductionLineId = null
    set @ParentProductionLineIdChanged = 1
  end
if (@ParentProductionLineIdChanged = 1)
  begin
    set @ParentProductionUnitId = null
    set @ParentProductionUnitIdChanged = 1
  end
if (@ChildDepartmentIdChanged = 1)
  begin
    set @ChildProductionLineId = null
    set @ChildProductionLineIdChanged = 1
  end
if (@ChildProductionLineIdChanged = 1)
  begin
    set @ChildProductionUnitId = null
    set @ChildProductionUnitIdChanged = 1
  end
if (@ParentProductionUnitIdChanged = 1 or @ChildProductionUnitIdChanged = 1)
  begin
    set @PathInputId = null
    set @PathInputIdChanged = 1
  end
if (@PathInputIdChanged = 1)
  begin
 	  	 -- Valid Unit Combos
 	  	 Declare @PEIValues Table (ParentPUId int, ChildPUId int)
 	  	 insert into @PEIValues (ParentPUId, ChildPUId)
      Select pei.PU_Id, peis.PU_Id 
        from PrdExec_Inputs pei
        join PrdExec_Input_Sources peis on peis.pei_id = pei.pei_id
        where (@ParentProductionUnitId is null or pei.PU_Id = @ParentProductionUnitId) and
              (@ChildProductionUnitId is null or peis.PU_Id = @ChildProductionUnitId) and
              (@PathInputId is null or pei.PEI_Id = @PathInputId)
 	  	 if ((@ParentProductionUnitId is not null) and (@ParentProductionUnitId not in (select ParentPUId from @PEIValues)))
      begin
        set @ParentDepartmentId = null
        set @ParentDepartmentIdChanged = 1
        set @ParentProductionLineId = null
        set @ParentProductionLineIdChanged = 1
        set @ParentProductionUnitId = null
        set @ParentProductionUnitIdChanged = 1
      end
 	  	 if ((@ChildProductionUnitId is not null) and (@ChildProductionUnitId not in (select ChildPUId from @PEIValues)))
      begin
        set @ChildDepartmentId = null
        set @ChildDepartmentIdChanged = 1
        set @ChildProductionLineId = null
        set @ChildProductionLineIdChanged = 1
        set @ChildProductionUnitId = null
        set @ChildProductionUnitIdChanged = 1
      end
  end
------------------------------------------------------------------------------------------------------------------
-- Build picking lists
------------------------------------------------------------------------------------------------------------------
Declare @ParentUnits table (Dept_Id int, Dept_Desc nvarchar(100), PL_Id int, PL_Desc nvarchar(100), PU_Id int, PU_Order int, PU_Desc nvarchar(100), group_id int, accessLevel int, isCurVal bit)
Declare @ChildUnits table (Dept_Id int, Dept_Desc nvarchar(100), PL_Id int, PL_Desc nvarchar(100), PU_Id int, PU_Order int, PU_Desc nvarchar(100), group_id int, accessLevel int, isCurVal bit)
Declare @defaultLevel int
Declare @nullGroupIdLevel int
Declare @HasAdminRWLevel int
Set @defaultLevel = 0     --denied
Set @nullGroupIdLevel = 2 --if group_id is null, this is the access level 
Set @HasAdminRWLevel = 0
if (@FirstTime = 1 or
    @ParentDepartmentIdChanged = 1 or @ParentProductionLineIdChanged = 1 or @ParentProductionUnitIdChanged = 1 or
    @ChildDepartmentIdChanged = 1 or @ChildProductionLineIdChanged = 1 or @ChildProductionUnitIdChanged = 1)
  begin
    Select @HasAdminRWLevel=count(*) from user_security where user_id=@SDKUserId and access_Level>=2 and group_id=1
    insert into @ParentUnits (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Order, PU_Desc, group_id, accessLevel, isCurVal)
    Select dept.Dept_Id, dept.Dept_Desc, pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Order, pu.PU_Desc, coalesce(pu.group_id,pl.group_id), @defaultLevel, 0
      from PrdExec_Inputs pei
      join PrdExec_Input_Sources peis on peis.pei_id = pei.pei_id
      join Prod_Units_Base pu on pu.PU_Id = pei.PU_Id
      join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
      join Departments_Base dept on dept.Dept_Id = pl.Dept_Id and dept.Dept_Id > 0
 	     where (@ChildProductionUnitId is null or peis.PU_Id = @ChildProductionUnitId)
 	 update vs set accessLevel=@nullGroupIdLevel
 	 from @ParentUnits vs
 	 where vs.group_id is null
 	 update vs set accessLevel=us.Access_Level
 	 from @ParentUnits vs
 	 join User_Security us  on vs.group_id=us.Group_Id  
 	 where us.User_Id=@SDKUserId
 	 
 	 if @HasAdminRWLevel > 0 
 	 begin
 	  	 update vs set vs.accessLevel = @nullGroupIdLevel  from @ParentUnits vs
 	 end 
 	 update @ParentUnits set isCurVal = 1
 	   where (@ParentDepartmentId = Dept_Id and @ParentProductionLineId = PL_Id and @ParentProductionUnitId = PU_Id)
 	   
 	 delete from @ParentUnits where accessLevel < 2 and isCurVal = 0
    insert into @ChildUnits (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Order, PU_Desc, group_id, accessLevel, isCurVal)
    Select dept.Dept_Id, dept.Dept_Desc, pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Order, pu.PU_Desc, coalesce(pu.group_id,pl.group_id), @defaultLevel, 0
      from PrdExec_Inputs pei
      join PrdExec_Input_Sources peis on peis.pei_id = pei.pei_id
      join Prod_Units_Base pu on pu.PU_Id = peis.PU_Id
      join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
      join Departments_Base dept on dept.Dept_Id = pl.Dept_Id and dept.Dept_Id > 0
 	     where (@ParentProductionUnitId is null or pei.PU_Id = @ParentProductionUnitId)
 	 update vs set accessLevel=@nullGroupIdLevel
 	 from @ChildUnits vs
 	 where vs.group_id is null
 	 update vs set accessLevel=us.Access_Level
 	 from @ChildUnits vs
 	 join User_Security us  on vs.group_id=us.Group_Id  
 	 where us.User_Id=@SDKUserId
 	 
 	 if @HasAdminRWLevel > 0 
 	 begin
 	  	 update vs set vs.accessLevel = @nullGroupIdLevel  from @ChildUnits vs
 	 end 
 	 update @ChildUnits set isCurVal = 1
 	   where (@ChildDepartmentId = Dept_Id and @ChildProductionLineId = PL_Id and @ChildProductionUnitId = PU_Id)
 	   
 	 delete from @ChildUnits where accessLevel < 2 and isCurVal = 0
    insert into @PropertyItems select distinct 'ParentDepartment', Dept_Id, null, Dept_Desc, Dept_Desc from @ParentUnits where Dept_Id > 0
    insert into @PropertyItems select 'ParentDepartment', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
    if (@ParentDepartmentId is not null)
      begin
        insert into @PropertyItems select distinct 'ParentProductionLine', PL_Id, null, PL_Desc, PL_Desc from @ParentUnits where Dept_Id = @ParentDepartmentId
        insert into @PropertyItems select 'ParentProductionLine', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ParentProductionLine', * from fnSDK_DEI_InsertEmptyList (0)
    if (@ParentProductionLineId is not null)
      begin
        insert into @PropertyItems select distinct 'ParentProductionUnit', PU_Id, PU_Order, PU_Desc, PU_Desc from @ParentUnits where PL_Id = @ParentProductionLineId
        insert into @PropertyItems select 'ParentProductionUnit', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ParentProductionUnit', * from fnSDK_DEI_InsertEmptyList (0)
    insert into @PropertyItems select distinct 'ChildDepartment', Dept_Id, null, Dept_Desc, Dept_Desc from @ChildUnits where Dept_Id > 0
    insert into @PropertyItems select 'ChildDepartment', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
    if (@ChildDepartmentId is not null)
      begin
        insert into @PropertyItems select distinct 'ChildProductionLine', PL_Id, null, PL_Desc, PL_Desc from @ChildUnits where Dept_Id = @ChildDepartmentId
        insert into @PropertyItems select 'ChildProductionLine', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end 	 
    else
      insert into @PropertyItems select 'ChildProductionLine', * from fnSDK_DEI_InsertEmptyList (0)
    if (@ChildProductionLineId is not null)
      begin
        insert into @PropertyItems select distinct 'ChildProductionUnit', PU_Id, PU_Order, PU_Desc, PU_Desc from @ChildUnits where PL_Id = @ChildProductionLineId
        insert into @PropertyItems select 'ChildProductionUnit', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ChildProductionUnit', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @ParentProductionUnitIdChanged = 1 or @ChildProductionUnitIdChanged = 1)
  begin
    if ((@ParentProductionUnitId is not null) or (@ChildProductionUnitId is not null))
      begin
        insert into @PropertyItems
          select 'PathInput', pei.PEI_Id, pei.Input_Order, pei.Input_Name, pei.Input_Name
            from PrdExec_Inputs pei
            join PrdExec_Input_Sources peis on peis.pei_id = pei.pei_id
 	           where (@ParentProductionUnitId is null or pei.PU_Id = @ParentProductionUnitId) and
                  (@ChildProductionUnitId is null or peis.PU_Id = @ChildProductionUnitId)
        insert into @PropertyItems select 'PathInput', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'PathInput', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @ChildProductionUnitIdChanged = 1)
  begin
    if (@ChildProductionUnitId is not null)
      begin
        insert into @PropertyItems
          select 'ChildEventSubType', es.Event_Subtype_Id, null, es.Event_Subtype_Desc, es.Event_Subtype_Desc
            from Event_Configuration ec
            join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
            where ec.ET_Id = @EventType and ec.PU_Id = @ChildProductionUnitId and ec.is_Active = 1
        insert into @PropertyItems select 'ChildEventSubType', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ChildEventSubType', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @ParentProductionUnitIdChanged = 1)
  begin
    if (@ParentProductionUnitId is not null)
      begin
        insert into @PropertyItems
          select 'ParentEventSubType', es.Event_Subtype_Id, null, es.Event_Subtype_Desc, es.Event_Subtype_Desc
            from Event_Configuration ec
            join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
            where ec.ET_Id = @EventType and ec.PU_Id = @ParentProductionUnitId and ec.is_Active = 1
        insert into @PropertyItems select 'ParentEventSubType', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ParentEventSubType', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select 'Username', User_Id, null, Username, Username from Users where User_Id > 50
    insert into @PropertyItems select 'Username', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if (@FirstTime = 1 or @PathInputIdChanged = 1 or @StartTimeChanged = 1 or @EndTimeChanged = 1 or @ParentProductionUnitIdChanged = 1 or @ParentEventSubTypeIdChanged = 1)
  begin
    if ((@ParentProductionUnitId is not null) and (@ParentEventSubTypeId is not null))
      begin
        insert into @PropertyItems select 'ParentEvent', * from fnSDK_DEI_GetRelatedEventItems(@PathInputId, @StartTime, @EndTime, @ParentProductionUnitId, null, @ParentProductionUnitId, @ParentEventSubTypeId)
        insert into @PropertyItems select 'ParentEvent', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ParentEvent', * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @PathInputIdChanged = 1 or @StartTimeChanged = 1 or @EndTimeChanged = 1 or @ParentProductionUnitIdChanged = 1 or @ParentEventIdChanged = 1 or @ChildProductionUnitIdChanged = 1 or @ChildEventSubTypeIdChanged = 1)
  begin
    if ((@ChildProductionUnitId is not null) and (@ChildEventSubTypeId is not null))
      begin
        insert into @PropertyItems select 'ChildEvent', * from fnSDK_DEI_GetRelatedEventItems(@PathInputId, @StartTime, @EndTime, @ParentProductionUnitId, @ParentEventId, @ChildProductionUnitId, @ChildEventSubTypeId)
        insert into @PropertyItems select 'ChildEvent', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'ChildEvent', * from fnSDK_DEI_InsertEmptyList (0)
  end
------------------------------------------------------------------------------------------------------------------
-- Clean up properties for transactions
------------------------------------------------------------------------------------------------------------------
Declare @RequiredProperties table(PropertyName nvarchar(100))
Declare @ValidProperties table(PropertyName nvarchar(100))
Declare @DisabledProperties table(PropertyName nvarchar(100))
if (@TransactionType <> 2) -- Not Delete
begin
 	 insert into @ValidProperties (PropertyName) values('ChildDepartment')
 	 insert into @ValidProperties (PropertyName) values('ChildProductionLine')
 	 insert into @ValidProperties (PropertyName) values('ChildProductionUnit')
 	 insert into @ValidProperties (PropertyName) values('ChildEventSubType')
 	 insert into @ValidProperties (PropertyName) values('ChildEvent')
 	 insert into @ValidProperties (PropertyName) values('ParentDepartment')
 	 insert into @ValidProperties (PropertyName) values('ParentProductionLine')
 	 insert into @ValidProperties (PropertyName) values('ParentProductionUnit')
 	 insert into @ValidProperties (PropertyName) values('ParentEventSubType')
 	 insert into @ValidProperties (PropertyName) values('ParentEvent')
 	 insert into @ValidProperties (PropertyName) values('ParentGenealogyEventId')
 	 insert into @ValidProperties (PropertyName) values('PathInput')
 	 insert into @ValidProperties (PropertyName) values('StartTime')
 	 insert into @ValidProperties (PropertyName) values('EndTime')
 	 insert into @ValidProperties (PropertyName) values('ExtendedInfo')
 	 insert into @ValidProperties (PropertyName) values('ReportAsConsumption')
 	 insert into @ValidProperties (PropertyName) values('DimensionA')
 	 insert into @ValidProperties (PropertyName) values('DimensionX')
 	 insert into @ValidProperties (PropertyName) values('DimensionY')
 	 insert into @ValidProperties (PropertyName) values('DimensionZ')
 	 insert into @ValidProperties (PropertyName) values('StartCoordinateA')
 	 insert into @ValidProperties (PropertyName) values('StartCoordinateX')
 	 insert into @ValidProperties (PropertyName) values('StartCoordinateY')
 	 insert into @ValidProperties (PropertyName) values('StartCoordinateZ')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('ChildEvent')
 	 insert into @RequiredProperties (PropertyName) values('ParentEvent')
 	 insert into @RequiredProperties (PropertyName) values('StartTime')
 	 insert into @RequiredProperties (PropertyName) values('EndTime')
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
end
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

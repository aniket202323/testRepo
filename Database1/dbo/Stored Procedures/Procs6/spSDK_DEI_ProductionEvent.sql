CREATE procedure [dbo].[spSDK_DEI_ProductionEvent]
 	 @TransactionType int,
 	 @FirstTime bit,
 	 @SDKUserId int,
 	 @DepartmentId int output,
 	 @DepartmentIdChanged bit,
 	 @ProductionLineId int output,
 	 @ProductionLineIdChanged bit,
 	 @ProductionUnitId int output,
 	 @ProductionUnitIdChanged bit,
 	 @UserId int output,
 	 @UserIdChanged bit,
 	 @EntryById int output,
 	 @EntryByIdChanged bit,
 	 @SecondUserId int output,
 	 @SecondUserIdChanged bit,
 	 @EventSubTypeId int output,
 	 @EventSubTypeIdChanged bit,
 	 @OriginalProductId int output,
 	 @OriginalProductIdChanged bit,
 	 @AppliedProductId int output,
 	 @AppliedProductIdChanged bit,
 	 @ProductionStatusId int output,
 	 @ProductionStatusIdChanged bit,
 	 @TestingStatusId int output,
 	 @TestingStatusIdChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL nvarchar(100), UEL nvarchar(100), Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100),DefaultValue nVarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @EventType int
DECLARE @EventTypeDesc VarChar(100)
DECLARE @ChainStartTime Int
DECLARE @MaxOffset 	  	 INT
DECLARE @NewEndTime DateTime
SELECT @MaxOffset =  CONVERT(INT, Value) From User_Parameters Where User_Id = 6 and Parm_Id = 85
SELECT @MaxOffset = coalesce(@MaxOffset,0)
SET @NewEndTime = DateAdd(hour,12,GETUTCDATE())
IF @MaxOffset > 0
BEGIN
  SELECT  @NewEndTime =  DateAdd(Hour,@MaxOffset,dbo.fnServer_CmnGetDate(getUTCdate()))
END
set @EventType = 1 -- Production
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                         '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'Department',                 'DepartmentId',             null,                  1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionLine',             'ProductionLineId',         'Line',                1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionUnit',             'ProductionUnitId',         'Unit',                1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'EventName',                  '',                         'Event',               1, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'StartTime',                  '',                         'Start Time',          1, 'datetime', 0,  Convert(VarChar(25),DateAdd(Month,-1,GETUTCDATE()),120),  Convert(VarChar(25),@NewEndTime,120), null, null, null,Convert(VarChar(25),DateAdd(Minute,-10,GETUTCDATE()),120)
insert into @Properties select 'EndTime',                    '',                         'End Time',            1, 'datetime', 0,  Convert(VarChar(25),DateAdd(Month,-1,GETUTCDATE()),120),  Convert(VarChar(25),@NewEndTime,120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'EntryOn',                    '',                         'Entry On',            0, 'datetime', 0, null, null, null, null, null,null
insert into @Properties select 'DetailEntryOn',              '',                         null,                  1, 'datetime', 0, null, null, null, null, null,null
insert into @Properties select 'CommentText',                'CommentId',                'Comment',             1, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'DetailCommentText',          'DetailCommentId',          'Detail Comment',      1, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'Username',                   '', 	  	  	  	  	  	  'User Name',           0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'EntryBy',                    'EntryById',                'Entry By',            1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'SecondUsername',             'SecondUserId',             null,                  1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'EventSubType',               'EventSubTypeId',           'Event Sub Type',      0, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProcessOrder',               '', 	  	  	  	  	  	  'Order',               0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'OriginalProductCode',        '', 	  	  	  	  	  	  'Product',             0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'AppliedProductCode',         'AppliedProductId',         'Applied Product',     1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionStatus',           'ProductionStatusId',       'Status',              1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'TestingStatus',              '', 	  	  	  	  	  	  'Testing Status',      0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'TestPercentComplete',        '',                         'Test % Complete',     0, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'InitialDimensionA',          '',                         'Initial Dimension A', 0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'InitialDimensionX',          '',                         'Initial Dimension X', 0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'InitialDimensionY',          '',                         'Initial Dimension Y', 0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'InitialDimensionZ',          '',                         'Initial Dimension Z', 0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'FinalDimensionA',            '',                         'Final Dimension A',   0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'FinalDimensionX',            '',                         'Final Dimension X',   0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'FinalDimensionY',            '',                         'Final Dimension Y',   0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'FinalDimensionZ',            '',                         'Final Dimension Z',   0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'OrientationX',               '',                         null,                  0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'OrientationY',               '',                         null,                  0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'OrientationZ',               '',                         null,                  0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'ApproverUserId',             '',                         null,                  0, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ApprovedReasonId',           '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ProductionSetupDetail',      'ProductionSetupDetailId',  null,                  1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'UserReasonId',               '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'UserSignOffId',              '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'AlternateEventName',         '',                         'Alt Event Name',      1, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'Conformance',                '',                         null,                  0, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'CustomerOrderId',            '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'CustomerOrderLineId',        '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ShipmentId',                 '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'SourceEventId',              '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ProductionPlanId',           '',                         null,                  0, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ProductionSetupDetailId',    '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ExtendedInfo',               '',                         null,                  1, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'ESignatureId',               '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'DetailESignatureId',         '',                         null,                  1, 'integer',  0, null, null, null, null, null,null
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
  set @OriginalProductId = null
  set @OriginalProductIdChanged = 1
  set @AppliedProductId = null
  set @AppliedProductIdChanged = 1
  set @EventSubTypeId = null
  set @EventSubTypeIdChanged = 1
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
        join Event_Configuration ec on ec.PU_Id = pu.PU_Id AND ec.ET_Id = @EventType
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
SET @ChainStartTime = 1
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select 'SecondUsername',   User_Id, null, Username, Username from Users where User_Id > 50
    insert into @PropertyItems select 'SecondUsername',   * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
    insert into @PropertyItems select 'ProductionStatus', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if  @TransactionType = 0 AND @ProductionStatusId Is NUll
BEGIN
 	 IF @ProductionUnitId Is Not Null
 	  	 SELECT  @ProductionStatusId = MIN(Valid_Status)
 	  	  	 FROM PrdExec_Status a
 	  	  	 WHERE Is_Default_Status = 1 AND a.PU_Id = @ProductionUnitId
 	 IF @ProductionStatusId Is Null 
 	  	 SET @ProductionStatusId = 5
 	 SET @ProductionStatusIdChanged = 1
 	 UPDATE @Properties SET DefaultValue = @ProductionStatusId WHERE PropertyName = 'ProductionStatus'
END
IF @ProductionUnitId IS NOT NULL
BEGIN
 	 SELECT @EventSubTypeId = ec.Event_Subtype_Id
 	  	 FROM Event_Configuration ec
 	  	 WHERE ec.ET_Id = @EventType and ec.PU_Id = @ProductionUnitId
 	  	 
 	 SELECT @ChainStartTime=a.Chain_Start_Time from Prod_Units_Base a where a.PU_Id = @ProductionUnitId
 	 DECLARE @PrevEndTime DateTime
 	 SELECT @PrevEndTime = Max(TimeStamp) From Events WHERE PU_Id = @ProductionUnitId And TimeStamp < dbo.fnServer_CmnGetDate(getUTCdate())
 	 IF @PrevEndTime Is Not Null
 	  	 UPDATE @Properties SET DefaultValue = Convert(VarChar(25),@PrevEndTime,120) WHERE PropertyName = 'StartTime'
END
if (@FirstTime = 1 or @ProductionUnitIdChanged = 1)
  begin
    if (@ProductionUnitId is not null)
      begin
        insert into @PropertyItems
          select 'AppliedProductCode', p.Prod_Id, null, p.Prod_Code, p.Prod_Code
            from PU_Products pup
            join Products p on p.Prod_Id = pup.Prod_id
            where pup.PU_Id = @ProductionUnitId and (p.Is_Active_Product is null or p.Is_Active_Product = 1)
        insert into @PropertyItems select 'AppliedProductCode', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
        insert into @PropertyItems
          select 'EventSubType', es.Event_Subtype_Id, null, es.Event_Subtype_Desc, es.Event_Subtype_Desc
            from Event_Configuration ec
            join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
            where ec.ET_Id = @EventType and ec.PU_Id = @ProductionUnitId --and ec.is_Active = 1
        insert into @PropertyItems select 'EventSubType', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	  	 insert into @PropertyItems 
 	  	  	 select DISTINCT 'ProductionStatus', ProdStatus_Id, null, ProdStatus_Desc, ProdStatus_Desc 
 	  	  	 from Production_Status a
 	  	  	 JOIN PrdExec_Status b on b.Valid_Status = a.ProdStatus_Id
 	  	  	 WHERE b.PU_Id = @ProductionUnitId
 	  	 IF @@ROWCOUNT = 0
 	  	 BEGIN
 	  	  	 insert into @PropertyItems 
 	  	  	  	 select DISTINCT 'ProductionStatus', ProdStatus_Id, null, ProdStatus_Desc, ProdStatus_Desc 
 	  	  	  	 from Production_Status a
 	  	 END
      end
    else
      begin
        insert into @PropertyItems select 'AppliedProductCode',  * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'EventSubType',        * from fnSDK_DEI_InsertEmptyList (0)
      end
  end
if (@EventSubTypeId is not null)
  begin
    declare @DimXEna tinyint, @DimYEna tinyint, @DimZEna tinyint, @DimAEna tinyint
    declare @DimXName nvarchar(100), @DimYName nvarchar(100), @DimZName nvarchar(100), @DimAName nvarchar(100)
 	 declare @DimXUnit nvarchar(100), @DimYUnit nvarchar(100), @DimZUnit nvarchar(100), @DimAUnit nvarchar(100)
    select @DimXEna = 1,                   @DimXName = Dimension_X_Name, @DimXUnit = Dimension_X_Eng_Units,
           @DimYEna = Dimension_Y_Enabled, @DimYName = Dimension_Y_Name, @DimYUnit = Dimension_Y_Eng_Units,
           @DimZEna = Dimension_Z_Enabled, @DimZName = Dimension_Z_Name, @DimZUnit = Dimension_Z_Eng_Units,
           @DimAEna = Dimension_A_Enabled, @DimAName = Dimension_A_Name, @DimAUnit = Dimension_A_Eng_Units,
           @EventTypeDesc = Event_Subtype_Desc 
      from Event_Subtypes
      where Event_Subtype_Id = @EventSubTypeId
    UPDATE @Properties Set PropertyDisplayName = @EventTypeDesc WHERE PropertyName = 'EventName'
 	 IF @DimXEna = 1
 	 BEGIN
 	  	 update @Properties set PropertyDisplayName = 'Initial ' + @DimXName, EngUnits = @DimXUnit where PropertyName = 'InitialDimensionX'
 	  	 update @Properties set IsEnabled = 1, PropertyDisplayName = 'Final ' + @DimXName, EngUnits = @DimXUnit where PropertyName = 'FinalDimensionX'
 	 END
 	 IF  @DimYEna = 1
 	 BEGIN
 	  	 update @Properties set IsEnabled = 0, PropertyDisplayName = 'Initial ' + @DimYName, EngUnits = @DimYUnit where PropertyName = 'InitialDimensionY'
 	  	 update @Properties set IsEnabled = 1, PropertyDisplayName = 'Final ' + @DimYName, EngUnits = @DimYUnit where PropertyName = 'FinalDimensionY'
 	 END
    IF @DimZEna = 1
 	 BEGIN
 	  	 update @Properties set IsEnabled = 0, PropertyDisplayName = 'Initial ' + @DimZName, EngUnits = @DimZUnit where PropertyName = 'InitialDimensionZ'
 	  	 update @Properties set IsEnabled = 1, PropertyDisplayName = 'Final ' + @DimZName, EngUnits = @DimZUnit where PropertyName = 'FinalDimensionZ'
 	 END
    IF @DimAEna = 1
 	 BEGIN
 	  	 update @Properties set IsEnabled = 0, PropertyDisplayName = 'Initial ' + @DimAName, EngUnits = @DimAUnit where PropertyName = 'InitialDimensionA'
 	  	 update @Properties set IsEnabled = 1, PropertyDisplayName = 'Final ' + @DimAName, EngUnits = @DimAUnit where PropertyName = 'FinalDimensionA'
 	 END
  end
else
  begin
    update @Properties set IsEnabled = 0 where PropertyName like '%Dimension%'
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
 	 insert into @ValidProperties (PropertyName) values('EventName')
 	 insert into @ValidProperties (PropertyName) values('StartTime')
 	 insert into @ValidProperties (PropertyName) values('EndTime')
 	 insert into @ValidProperties (PropertyName) values('ProductionStatus')
 	 insert into @ValidProperties (PropertyName) values('OriginalProductCode')
 	 insert into @ValidProperties (PropertyName) values('AppliedProductCode')
 	 insert into @ValidProperties (PropertyName) values('AlternateEventName')
 	 insert into @ValidProperties (PropertyName) values('EntryOn')
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('CommentText')
 	 insert into @ValidProperties (PropertyName) values('InitialDimensionX')
 	 insert into @ValidProperties (PropertyName) values('FinalDimensionX')
 	 insert into @ValidProperties (PropertyName) values('InitialDimensionY')
 	 insert into @ValidProperties (PropertyName) values('FinalDimensionY')
 	 insert into @ValidProperties (PropertyName) values('InitialDimensionZ')
 	 insert into @ValidProperties (PropertyName) values('FinalDimensionZ')
 	 insert into @ValidProperties (PropertyName) values('InitialDimensionA')
 	 insert into @ValidProperties (PropertyName) values('FinalDimensionA')
 	 insert into @ValidProperties (PropertyName) values('TestingStatus')
 	 insert into @ValidProperties (PropertyName) values('TestPercentComplete')
 	 insert into @ValidProperties (PropertyName) values('OrientationX')
 	 insert into @ValidProperties (PropertyName) values('OrientationY')
 	 insert into @ValidProperties (PropertyName) values('OrientationZ')
 	 insert into @ValidProperties (PropertyName) values('Conformance')
 	 insert into @ValidProperties (PropertyName) values('CustomerOrderId')
 	 insert into @ValidProperties (PropertyName) values('CustomerOrderLineId')
 	 insert into @ValidProperties (PropertyName) values('ShipmentId')
 	 insert into @ValidProperties (PropertyName) values('ProcessOrder')
 	 insert into @ValidProperties (PropertyName) values('ProductionSetupDetailId')
 	 insert into @ValidProperties (PropertyName) values('ExtendedInfo')
 	 
 	 insert into @ValidProperties (PropertyName) values('DetailCommentText')
 	 
 	 insert into @ValidProperties (PropertyName) values('EventSubType')
 	 insert into @ValidProperties (PropertyName) values('SourceEventId')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('Department')
 	 insert into @RequiredProperties (PropertyName) values('ProductionLine')
 	 insert into @RequiredProperties (PropertyName) values('ProductionUnit')
 	 insert into @RequiredProperties (PropertyName) values('EventName')
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
 	 insert into @ValidProperties (PropertyName) values('EntryOn')
 	 insert into @ValidProperties (PropertyName) values('DetailEntryOn')
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('EntryBy')
 	 insert into @ValidProperties (PropertyName) values('SecondUsername')
 	 insert into @ValidProperties (PropertyName) values('ESignatureId')
 	 insert into @ValidProperties (PropertyName) values('DetailESignatureId')
 	 insert into @ValidProperties (PropertyName) values('OriginalProductCode')
 	 insert into @ValidProperties (PropertyName) values('ApproverUserId')
 	 insert into @ValidProperties (PropertyName) values('ApprovedReasonId')
 	 insert into @ValidProperties (PropertyName) values('UserReasonId')
 	 insert into @ValidProperties (PropertyName) values('UserSignOffId')
end
IF @ChainStartTime is NOT Null AND @ChainStartTime = 0
BEGIN
 	 INSERT INTO @RequiredProperties(PropertyName) VALUES ('StartTime')
END
ELSE
BEGIN
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('StartTime')
END
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits,DefaultValue from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

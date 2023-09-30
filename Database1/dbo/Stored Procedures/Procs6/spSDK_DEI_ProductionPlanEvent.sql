CREATE procedure [dbo].[spSDK_DEI_ProductionPlanEvent]
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
 	 @BOMFormulationId int output,
 	 @BOMFormulationIdChanged bit,
 	 @ControlTypeId int output,
 	 @ControlTypeIdChanged bit,
 	 @PathId int output,
 	 @PathIdChanged bit,
 	 @ProductId int output,
 	 @ProductIdChanged bit,
 	 @ProductionPlanStatusId int output,
 	 @ProductionPlanStatusIdChanged bit,
 	 @ProductionPlanTypeId int output,
 	 @ProductionPlanTypeIdChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL nvarchar(100), UEL nvarchar(100), Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100),DefaultValue nVarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @EventType int
set @EventType = 19 -- Process Order
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                         '',                         null,                 1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'ProcessOrder',               '',                         'Process Order',      1, 'text',     0, null, null, null, null, null, null
insert into @Properties select 'PathCode', 	  	  	  	  	  'PathId',                   'Path',               1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'ProductionPlanStatus', 	  	  'ProductionPlanStatusId',   'Status',             1, 'list',     0, null, null, null, null, null, '1'
insert into @Properties select 'ProductCode', 	  	  	  	  'ProductId',                'Product',            1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'BOMFormulation',             'BOMFormulationId',         'BOM',                1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'BlockNumber',                '',                         'Block Number',       1, 'text',     0, null, null, null, null, null, null
insert into @Properties select 'ExtendedInfo',               '',                         'Extended Info',      1, 'text',     0, null, null, null, null, null, null
insert into @Properties select 'ControlType',                'ControlTypeId',            'Control Type',       1, 'list',     0, null, null, null, null, null, '2'
insert into @Properties select 'ParentProcessOrder', 	  	  '', 	  	  	  	  	  	  'Parent Order',       1, 'text',  0, null, null, null, null, null, null
insert into @Properties select 'ParentPathCode',             '', 	  	  	  	  	  	  'Parent Path',        1, 'text',  0, null, null, null, null, null, null
insert into @Properties select 'ProductionPlanType', 	  	  'ProductionPlanTypeId',     'Plan Type',          1, 'list',     0, null, null, null, null, null, '1'
insert into @Properties select 'SourcePathCode',             '', 	  	  	  	  	  	  'Source Path',        1, 'text',  0, null, null, null, null, null, null
insert into @Properties select 'SourceProcessOrder', 	  	  '', 	  	  	  	  	  	  'Source Order',       1, 'text',  0, null, null, null, null, null, null
insert into @Properties select 'ForecastStartTime',          '',                         'Forecast Start',     1, 'datetime', 0, Convert(VarChar(25),DateAdd(Month,0,GETUTCDATE()),120),  Convert(VarChar(25),DateAdd(Month,12,GETUTCDATE()),120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'ForecastEndTime',            '',                         'Forecast End',       1, 'datetime', 0,  Convert(VarChar(25),DateAdd(Month,0,GETUTCDATE()),120),  Convert(VarChar(25),DateAdd(Month,12,GETUTCDATE()),120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'ForecastQuantity',           '',                         'Forecast Quantity',  1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'CommentText',                'CommentId',                'Comment',            1, 'comment',  0, null, null, null, null, null, null
insert into @Properties select 'UserGeneral1',               '',                         'User General 1',     1, 'text',     0, null, null, null, null, null, null
insert into @Properties select 'UserGeneral2',               '',                         'User General 2',     1, 'text',     0, null, null, null, null, null, null
insert into @Properties select 'UserGeneral3',               '',                         'User General 3',     1, 'text',     0, null, null, null, null, null, null
insert into @Properties select 'PredictedRemainingDuration', '',                         'Remaining Duration', 1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'PredictedRemainingQuantity', '',                         'Remaining Quantity', 1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'PredictedTotalDuration',     '',                         'Total Duration',     1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'StartTime',                  '',                         'Start Time',         1, 'datetime', 0, null, null, null, null, null, null
insert into @Properties select 'EndTime',                    '',                         'End Time',           1, 'datetime', 0, null, null, null, null, null, null
insert into @Properties select 'EntryOn',                    '',                         'Entry On',           1, 'datetime', 0, null, null, null, null, null, null
insert into @Properties select 'Username',                   'UserId',                   'User Name',          1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'ActualGoodItems',            '',                         'Good Items',         1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'ActualGoodQuantity',         '',                         'Good Quantity',      1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'ActualBadItems',             '',                         'Bad Items',          1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'ActualBadQuantity',          '',                         'Bad Quantity',       1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'ActualDownTime',             '',                         'DownTime',           1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'ActualRepetitions',          '',                         'Repetitions',        1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'ActualRunningTime',          '',                         'Running Time',       1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'LateItems',                  '',                         'Late Items',         1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'AlarmCount',                 '',                         'Alarms',             1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'AdjustedQuantity',           '',                         'Adjusted Quantity',  1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'ProductionRate',             '',                         'Production Rate',    1, 'float',    0, null, null, null, null, null, null
insert into @Properties select 'ImpliedSequence',            '',                         'Implied Sequence',   1, 'integer',  0, null, null, null, null, null, null
/* Not used in current UI*/
insert into @Properties select 'Department',                 'DepartmentId',             null,                 1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'ProductionLine',             'ProductionLineId',         'Line',               1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'ProductionUnit',             'ProductionUnitId',         'Unit',               1, 'list',     0, null, null, null, null, null, null
insert into @Properties select 'ParentPathId',               '',                         null,                 1, 'integer',  0, null, null, null, null, null, null
insert into @Properties select 'SourcePathId',               '',                         null,                 1, 'integer',  0, null, null, null, null, null, null
------------------------------------------------------------------------------------------------------------------
-- Force dependant fields to null if their parent has been modified
------------------------------------------------------------------------------------------------------------------
--if (@DepartmentIdChanged = 1)
--begin
--  set @ProductionLineId = null
--  set @ProductionLineIdChanged = 1
--end
--if (@ProductionLineIdChanged = 1)
--begin
--  set @ProductionUnitId = null
--  set @ProductionUnitIdChanged = 1
--end
--if (@ProductionUnitIdChanged = 1)
--begin
--  set @PathId = null
--  set @PathIdChanged = 1
--  set @ProductId = null
--  set @ProductIdChanged = 1
--end
--Select @PathIdChanged,@ProductionUnitIdChanged
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
IF @FirstTime = 1 or  @DepartmentIdChanged = 1 or @ProductionLineIdChanged = 1 or @ProductionUnitIdChanged = 1
BEGIN
    insert into @Units (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Order, PU_Desc, group_id, accessLevel, isCurVal)
    Select dept.Dept_Id, dept.Dept_Desc, pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Order, pu.PU_Desc, coalesce(pu.group_id,pl.group_id), @defaultLevel, 0
      from Prod_Units_Base pu
      join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
      join Departments_Base dept on dept.Dept_Id = pl.Dept_Id and dept.Dept_Id > 0
 	     where pu.PU_Id in (select distinct PU_Id from PrdExec_Path_Units)
 	     
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
END
IF @FirstTime = 1 and @TransactionType = 0
BEGIN
 	 SET @ProductionPlanStatusId = 1
 	 SET @ProductionPlanStatusIdChanged = 1
 	 SET @ControlTypeId = 2
 	 SET @ControlTypeIdChanged = 1
 	 SET @ProductionPlanTypeId = 1
 	 SET @ProductionPlanTypeIdChanged = 1
END
IF @TransactionType != 0
BEGIN 
    insert into @PropertyItems
 	  	 select 'PathCode', p.Path_Id, null, p.Path_Code, p.Path_Code
 	  	   from PrdExec_Paths p
 	  	   where p.Path_Id  = @PathId
 	 insert into @PropertyItems select 'PathCode',    * from fnSDK_DEI_InsertEmptyList (0)
 	 INSERT into @PropertyItems 
 	  	 select 'ProductionPlanStatus', PP_Status_Id, null, PP_Status_Desc, PP_Status_Desc 
 	  	  	 from Production_Plan_Statuses
 	  	  	 WHERE PP_Status_Id  = @ProductionPlanStatusId
 	 INSERT into @PropertyItems 
 	  	  	 select 'ControlType',Control_Type_Id, null, Control_Type_Desc, Control_Type_Desc 
 	  	  	 from Control_Type
 	  	  	 WHERE Control_Type_Id = @ControlTypeId
 	 insert into @PropertyItems 
 	  	 select 'BOMFormulation',       BOM_Formulation_Id, null, BOM_Formulation_Code, 
 	  	  	 BOM_Formulation_Code 
 	  	 from Bill_Of_Material_Formulation
 	  	 WHERE BOM_Formulation_Id = @BOMFormulationId
 	 insert into @PropertyItems 
 	  	 select 'BOMFormulation', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 insert into @PropertyItems 
 	  	 select 'ProductionPlanType',   PP_Type_Id, null, PP_Type_Name, PP_Type_Name 
 	  	  	 from Production_Plan_Types
 	  	  	 where PP_Type_Id = @ProductionPlanTypeId
    insert into @PropertyItems
      select 'ProductCode', p.Prod_Id, null, p.Prod_Code, p.Prod_Code
        From Products p 
        where p.Prod_Id  = @ProductId 
END
ELSE
BEGIN
    insert into @PropertyItems
 	  	 select Distinct 'PathCode', p.Path_Id, null, p.Path_Code, p.Path_Code
 	  	   from PrdExec_Paths p
 	  	   JOIN PrdExec_Path_Units a  ON a.Path_Id = p.Path_Id
 	 INSERT into @PropertyItems 
 	  	 SELECT 'ProductionPlanStatus', PP_Status_Id, null, PP_Status_Desc, PP_Status_Desc 
 	  	  	 FROM Production_Plan_Statuses
 	  	  	 WHERE PP_Status_Id in (1,7)
 	 INSERT into @PropertyItems 
 	  	  	 select 'ControlType',Control_Type_Id, null, Control_Type_Desc, Control_Type_Desc 
 	  	  	 from Control_Type
 	 insert into @PropertyItems 
 	  	 select 'BOMFormulation',       BOM_Formulation_Id, null, BOM_Formulation_Code, 
 	  	  	 BOM_Formulation_Code 
 	  	 from Bill_Of_Material_Formulation
 	 insert into @PropertyItems 
 	  	 select 'BOMFormulation', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 insert into @PropertyItems 
 	  	 select 'ProductionPlanType',   PP_Type_Id, null, PP_Type_Name, PP_Type_Name 
 	  	  	 from Production_Plan_Types
 	  	  	 where PP_Type_Id = 1
    insert into @PropertyItems -- Start with empty list
 	  	 select 'ProductCode', * from fnSDK_DEI_InsertEmptyList (0)
END
if (@PathIdChanged = 1 or @PathId is not null) and @TransactionType = 0  
  begin
        insert into @PropertyItems
          select 'ProductCode', p.Prod_Id, null, p.Prod_Code, p.Prod_Code
            from PrdExec_Path_Products pup
            join Products p on p.Prod_Id = pup.Prod_id
            where pup.Path_Id = @PathId and (p.Is_Active_Product is null or p.Is_Active_Product = 1)
  end
------------------------------------------------------------------------------------------------------------------
-- Clean up properties for transactions
------------------------------------------------------------------------------------------------------------------
Declare @RequiredProperties table(PropertyName nvarchar(100))
Declare @ValidProperties table(PropertyName nvarchar(100))
Declare @DisabledProperties table(PropertyName nvarchar(100))
if @TransactionType in (0,1,3) -- Add/Update/Query
BEGIN
 	 insert into @ValidProperties (PropertyName) values('ProcessOrder')
 	 insert into @ValidProperties (PropertyName) values('PathCode')
 	 insert into @ValidProperties (PropertyName) values('ProductionPlanStatus')
 	 insert into @ValidProperties (PropertyName) values('ProductCode')
 	 insert into @ValidProperties (PropertyName) values('ForecastStartTime')
 	 insert into @ValidProperties (PropertyName) values('ForecastEndTime')
 	 insert into @ValidProperties (PropertyName) values('ForecastQuantity')
 	 
 	 insert into @ValidProperties (PropertyName) values('BlockNumber')
 	 insert into @ValidProperties (PropertyName) values('ExtendedInfo')
 	 insert into @ValidProperties (PropertyName) values('ControlType')
 	 insert into @ValidProperties (PropertyName) values('ParentProcessOrder')
 	 insert into @ValidProperties (PropertyName) values('ParentPathCode')
 	 insert into @ValidProperties (PropertyName) values('ProductionPlanType')
 	 insert into @ValidProperties (PropertyName) values('SourceProcessOrder')
 	 insert into @ValidProperties (PropertyName) values('SourcePathCode')
 	 
 	 insert into @ValidProperties (PropertyName) values('CommentText')
 	 
 	 insert into @ValidProperties (PropertyName) values('UserGeneral1')
 	 insert into @ValidProperties (PropertyName) values('UserGeneral2')
 	 insert into @ValidProperties (PropertyName) values('UserGeneral3')
/* Not used in current client - but still returned */
 	 insert into @ValidProperties (PropertyName) values('Department')
 	 insert into @ValidProperties (PropertyName) values('ProductionLine')
 	 insert into @ValidProperties (PropertyName) values('ProductionUnit')
 	 
 	 insert into @DisabledProperties (PropertyName) values('StartTime')
 	 insert into @DisabledProperties (PropertyName) values('EndTime')
 	 insert into @DisabledProperties (PropertyName) values('PredictedRemainingDuration')
 	 insert into @DisabledProperties (PropertyName) values('PredictedRemainingQuantity')
 	 insert into @DisabledProperties (PropertyName) values('PredictedTotalDuration')
 	 insert into @DisabledProperties (PropertyName) values('ActualGoodItems')
 	 insert into @DisabledProperties (PropertyName) values('ActualGoodQuantity')
 	 insert into @DisabledProperties (PropertyName) values('ActualBadItems')
 	 insert into @DisabledProperties (PropertyName) values('ActualBadQuantity')
 	 insert into @DisabledProperties (PropertyName) values('ActualDownTime')
 	 insert into @DisabledProperties (PropertyName) values('ActualRepetitions')
 	 insert into @DisabledProperties (PropertyName) values('ActualRunningTime')
 	 insert into @DisabledProperties (PropertyName) values('LateItems')
 	 insert into @DisabledProperties (PropertyName) values('AlarmCount')
 	 insert into @DisabledProperties (PropertyName) values('AdjustedQuantity')
 	 insert into @DisabledProperties (PropertyName) values('ProductionRate')
 	 insert into @DisabledProperties (PropertyName) values('EntryOn')
 	 insert into @DisabledProperties (PropertyName) values('ProductionPlanType')
 	 insert into @DisabledProperties (PropertyName) values('ParentProcessOrder')
 	 insert into @DisabledProperties (PropertyName) values('ParentPathCode')
 	 insert into @DisabledProperties (PropertyName) values('SourceProcessOrder')
 	 insert into @DisabledProperties (PropertyName) values('SourcePathCode')
 	 insert into @ValidProperties 
 	  	 SELECT PropertyName FROM @DisabledProperties
 	  	 
 	 insert into @RequiredProperties (PropertyName) values('ProcessOrder')
 	 insert into @RequiredProperties (PropertyName) values('PathCode')
 	 insert into @RequiredProperties (PropertyName) values('ProductionPlanStatus')
 	 insert into @RequiredProperties (PropertyName) values('ProductCode')
 	 insert into @RequiredProperties (PropertyName) values('ForecastStartTime')
 	 insert into @RequiredProperties (PropertyName) values('ForecastEndTime')
 	 insert into @RequiredProperties (PropertyName) values('ForecastQuantity')
 	 IF @TransactionType = 1 --Update
 	 BEGIN
 	  	 insert into @RequiredProperties (PropertyName) values('Id')
 	  	 insert into @ValidProperties (PropertyName) values('Id')
 	  	 
 	  	 insert into @DisabledProperties (PropertyName) values('ProductionPlanStatus')
 	  	 insert into @DisabledProperties (PropertyName) values('PathCode')
 	  	 insert into @DisabledProperties (PropertyName) values('ProductCode')
 	  	 insert into @DisabledProperties (PropertyName) values('BOMFormulation')
 	  	 insert into @DisabledProperties (PropertyName) values('ProductionPlanType')
 	 END
END
if @TransactionType in (1,2) -- Update or Delete
begin
 	 insert into @RequiredProperties (PropertyName) values('Id')
 	 insert into @ValidProperties (PropertyName) values('Id')
end
if (@TransactionType = 3) -- Query
begin
 	 if (@FirstTime = 1)
 	 begin
 	  	 insert into @PropertyItems select 'Username',             User_Id, null, Username, Username from Users where User_Id > 50 or User_Id = 1
 	  	 insert into @PropertyItems select 'Username',             * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 END
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('ParentPathId')
 	 insert into @ValidProperties (PropertyName) values('SourcePathId')
end
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

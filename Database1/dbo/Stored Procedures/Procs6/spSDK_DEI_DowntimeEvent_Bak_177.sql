CREATE procedure [dbo].[spSDK_DEI_DowntimeEvent_Bak_177]
 	 @TransactionType int,
 	 @FirstTime bit,
 	 @SDKUserId int,
 	 @DepartmentId int output,
 	 @DepartmentIdChanged bit,
 	 @ProductionLineId int output,
 	 @ProductionLineIdChanged bit,
 	 @ProductionUnitId int output,
 	 @ProductionUnitIdChanged bit,
 	 @SourceDepartmentId int output,
 	 @SourceDepartmentIdChanged bit,
 	 @SourceProductionLineId int output,
 	 @SourceProductionLineIdChanged bit,
 	 @SourceProductionUnitId int output,--13
 	 @SourceProductionUnitIdChanged bit,--14
 	 @UserId int output,
 	 @UserIdChanged bit,
 	 @ResearchStatusId int output,
 	 @ResearchStatusIdChanged bit,
 	 @ResearchUserId int output,
 	 @ResearchUserIdChanged bit,
 	 @DowntimeFaultId int output, --21
 	 @DowntimeFaultIdChanged bit,
 	 @DowntimeStatusId int output,
 	 @DowntimeStatusIdChanged bit,
 	 @Cause1Id int output,
 	 @Cause1IdChanged bit,
 	 @Cause2Id int output,
 	 @Cause2IdChanged bit,
 	 @Cause3Id int output,
 	 @Cause3IdChanged bit, --30
 	 @Cause4Id int output,
 	 @Cause4IdChanged bit,
 	 @Action1Id int output,
 	 @Action1IdChanged bit,
 	 @Action2Id int output,
 	 @Action2IdChanged bit,
 	 @Action3Id int output,
 	 @Action3IdChanged bit,
 	 @Action4Id int output,
 	 @Action4IdChanged bit, --40
 	 @DowntimeEventId Int Output,
 	 @DowntimeEventIdChanged int
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL nvarchar(100), UEL nvarchar(100), Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100),DefaultValue nVarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @EventType int
Declare @ReasonTreeId int
Declare @ActionTreeId int
DECLARE @ResearchEnabled Int
DECLARE @Level1Name VarChar(100)
DECLARE @Level2Name VarChar(100)
DECLARE @Level3Name VarChar(100)
DECLARE @Level4Name VarChar(100)
DECLARE @DaysBackOpenDowntimeEventCanBeAdded Int
DECLARE @OpenDowntimeEventCanBeAddedDaysBack Int
DECLARE @NewStartTime DateTime
DECLARE @NextStartTime DateTime,@PrevEndTime DateTime
DECLARE @CurrentEndtime DateTime,@CurrentStartTime DateTime
Declare @sheetId Int,@MyAccessLevel Int
Select @DaysBackOpenDowntimeEventCanBeAdded = CONVERT(int, COALESCE(Value, '0')) From Site_Parameters Where Parm_Id = 77
Select @OpenDowntimeEventCanBeAddedDaysBack = CONVERT(tinyint, COALESCE(Value, '0')) From Site_Parameters Where Parm_Id = 78
SET @OpenDowntimeEventCanBeAddedDaysBack = 0 --- disap
set @EventType = 2 -- Downtime
set @ReasonTreeId = null
set @ActionTreeId = null
SET @ResearchEnabled = 0
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'Id',                   '',                       null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'Department',           'DepartmentId',           null,               1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionLine',       'ProductionLineId',       'Line',             1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionUnit',       'ProductionUnitId',       'Unit',             1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'SourceDepartment',     'SourceDepartmentId', 	  '',                 0, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'SourceProductionLine', 'SourceProductionLineId', '',                 0, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'SourceProductionUnit', 'SourceProductionUnitId', 'Location',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'StartTime',            '',                       'Start Time',       1, 'datetime', 0,  Convert(VarChar(25),DateAdd(Month,-1,GETUTCDATE()),120),  Convert(VarChar(25),DateAdd(Month,1,GETUTCDATE()),120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'EndTime',              '',                       'End Time',         1, 'datetime', 0, Convert(VarChar(25),DateAdd(Month,-1,GETUTCDATE()),120),  Convert(VarChar(25),DateAdd(Month,1,GETUTCDATE()),120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'DowntimeFault',        'DowntimeFaultId',        'Fault',            1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'DowntimeStatus',       'DowntimeStatusId',       'Status',           1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Duration',             '',                       null,               0, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'Username',             'UserId',                 'User Name',        0, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause1',               'Cause1Id',               'Cause 1',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause2',               'Cause2Id',               'Cause 2',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause3',               'Cause3Id',               'Cause 3',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause4',               'Cause4Id',               'Cause 4',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'CauseCommentText',     'CauseCommentId',         'Cause Comment',    0, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'Action1',              'Action1Id',              'Action 1',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Action2',              'Action2Id',              'Action 2',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Action3',              'Action3Id',              'Action 3',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Action4',              'Action4Id',              'Action 4',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ActionCommentText',    'ActionCommentId',        'Action Comment',   0, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'ResearchOpenDate',     '',                       'Open Date',        0, 'datetime', 0,  null,  null, null, null, null,Null
insert into @Properties select 'ResearchCloseDate',    '',                       'Close Date',       0, 'datetime', 0,Null  ,  Null, null, null, null,Null
insert into @Properties select 'ResearchStatus',       'ResearchStatusId',       'Status',           1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ResearchUserName',     '', 	  	  	  	  	  	  'User Name',        0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'ResearchCommentText',  'ResearchCommentId',      'Research Comment', 0, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'ReasonTreeDataId',     '',                       null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ESignatureId',         '',                       null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'DowntimeEventId',      '',                       null,               1, 'integer',  0, null, null, null, null, null,null
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
  SET @SourceProductionUnitId = null
  SET @SourceProductionUnitIdChanged = 1
  set @DowntimeStatusId = null
  set @DowntimeStatusIdChanged = 1
end
IF (@SourceProductionUnitIdChanged = 1)
BEGIN
  set @DowntimeFaultId = null
  set @DowntimeFaultIdChanged = 1
  set @Action1Id = null
  set @Action1IdChanged = 1
END
IF (@DowntimeFaultIdChanged = 1)
BEGIN
  set @Cause1Id = null
  set @Cause1IdChanged = 1
END
if (@Cause1IdChanged = 1)
begin
  set @Cause2Id = null
  set @Cause2IdChanged = 1
end
if (@Cause2IdChanged = 1)
begin
  set @Cause3Id = null
  set @Cause3IdChanged = 1
end
if (@Cause3IdChanged = 1)
begin
  set @Cause4Id = null
  set @Cause4IdChanged = 1
end
if (@Action1IdChanged = 1)
begin
  set @Action2Id = null
  set @Action2IdChanged = 1
end
if (@Action2IdChanged = 1)
begin
  set @Action3Id = null
  set @Action3IdChanged = 1
end
if (@Action3IdChanged = 1)
begin
  set @Action4Id = null
  set @Action4IdChanged = 1
end
--Select @Cause1Id,@Cause2Id,@Cause3Id,@Cause4Id
--Select @Cause1IdChanged,@Cause2IdChanged,@Cause3IdChanged,@Cause4IdChanged
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
IF @DowntimeEventId Is Not Null
BEGIN
 	 SELECT @CurrentEndtime = End_time,@CurrentStartTime = Start_Time
 	  	 FROM Timed_Event_Details
 	  	 WHERE TEDet_Id = @DowntimeEventId
 	 SELECT @PrevEndTime = MAX(End_Time) 
 	  	 From Timed_Event_Details 
 	  	 where (PU_Id = @ProductionUnitId) and (End_Time <= @CurrentStartTime)
 	 SELECT @NextStartTime = Min(Start_Time) 
 	  	 From Timed_Event_Details 
 	  	 where (PU_Id = @ProductionUnitId) and (Start_Time >= @CurrentEndtime)
 	  	 IF @NextStartTime is Null
 	  	 BEGIN
 	  	  	 SET @NextStartTime = Convert(VarChar(25),DateAdd(Month,1,GETUTCDATE()),120)
 	  	 END
 	  	 SELECT @CurrentEndtime = dbo.fnServer_CmnConvertFromDbTime(Dateadd(second,-1,@CurrentEndtime),'UTC')
 	  	 SELECT @CurrentStartTime = dbo.fnServer_CmnConvertFromDbTime(Dateadd(second,1,@CurrentStartTime),'UTC')
 	  	 SELECT @PrevEndTime = dbo.fnServer_CmnConvertFromDbTime(Dateadd(second,1,@PrevEndTime),'UTC')
 	  	 SELECT @NextStartTime = dbo.fnServer_CmnConvertFromDbTime(Dateadd(second,-1,@NextStartTime),'UTC')
 	  	 UPDATE @Properties  	 SET  LEL =  Convert(VarChar(25),@PrevEndTime,120),UEL = Convert(VarChar(25),@CurrentEndtime,120),IsEnabled = 1
 	  	  	 WHERE  PropertyName = 'StartTime'
 	  	 UPDATE @Properties  	 SET  LEL =  Convert(VarChar(25),@CurrentStartTime,120),UEL = Convert(VarChar(25),@NextStartTime,120),IsEnabled = 1
 	  	  	 WHERE  PropertyName = 'EndTime'
END
ELSE
BEGIN
 	 IF (@ProductionUnitId is not null)
 	 BEGIN
 	  	 SELECT @NewStartTime = DateAdd(Month,-1,GETUTCDATE())
 	  	 IF @DaysBackOpenDowntimeEventCanBeAdded <> 0
 	  	 BEGIN 
 	  	  	 Select @NewStartTime = DateAdd(day, -1 * @DaysBackOpenDowntimeEventCanBeAdded,GETUTCDATE())
 	  	 END
       IF @OpenDowntimeEventCanBeAddedDaysBack = 0
 	  	 BEGIN
 	  	  	 Select @PrevEndTime = MAX(End_Time) 
 	  	  	  	 From Timed_Event_Details 
 	  	  	  	 where (PU_Id = @ProductionUnitId) and (End_Time is NOT NULL)
 	  	  	 SET @PrevEndTime =  dbo.fnServer_CmnConvertFromDbTime(@PrevEndTime,'UTC')
 	  	  	 IF @PrevEndTime > @NewStartTime
 	  	  	  	 SET @NewStartTime = @PrevEndTime
 	  	 END
 	  	 UPDATE @Properties 
 	  	  	  	 SET  LEL =  Convert(VarChar(25),@NewStartTime,120)
 	  	  	 WHERE  PropertyName = 'StartTime'
 	 END
 	 ELSE
 	 BEGIN
 	  	 UPDATE @Properties  	 SET  LEL =  Null,UEL = Null,DefaultValue = null,IsEnabled = 0
 	  	  	 WHERE  PropertyName = 'StartTime'
 	  	 UPDATE @Properties  	 SET  LEL =  Null,UEL = Null,DefaultValue = null,IsEnabled = 0
 	  	  	 WHERE  PropertyName = 'EndTime'
 	 END
END
if (@FirstTime = 1 or @ProductionUnitIdChanged = 1)
  begin
    if (@ProductionUnitId is not null)
      begin
        insert into @PropertyItems select 'SourceProductionUnit', a.PU_Id, a.PU_Order, a.PU_Desc, a.PU_Desc
 	  	  	 FROM Prod_Units_Base a
 	  	  	 JOIN Prod_Events c on c.PU_Id = a.PU_Id and c.Event_Type = @EventType
 	  	  	 WHERE a.Master_Unit = @ProductionUnitId or a.PU_Id = @ProductionUnitId
        insert into @PropertyItems select 'SourceProductionUnit', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
        insert into @PropertyItems select 'DowntimeStatus',       TEStatus_Id, null, TEStatus_Name, TEStatus_Name from Timed_Event_Status where PU_Id = @ProductionUnitId
        insert into @PropertyItems select 'DowntimeStatus',       * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
        IF @SourceProductionUnitId is Null 
        BEGIN
 	  	  	 SET @SourceProductionUnitId =  @ProductionUnitId
 	  	  	 SET @SourceProductionUnitIdChanged = 1
 	  	 END
      end
    else
      begin
        insert into @PropertyItems select 'SourceProductionUnit', * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'DowntimeFault',        * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'DowntimeStatus',       * from fnSDK_DEI_InsertEmptyList (0)
      end
  end
if (@FirstTime = 1 or @SourceProductionUnitIdChanged = 1)
  begin
    if (@SourceProductionUnitId is not null)
      begin
        insert into @PropertyItems select 'DowntimeFault',        TEFault_Id, null, TEFault_Name, TEFault_Name from Timed_Event_Fault where Source_PU_Id = @SourceProductionUnitId
        insert into @PropertyItems select 'DowntimeFault',        * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      begin
 	  	 SET @ReasonTreeId = Null
 	  	 SET @ActionTreeId = Null
        insert into @PropertyItems select 'DowntimeFault',        * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
  end
if (@SourceProductionUnitId is not null)
BEGIN
 	 select @ReasonTreeId = Name_Id,
 	  	    @ActionTreeId = Action_Tree_Id,
 	  	    @ResearchEnabled = Research_Enabled 
 	 FROM Prod_Events where PU_Id = @SourceProductionUnitId and Event_Type = @EventType
END
IF  (@FirstTime = 1 and @TransactionType = 0)  or @DowntimeFaultIdChanged = 1 
BEGIN
 	 IF @DowntimeFaultId Is Not Null
 	 BEGIN
 	  	 SELECT 	 @Cause1Id = a.Reason_Level1,
 	  	  	  	 @Cause2Id = a.Reason_Level2,
 	  	  	  	 @Cause3Id = a.Reason_Level3,
 	  	  	  	 @Cause4Id = a.Reason_Level4 
 	  	 FROM Timed_Event_Fault a 
 	  	  	 WHERE a.TEFault_Id = @DowntimeFaultId
 	   set @Cause1IdChanged= 1
 	   set @Cause2IdChanged= 1
 	   set @Cause3IdChanged= 1
 	   set @Cause4IdChanged= 1
 	 insert into @PropertyItems select 'Cause1',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 1, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
 	 insert into @PropertyItems select 'Cause1',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 END
 	 ELSE
 	 BEGIN
 	  	 set @Cause1Id = null
 	  	 set @Cause1IdChanged = 1
 	  	 insert into @PropertyItems select 'Cause1',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 END
END 
--Select @Cause1IdChanged,@Cause2IdChanged,@Cause3IdChanged,@Cause4IdChanged
--Select @Cause1Id,@Cause2Id,@Cause3Id,@Cause4Id
IF @ReasonTreeId Is Not Null
BEGIN
 	 insert into @PropertyItems select 'Cause1',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 1, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
 	 insert into @PropertyItems select 'Cause1',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
END
ELSE
BEGIN
 	 set @Cause1Id = null
 	 set @Cause1IdChanged = 1
 	 insert into @PropertyItems select 'Cause1',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 set @Cause2Id = null
 	 set @Cause2IdChanged = 1
 	 set @Cause3Id = null
 	 set @Cause3IdChanged = 1
 	 set @Cause4Id = null
 	 set @Cause4IdChanged = 1
END
if (@FirstTime = 1 or @Cause2IdChanged = 1 or @Cause1Id is not null)
  begin
    if (@Cause1Id is not null)
      begin
        insert into @PropertyItems select 'Cause2',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 2, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
        insert into @PropertyItems select 'Cause2',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Cause2',               * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Cause3IdChanged = 1 or @Cause2Id is not null)
  begin
    if (@Cause2Id is not null)
      begin
        insert into @PropertyItems select 'Cause3',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 3, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
        insert into @PropertyItems select 'Cause3',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Cause3',               * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Cause4IdChanged = 1 or @Cause3Id is not null)
  begin
    if (@Cause3Id is not null)
      begin
        insert into @PropertyItems select 'Cause4',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 4, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
        insert into @PropertyItems select 'Cause4',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Cause4',               * from fnSDK_DEI_InsertEmptyList (0)
  end
IF @ActionTreeId Is Not Null
BEGIN
 	 insert into @PropertyItems select 'Action1', * from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 1, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
 	 insert into @PropertyItems select 'Action1', * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
END
ELSE
BEGIN
 	 set @Action1Id = null
 	 set @Action1IdChanged = 1
 	 insert into @PropertyItems select 'Action1',* from fnSDK_DEI_InsertEmptyList (0)
 	 set @Action2Id = null
 	 set @Action2IdChanged = 1
 	 set @Action3Id = null
 	 set @Action3IdChanged = 1
 	 set @Action4Id = null
 	 set @Action4IdChanged = 1
END
if (@FirstTime = 1 or @Action2IdChanged = 1 or @Action1Id is not null)
  begin
    if (@Action1Id is not null)
      begin
        insert into @PropertyItems select 'Action2',              * from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 2, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
        insert into @PropertyItems select 'Action2',              * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Action2',              * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Action3IdChanged = 1 or @Action2Id is not null)
  begin
    if (@Action2Id is not null)
      begin
        insert into @PropertyItems select 'Action3',              * from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 3, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
        insert into @PropertyItems select 'Action3',              * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Action3',              * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Action4IdChanged = 1 or @Action3Id is not null)
  begin
    if (@Action3Id is not null)
      begin
        insert into @PropertyItems select 'Action4',              * from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 4, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
        insert into @PropertyItems select 'Action4',              * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Action4',              * from fnSDK_DEI_InsertEmptyList (0)
  end
IF (@ReasonTreeId is not null)
BEGIN
 	 SELECT @Level1Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ReasonTreeId and Reason_Level = 1
 	 SELECT @Level2Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ReasonTreeId and Reason_Level = 2
 	 SELECT @Level3Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ReasonTreeId and Reason_Level = 3
 	 SELECT @Level4Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ReasonTreeId and Reason_Level = 4
 	 IF @Level1Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level1Name where PropertyName = 'Cause1'
 	 END
 	 IF @Level2Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level2Name where PropertyName = 'Cause2'
 	 END
 	 IF @Level3Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level3Name where PropertyName = 'Cause3'
 	 END
 	 IF @Level4Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level4Name where PropertyName = 'Cause4'
 	 END
END
IF (@ActionTreeId is not null)
BEGIN
 	 SET @Level1Name = Null
 	 SET @Level2Name = Null
 	 SET @Level3Name = Null
 	 SET @Level4Name = Null
 	 SELECT @Level1Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ActionTreeId and Reason_Level = 1
 	 SELECT @Level2Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ActionTreeId and Reason_Level = 2
 	 SELECT @Level3Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ActionTreeId and Reason_Level = 3
 	 SELECT @Level4Name = Level_Name FROM Event_Reason_Level_Headers where Tree_Name_Id = @ActionTreeId and Reason_Level = 4
 	 IF @Level1Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level1Name where PropertyName = 'Action1'
 	 END
 	 IF @Level2Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level2Name where PropertyName = 'Action2'
 	 END
 	 IF @Level3Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level3Name where PropertyName = 'Action3'
 	 END
 	 IF @Level4Name IS NOT NULL
 	 BEGIN
 	  	 UPDATE @Properties set PropertyDisplayName = @Level4Name where PropertyName = 'Action4'
 	 END
END
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
 	 insert into @ValidProperties (PropertyName) values('Duration')
 	 insert into @ValidProperties (PropertyName) values('StartTime')
 	 insert into @ValidProperties (PropertyName) values('EndTime')
 	 insert into @ValidProperties (PropertyName) values('SourceProductionUnit')
 	 insert into @ValidProperties (PropertyName) values('DowntimeFault')
 	 insert into @ValidProperties (PropertyName) values('DowntimeStatus')
 	 insert into @ValidProperties (PropertyName) values('Cause1')
 	 insert into @ValidProperties (PropertyName) values('Cause2')
 	 insert into @ValidProperties (PropertyName) values('Cause3')
 	 insert into @ValidProperties (PropertyName) values('Cause4')
 	 insert into @ValidProperties (PropertyName) values('CauseCommentText')
 	 insert into @ValidProperties (PropertyName) values('Action1')
 	 insert into @ValidProperties (PropertyName) values('Action2')
 	 insert into @ValidProperties (PropertyName) values('Action3')
 	 insert into @ValidProperties (PropertyName) values('Action4')
 	 insert into @ValidProperties (PropertyName) values('ActionCommentText')
 	 insert into @ValidProperties (PropertyName) values('ResearchOpenDate')
 	 insert into @ValidProperties (PropertyName) values('ResearchCloseDate')
 	 insert into @ValidProperties (PropertyName) values('ResearchStatus')
 	 insert into @ValidProperties (PropertyName) values('ResearchUserName')
 	 insert into @ValidProperties (PropertyName) values('ResearchCommentText')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('Department')
 	 insert into @RequiredProperties (PropertyName) values('ProductionLine')
 	 insert into @RequiredProperties (PropertyName) values('ProductionUnit')
 	 insert into @RequiredProperties (PropertyName) values('StartTime')
 	 --insert into @RequiredProperties (PropertyName) values('EndTime')
 	 
 	 if (@Cause1Id is not null)
 	 begin
 	  	 if (exists(select * from @PropertyItems where PropertyName like 'Cause1' and ItemId is not null))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Cause1')
 	  	 if ((@Cause2Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Cause2' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Cause2')
 	  	 if ((@Cause3Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Cause3' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Cause3')
 	  	 if ((@Cause4Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Cause4' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Cause4')
 	 end
 	 if (@Action1Id is not null)
 	 begin
 	  	 if (exists(select * from @PropertyItems where PropertyName like 'Action1' and ItemId is not null))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Action1')
 	  	 if ((@Action2Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Action2' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Action2')
 	  	 if ((@Action3Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Action3' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Action3')
 	  	 if ((@Action4Id is not null) or
 	  	  	 (exists(select * from @PropertyItems where PropertyName like 'Action4' and ItemId is not null)))
 	  	  	 insert into @RequiredProperties (PropertyName) values('Action4')
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
 	 insert into @ValidProperties (PropertyName) values('ReasonTreeDataId')
 	 insert into @ValidProperties (PropertyName) values('ESignatureId')
end
IF @ResearchEnabled = 0
BEGIN
    insert into @PropertyItems select 'ResearchStatus',* from fnSDK_DEI_InsertEmptyList (0)
END
ELSE
BEGIN
    insert into @PropertyItems select 'ResearchStatus',   Research_Status_Id, null, Research_Status_Desc, Research_Status_Desc from Research_Status
END
EXECUTE dbo.spSDK_DEI_GetSecurityBySheet @ProductionUnitId ,@ProductionLineId ,@SDKUserId ,@sheetId  Output,@MyAccessLevel  Output
IF  (SELECT Convert(Int,dbo.fnSDK_DEI_GetDisplayOptionValue('Assign Reasons',30,@sheetId,23))) > @MyAccessLevel
BEGIN
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Cause1')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Cause2')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Cause3')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Cause4')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Action1')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Action2')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Action3')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Action4')
END
IF (SELECT Convert(Int,dbo.fnSDK_DEI_GetDisplayOptionValue('Change Fault',30,@sheetId,23))) > @MyAccessLevel
BEGIN
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('DowntimeFault')
END
IF  (SELECT Convert(Int,dbo.fnSDK_DEI_GetDisplayOptionValue('Change Location',30,@sheetId,23))) > @MyAccessLevel
BEGIN
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('SourceProductionUnit')
END
IF  (SELECT Convert(Int,dbo.fnSDK_DEI_GetDisplayOptionValue('Change Time',30,@sheetId,23))) > @MyAccessLevel
BEGIN
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('StartTime')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('EndTime')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('Duration')
END
IF  (SELECT Convert(Int,dbo.fnSDK_DEI_GetDisplayOptionValue('Change Comments',30,@sheetId,23))) > @MyAccessLevel
BEGIN
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('CauseCommentText')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('ActionCommentText')
 	 INSERT INTO @DisabledProperties(PropertyName) VALUES ('ResearchCommentText')
END
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select Distinct PropertyOrder,PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits,DefaultValue 
 	 from @Properties 
 	 order by PropertyOrder
select Distinct PropertyName, ItemValue, ItemId, ItemDisplayValue,ItemOrder from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

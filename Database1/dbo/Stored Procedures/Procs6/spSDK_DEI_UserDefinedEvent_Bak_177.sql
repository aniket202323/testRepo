CREATE procedure [dbo].[spSDK_DEI_UserDefinedEvent_Bak_177]
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
 	 @AckById int output,
 	 @AckByIdChanged bit,
 	 @Cause1Id int output,
 	 @Cause1IdChanged bit,
 	 @Cause2Id int output,
 	 @Cause2IdChanged bit,
 	 @Cause3Id int output,
 	 @Cause3IdChanged bit,
 	 @Cause4Id int output,
 	 @Cause4IdChanged bit,
 	 @Action1Id int output,
 	 @Action1IdChanged bit,
 	 @Action2Id int output,
 	 @Action2IdChanged bit,
 	 @Action3Id int output,
 	 @Action3IdChanged bit,
 	 @Action4Id int output,
 	 @Action4IdChanged bit,
 	 @ResearchStatusId int output,
 	 @ResearchStatusIdChanged bit,
 	 @ResearchUserId int output,
 	 @ResearchUserIdChanged bit,
 	 @EventSubTypeId int output,
 	 @EventSubTypeIdChanged bit,
 	 @EventStatusId int output,
 	 @EventStatusIdChanged bit,
 	 @TestingStatusId int output,
 	 @TestingStatusIdChanged bit
AS
Declare @Properties table(PropertyOrder int IDENTITY, PropertyName nvarchar(100), IdPropertyName nvarchar(100), PropertyDisplayName nvarchar(100), IsEnabled bit, PropertyType nvarchar(100), isRequired bit, LEL nvarchar(100), UEL nvarchar(100), Precision int, DataEntryMask nvarchar(100), EngUnits nvarchar(100),DefaultValue nVarchar(100))
Declare @PropertyItems table(PropertyName nvarchar(100), ItemId int, ItemOrder int, ItemDisplayValue nvarchar(100), ItemValue nvarchar(100))
Declare @RequiredProperties table(PropertyName nvarchar(100))
Declare @ValidProperties table(PropertyName nvarchar(100))
Declare @DisabledProperties table(PropertyName nvarchar(100))
Declare @EventType int
Declare @ReasonTreeId int
Declare @ActionTreeId int
DECLARE @Level1Name VarChar(100)
DECLARE @Level2Name VarChar(100)
DECLARE @Level3Name VarChar(100)
DECLARE @Level4Name VarChar(100)
set @EventType = 14 -- UDE
set @ReasonTreeId = null
set @ActionTreeId = null
------------------------------------------------------------------------------------------------------------------
-- Setup property list
------------------------------------------------------------------------------------------------------------------
insert into @Properties select 'UserDefinedEventName',       '',                         'UDE Name',         1, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'Id',                         '',                         null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'Department',                 'DepartmentId',             null,               1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionLine',             'ProductionLineId',         'Line',             1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionUnit',             'ProductionUnitId',         'Unit',             1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'StartTime',                  '',                         'Start Time',       1, 'datetime', 0, Convert(VarChar(25),DateAdd(Month,-1,GETUTCDATE()),120),  Convert(VarChar(25),DateAdd(Month,1,GETUTCDATE()),120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'EndTime',                    '',                         'End Time',         1, 'datetime', 0, Convert(VarChar(25),DateAdd(Month,-1,GETUTCDATE()),120),  Convert(VarChar(25),DateAdd(Month,1,GETUTCDATE()),120), null, null, null,Convert(VarChar(25),GETUTCDATE(),120)
insert into @Properties select 'CommentText',                'CommentId',                'Comment',          1, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'Username',                   'User', 	  	  	  	  	  'User Name',        0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'Ack',                        '',                         null,               1, 'bool',     0, null, null, null, null, null,'0'
insert into @Properties select 'AckBy',                      'AckById',                  'Ack By',           0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'AckOn',                      '',                         'Ack On',           0, 'datetime', 0, null, null, null, null, null,null
insert into @Properties select 'Cause1',                     'Cause1Id',                 'Cause 1',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause2',                     'Cause2Id',                 'Cause 2',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause3',                     'Cause3Id',                 'Cause 3',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Cause4',                     'Cause4Id',                 'Cause 4',          1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'CauseCommentText',           'CauseCommentId',           'Cause Comment',    1, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'Action1',                    'Action1Id',                'Action 1',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Action2',                    'Action2Id',                'Action 2',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Action3',                    'Action3Id',                'Action 3',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'Action4',                    'Action4Id',                'Action 4',         1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ActionCommentText',          'ActionCommentId',          'Action Comment',   1, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'ResearchOpenDate',           '',                         'Open Date',        0, 'datetime', 0, Null, Null, null, null, null,Null
insert into @Properties select 'ResearchCloseDate',          '',                         'Close Date',       0, 'datetime', 0, Null, Null, null, null, null,Null
insert into @Properties select 'ResearchStatus',             'ResearchStatusId',         'Research Status',  1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ResearchUserName',           'ResearchUserId',           'Research User',    0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'ResearchCommentText',        'ResearchCommentId',        'Research Comment', 1, 'comment',  0, null, null, null, null, null,null
insert into @Properties select 'Duration',                   '',                         null,               0, 'float',    0, null, null, null, null, null,null
insert into @Properties select 'EventSubType',               'EventSubTypeId',           'Event Sub Type',   1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'ParentUserDefinedEventName', '',                         'Parent UDE',       0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'ParentUserDefinedEventId',   '',                         null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ProductionEventName',        '',                         'Event',            0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'ProductionEventId',          '',                         null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ReasonTreeDataId',           '',                         null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'ESignatureId',               '',                         null,               1, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'EventStatus',                'EventStatusId',            'Status',           1, 'list',     0, null, null, null, null, null,null
insert into @Properties select 'TestingStatus',              '', 	  	  	  	  	  	  'Testing Status',   0, 'text',     0, null, null, null, null, null,null
insert into @Properties select 'Conformance',                '',                         null,               0, 'integer',  0, null, null, null, null, null,null
insert into @Properties select 'TestPercentComplete',        '',                         'Test % Complete',  0, 'integer',  0, null, null, null, null, null,null
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
  set @EventSubTypeId = null
  set @EventSubTypeIdChanged = 1
  set @Cause1Id = null
  set @Cause1IdChanged = 1
  set @Action1Id = null
  set @Action1IdChanged = 1
end
if (@Cause1IdChanged = 1) or (@Cause2Id is Not Null and @Cause1Id Is Null)
begin
  set @Cause2Id = null
  SET @Cause1IdChanged = 1
  set @Cause2IdChanged = 1
end
if (@Cause2IdChanged = 1) or (@Cause3Id is Not Null and @Cause2Id Is Null)
begin
  set @Cause3Id = null
  set @Cause2IdChanged = 1
  set @Cause3IdChanged = 1
end
if (@Cause3IdChanged = 1) or (@Cause4Id is Not Null and @Cause3Id Is Null)
begin
  set @Cause4Id = null
  set @Cause3IdChanged = 1
  set @Cause4IdChanged = 1
end
if (@Action1IdChanged = 1) or (@Action2Id is Not Null and @Action1Id Is Null)
begin
  set @Action2Id = null
  SET @Action1IdChanged = 1
  set @Action2IdChanged = 1
end
if (@Action2IdChanged = 1) or (@Action3Id is Not Null and @Action2Id Is Null)
begin
  set @Action3Id = null
  SET @Action2IdChanged = 1
  set @Action3IdChanged = 1
end
if (@Action3IdChanged = 1) or (@Action4Id is Not Null and @Action3Id Is Null)
begin
  set @Action4Id = null
  SET @Action3IdChanged = 1
  set @Action4IdChanged = 1
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
if (@FirstTime = 1)
  begin
    insert into @PropertyItems select 'ResearchStatus',   Research_Status_Id, null, Research_Status_Desc, Research_Status_Desc from Research_Status
    insert into @PropertyItems select 'ResearchStatus',   * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
  end
if  @TransactionType = 0 AND @EventStatusId Is NUll
BEGIN
 	 IF @ProductionUnitId Is Not Null
 	  	 SELECT  @EventStatusId = MIN(Valid_Status)
 	  	  	 FROM PrdExec_Status a
 	  	  	 WHERE Is_Default_Status = 1 AND a.PU_Id = @ProductionUnitId
 	 IF @EventStatusId Is Null 
 	  	 SET @EventStatusId = 5
 	 SET @EventStatusIdChanged = 1
 	 UPDATE @Properties SET DefaultValue = @EventStatusId WHERE PropertyName = 'ProductionStatus'
END
if (@FirstTime = 1 or @ProductionUnitIdChanged = 1)
  begin
    if (@ProductionUnitId is not null) 
      begin  
 	  	 DECLARE @SubTypeCount Int
        insert into @PropertyItems
          select 'EventSubType', es.Event_Subtype_Id, null, es.Event_Subtype_Desc, es.Event_Subtype_Desc
            from Event_Configuration ec
            join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
            where ec.ET_Id = @EventType and ec.PU_Id = @ProductionUnitId -- and ec.is_Active = 1
        SET @SubTypeCount = @@ROWCOUNT
        insert into @PropertyItems select 'EventSubType',         * from fnSDK_DEI_InsertEmptyList (@SubTypeCount)
        IF @SubTypeCount = 1 and  @EventSubTypeId Is Null
        BEGIN
 	  	  	 SELECT @EventSubTypeId = ec.Event_Subtype_Id             
 	  	  	  	 from Event_Configuration ec
 	  	  	  	 where ec.ET_Id = @EventType and ec.PU_Id = @ProductionUnitId
 	  	  	 SELECT @EventSubTypeIdChanged = 1
        END
 	  	 insert into @PropertyItems 
 	  	  	 select DISTINCT 'EventStatus', ProdStatus_Id, null, ProdStatus_Desc, ProdStatus_Desc 
 	  	  	 from Production_Status a
 	  	  	 JOIN PrdExec_Status b on b.Valid_Status = a.ProdStatus_Id
 	  	  	 WHERE b.PU_Id = @ProductionUnitId
 	  	 IF @@ROWCOUNT = 0
 	  	 BEGIN
 	  	  	 insert into @PropertyItems 
 	  	  	  	 select DISTINCT 'EventStatus', ProdStatus_Id, null, ProdStatus_Desc, ProdStatus_Desc 
 	  	  	  	 from Production_Status a
 	  	 END
      end
    else
      begin
        insert into @PropertyItems select 'EventSubType',         * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'Cause1',               * from fnSDK_DEI_InsertEmptyList (0)
        insert into @PropertyItems select 'Action1',              * from fnSDK_DEI_InsertEmptyList (0)
      end
  end
IF @EventSubTypeIdChanged = 1 or @EventSubTypeId IS Not Null 
BEGIN
 	 DECLARE @AckReq Int, @ActionReq Int,@CauseReq Int,@DurationReq Int
 	 DECLARE @DefC1 Int,@DefC2 Int,@DefC3 Int,@DefC4 Int
 	 DECLARE @DefA1 Int,@DefA2 Int,@DefA3 Int,@DefA4 Int
 	 SELECT  @AckReq = es.Ack_Required,
 	  	  	 @ActionReq = es.Action_Required,
 	  	  	 @CauseReq = es.Cause_Required,
 	  	  	 @DurationReq = es.Duration_Required,
 	  	  	 @ReasonTreeId = es.Cause_Tree_Id,
 	  	  	 @ActionTreeId = es.Action_Tree_Id,
 	  	  	 @DefA1 = es.Default_Action1,
 	  	  	 @DefA2 = es.Default_Action2,
 	  	  	 @DefA3 = es.Default_Action3,
 	  	  	 @DefA4 = es.Default_Action4,
 	  	  	 @DefC1 = es.Default_Cause1,
 	  	  	 @DefC2 = es.Default_Cause2,
 	  	  	 @DefC3 = es.Default_Cause3,
 	  	  	 @DefC4 = es.Default_Cause4
 	 FROM  Event_Subtypes es
 	 WHERE  es.Event_Subtype_Id = @EventSubTypeId
 	 IF @AckReq = 0
 	 BEGIN
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Ack')
 	 END
 	 IF @ActionReq = 0 OR @ActionTreeId Is Null
 	 BEGIN
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Action1')
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Action2')
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Action3')
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Action4')
 	 END
 	 ELSE IF @ActionReq = 1
 	 BEGIN
 	  	 INSERT INTO @PropertyItems select 'Action1',* from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 1, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
 	 END
    insert into @PropertyItems select 'Action1',* from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 IF @CauseReq = 0 OR @ReasonTreeId Is Null
 	 BEGIN
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Cause1')
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Cause2')
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Cause3')
 	  	 INSERT INTO @DisabledProperties  (PropertyName) VALUES ('Cause4')
 	 END
 	 ELSE IF @CauseReq = 1
 	 BEGIN
 	  	 INSERT into @PropertyItems select 'Cause1', * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 1, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
 	 END
 	 INSERT into @PropertyItems select 'Cause1',* from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
 	 IF @DurationReq = 1
 	 BEGIN
 	  	 INSERT INTO @RequiredProperties (PropertyName) values('StartTime')
 	  	 INSERT INTO @RequiredProperties (PropertyName) values('EndTime')
 	 END
 	 IF  @EventSubTypeIdChanged = 1
 	 BEGIN
 	  	 UPDATE @Properties SET DefaultValue = @DefC1 WHERE PropertyName = 'Cause1'
 	  	 UPDATE @Properties SET DefaultValue = @DefC2 WHERE PropertyName = 'Cause2'
 	  	 UPDATE @Properties SET DefaultValue = @DefC3 WHERE PropertyName = 'Cause3'
 	  	 UPDATE @Properties SET DefaultValue = @DefC4 WHERE PropertyName = 'Cause4'
 	  	 UPDATE @Properties SET DefaultValue = @DefA1 WHERE PropertyName = 'Action1'
 	  	 UPDATE @Properties SET DefaultValue = @DefA2 WHERE PropertyName = 'Action2'
 	  	 UPDATE @Properties SET DefaultValue = @DefA3 WHERE PropertyName = 'Action3'
 	  	 UPDATE @Properties SET DefaultValue = @DefA4 WHERE PropertyName = 'Action4'
 	  	 SET @Cause1Id = @DefC1
 	  	 SET @Cause2Id = @DefC2
 	  	 SET @Cause3Id = @DefC3
 	  	 SET @Cause4Id = @DefC4
 	  	 SET @Action1Id = @DefA1
 	  	 SET @Action2Id = @DefA2
 	  	 SET @Action3Id = @DefA3
 	  	 SET @Action4Id = @DefA4
 	  	 SET @Cause1IdChanged = 1
 	  	 SET @Cause2IdChanged = 1
 	  	 SET @Cause3IdChanged = 1
 	  	 SET @Cause4IdChanged = 1
 	  	 SET @Action1IdChanged = 1
 	  	 SET @Action2IdChanged = 1
 	  	 SET @Action3IdChanged = 1
 	  	 SET @Action4IdChanged = 1
 	 END
END
if (@FirstTime = 1 or @Cause1IdChanged = 1 or @Cause1Id is not null)
  begin
    if (@Cause1Id is not null)
      begin
        insert into @PropertyItems select 'Cause2',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 2, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
        insert into @PropertyItems select 'Cause2',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Cause2',               * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Cause2IdChanged = 1 or @Cause2Id is not null)
  begin
    if (@Cause2Id is not null)
      begin
        insert into @PropertyItems select 'Cause3',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 3, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
        insert into @PropertyItems select 'Cause3',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Cause3',               * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Cause3IdChanged = 1 or @Cause3Id is not null)
  begin
    if (@Cause3Id is not null)
      begin
        insert into @PropertyItems select 'Cause4',               * from dbo.fnSDK_DEI_GetReasonTreeItems (@ReasonTreeId, 4, @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id)
        insert into @PropertyItems select 'Cause4',               * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Cause4',               * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Action1IdChanged = 1 or @Action1Id is not null)
  begin
    if (@Action1Id is not null)
      begin
        insert into @PropertyItems select 'Action2',              * from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 2, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
        insert into @PropertyItems select 'Action2',              * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Action2',              * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Action2IdChanged = 1 or @Action2Id is not null)
  begin
    if (@Action2Id is not null)
      begin
        insert into @PropertyItems select 'Action3',              * from dbo.fnSDK_DEI_GetReasonTreeItems (@ActionTreeId, 3, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
        insert into @PropertyItems select 'Action3',              * from fnSDK_DEI_InsertEmptyList (@@ROWCOUNT)
      end
    else
      insert into @PropertyItems select 'Action3',              * from fnSDK_DEI_InsertEmptyList (0)
  end
if (@FirstTime = 1 or @Action3IdChanged = 1 or @Action3Id is not null)
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
if (@TransactionType <> 2) -- Not Delete
begin
 	 insert into @ValidProperties (PropertyName) values('Department')
 	 insert into @ValidProperties (PropertyName) values('ProductionLine')
 	 insert into @ValidProperties (PropertyName) values('ProductionUnit')
 	 insert into @ValidProperties (PropertyName) values('StartTime')
 	 insert into @ValidProperties (PropertyName) values('EndTime')
 	 insert into @ValidProperties (PropertyName) values('CommentText')
 	 insert into @ValidProperties (PropertyName) values('Ack')
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
 	 insert into @ValidProperties (PropertyName) values('Duration')
 	 insert into @ValidProperties (PropertyName) values('EventSubType')
 	 insert into @ValidProperties (PropertyName) values('ParentUserDefinedEventId')
 	 insert into @ValidProperties (PropertyName) values('ProductionEventId')
 	 insert into @ValidProperties (PropertyName) values('UserDefinedEventName')
 	 insert into @ValidProperties (PropertyName) values('ParentUserDefinedEventName')
 	 insert into @ValidProperties (PropertyName) values('ProductionEventName')
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('AckOn')
 	 insert into @ValidProperties (PropertyName) values('AckBy')
 	 insert into @ValidProperties (PropertyName) values('EventStatus')
 	 insert into @ValidProperties (PropertyName) values('TestingStatus')
 	 insert into @ValidProperties (PropertyName) values('Conformance')
 	 insert into @ValidProperties (PropertyName) values('TestPercentComplete')
End
if (@TransactionType in (0,1)) -- Add or Update
begin
 	 insert into @RequiredProperties (PropertyName) values('Department')
 	 insert into @RequiredProperties (PropertyName) values('ProductionLine')
 	 insert into @RequiredProperties (PropertyName) values('ProductionUnit')
 	 insert into @RequiredProperties (PropertyName) values('StartTime')
 	 insert into @RequiredProperties (PropertyName) values('EndTime')
 	 insert into @RequiredProperties (PropertyName) values('EventSubType')
 	 insert into @RequiredProperties (PropertyName) values('UserDefinedEventName')
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
 	 insert into @DisabledProperties (PropertyName) values('EventSubType')
end
if (@TransactionType in (1,2)) -- Update or Delete
begin
 	 insert into @RequiredProperties (PropertyName) values('Id')
 	 insert into @ValidProperties (PropertyName) values('Id')
end
if (@TransactionType = 3) -- Query
begin
 	 insert into @ValidProperties (PropertyName) values('UserDefinedEventName')
 	 insert into @ValidProperties (PropertyName) values('Username')
 	 insert into @ValidProperties (PropertyName) values('AckBy')
 	 insert into @ValidProperties (PropertyName) values('AckOn')
 	 insert into @ValidProperties (PropertyName) values('ReasonTreeDataId')
 	 insert into @ValidProperties (PropertyName) values('ESignatureId')
 	 insert into @ValidProperties (PropertyName) values('ParentUserDefinedEventName')
 	 insert into @ValidProperties (PropertyName) values('ProductionEventName')
end
update @Properties set isRequired = 1 where PropertyName in (select PropertyName from @RequiredProperties)
update @Properties set IsEnabled = 0 where PropertyName in (select PropertyName from @DisabledProperties)
delete from @Properties where PropertyName not in (select PropertyName from @ValidProperties)
delete from @PropertyItems where PropertyName not in (select PropertyName from @ValidProperties)
select PropertyName, IdPropertyName, PropertyDisplayName, IsEnabled, PropertyType, isRequired, LEL, UEL, Precision, DataEntryMask, EngUnits,DefaultValue from @Properties order by PropertyOrder
select PropertyName, ItemValue, ItemId, ItemDisplayValue from @PropertyItems order by PropertyName, ItemOrder, ItemDisplayValue
Return(1)

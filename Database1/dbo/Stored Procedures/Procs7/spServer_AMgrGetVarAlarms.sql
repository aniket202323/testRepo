CREATE PROCEDURE dbo.spServer_AMgrGetVarAlarms
 AS
declare
  @varid int,
  @Cutoffvarid int,
  @ATDId int,
  @ATId int,
  @RuleId int,
  @ATVRuleId int,
  @result nvarchar(25),
  @AlarmMax nvarchar(25),
  @AlarmMin nvarchar(25),
  @StartResult nvarchar(25),
  @EndResult nvarchar(25),
  @result_on datetime,
  @StartTime datetime,
  @EndTime datetime,
  @UserId int,
  @AlarmDesc nVarChar(1000),
  @CutoffVarDesc nVarChar(255),
  @SupportAppliedProdFlag int,
  @Value varchar(5000)
Set NoCount On
select @SupportAppliedProdFlag = 0
select @Value = Null
exec spServer_CmnGetParameter 196, 20, HOST_NAME, @Value OUTPUT
if @Value is not null and @value = '1'
   select @SupportAppliedProdFlag = 1
DECLARE @Current Int
Declare @End Int
DECLARE @Current1 Int
Declare @End1 Int
DECLARE @atids Table(myId Int Identity(1,1) Primary Key,atid Int)
DECLARE @ATVRD  Table(myId Int Identity(1,1) Primary Key,alarm_variable_rule_id Int, atvrd_id Int)
declare @AGVATheResults table (myId Int Identity(1,1) PRIMARY KEY ,VarId int, VarDesc nvarchar(255) NULL, PUId int, ATDId int NULL, Priority int NULL, ATId 
 	  	  	  	 int NULL, AlarmDesc nvarchar(1000) NULL, LowerEntry tinyint null, 
 	  	  	  	 LowerReject tinyint null, LowerWarning tinyint null, LowerUser tinyint null, 
 	  	  	  	 Target tinyint null, UpperUser tinyint null, UpperWarning tinyint null, 
 	  	  	  	 UpperReject tinyint null, UpperEntry tinyint null, SamplingType int NULL, 
 	  	  	  	 CutoffVarId int null, CutoffCriteria int null, CutoffValue nvarchar(50) null, 
 	  	  	  	 RangeAlarm tinyint NULL, MasterPUId int NULL, VarCommentId int NULL, 
 	  	  	  	 TemplateVarCommentId int NULL,ATSRDId int NULL,CutoffVarDesc nvarchar(255) NULL, 
 	  	  	  	 LatestTime datetime NULL, EGId int null, LowerEntryRuleId int null,
 	  	  	  	 LowerRejectRuleId int null, LowerWarningRuleId int null, LowerUserRuleId int null, 
 	  	  	  	 TargetRuleId int null, UpperUserRuleId int null, UpperWarningRuleId int null, 
 	  	  	  	 UpperRejectRuleId int null, UpperEntryRuleId int null, ATVRDId int NULL, StringSpecSetting int NULL,SPName nvarchar(255) NULL,
 	  	  	  	 TimeZone nvarchar(100) NULL, DataTypeId int, EventType int, UseAppliedProduct int, EmailTableId int)
Insert Into @AGVATheResults(VarId, VarDesc, PUId, MasterPUId, ATDId, Priority, ATId, AlarmDesc, SamplingType, CutoffVarId,
 	  	  	  	  	  	  	 CutoffCriteria, CutoffValue, VarCommentId, TemplateVarCommentId, EGId, ATVRDId, RangeAlarm,
 	  	  	  	  	  	  	 StringSpecSetting, SPName, TimeZone, DataTypeId, EventType,UseAppliedProduct, EmailTableId) 
Select 
  ATV.Var_Id,
  v.var_desc,
  p.PU_Id, 
  COALESCE(Master_Unit, p.PU_Id), 
  ATD_Id,
  ap_id,
  atv.AT_Id,
  Alarm_Desc = AT_Desc,
  v.Sampling_Type,
  coalesce (atv.Override_DQ_Var_Id, DQ_Var_Id),
  coalesce (atv.Override_DQ_Criteria, DQ_Criteria),
  coalesce (atv.Override_DQ_Value, DQ_Value),
  v.Comment_Id,
  atv.Comment_Id,
  atv.eg_id,
  atv.atvrd_id,
  RangeAlarm = 
 	    CASE
 	      WHEN v.Data_Type_Id = 3 THEN 0
 	      WHEN v.Data_Type_Id >= 50 THEN 2
 	      ELSE 1
 	    END,
  v.String_Specification_Setting,
  t.SP_Name,
  dbo.fnServer_GetTimeZone(p.PU_Id),
  v.Data_Type_Id,
  v.Event_Type,
  @SupportAppliedProdFlag as UseAppliedProduct,
  t.Email_Table_Id
 FROM   Alarm_Templates t 
 JOIN   Alarm_Template_Var_Data ATV on t.AT_Id = ATV.AT_Id
 JOIN   Variables_Base V on V.Var_Id = ATV.Var_Id
 JOIN   Prod_Units_Base P on p.PU_Id = v.PU_Id
 where  t.alarm_type_id = 1 and atv.ATVRD_Id is not Null
SET @End = @@ROWCOUNT 
SET @Current = 1
WHILE  @Current <=@End
BEGIN
 	 SET @CutoffVarDesc = Null
 	 SET  @varid = Null
 	 SET @ATDId = Null
 	 SET @CutoffVarId = Null
 	 SET @ATVRuleId = Null
 	 SET @StartTime=Null
 	 SET @EndTime = Null
 	 SELECT @varid = varid, @ATDId = atdid, @CutoffVarId = CutoffVarId, @ATVRuleId = ATVRDId 
 	  	 FROM @AGVATheResults WHERE myId = @Current
 	  	 EXECUTE spServer_CmnAlarmDesc @ATDId, @AlarmDesc output, NULL, @ATVRuleId
 	   IF @CutoffVarId is not null
 	   BEGIN
 	     select @CutoffVarDesc=var_desc from Variables_Base where var_id=@CutoffVarId
 	   END
 	   SELECT @StartTime=max(Start_Time) from alarms where atd_id=@atdid and key_id = @varid and Alarm_Type_Id=1
 	   IF (@StartTime is not null)
 	   BEGIN
 	  	  	 select @EndTime=End_Time from alarms where atd_id=@atdid and Start_Time = @StartTime  and key_id = @varid and Alarm_Type_Id=1
 	  	  	 if (@EndTime is not null)
 	  	  	  	 select @StartTime = @EndTime
   	 END
    UPDATE @AGVATheResults set AlarmDesc=@AlarmDesc,CutoffVarDesc=@CutoffVarDesc,LatestTime=@StartTime
       where myId = @Current
 	 SET @Current = @Current + 1 	 
END
INSERT INTO @atids(atid)
 	 SELECT DISTINCT atid from @AGVATheResults
SET @End = @@ROWCOUNT
SET @Current = 1
WHILE  @Current <=@End
BEGIN
 	 SET @atid = Null
 	 SELECT @atid = atid FROM @atids WHERE myId = @Current
 	 DELETE FROM @ATVRD
 	 INSERT INTO @ATVRD(alarm_variable_rule_id,atvrd_id)
     	 Select alarm_variable_rule_id, atvrd_id from  alarm_template_variable_rule_Data where at_id = @atid
  IF @@ROWCOUNT > 0
  BEGIN
 	  	 SELECT @End1 = MAX(myId) FROM  @ATVRD
 	  	 SELECT @Current1 = Min(myId) FROM  @ATVRD
 	  	 WHILE  @Current1 <=@End1
 	  	 BEGIN
 	  	  	 SELECT  @RuleId = Null ,@ATVRuleId = Null
 	  	  	 SELECT @RuleId = alarm_variable_rule_id, @ATVRuleId = atvrd_id FROM @ATVRD WHERE myId = @Current1
 	  	  	 if (@RuleId = 1) 	 update @AGVATheResults set LowerEntry=1,  	 LowerEntryRuleId=@ATVRuleId  	  	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 2) 	 update @AGVATheResults set LowerReject=1, LowerRejectRuleId=@ATVRuleId   	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 3) 	 update @AGVATheResults set LowerWarning=1,LowerWarningRuleId=@ATVRuleId  where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 4) 	 update @AGVATheResults set LowerUser=1,  	 LowerUserRuleId=@ATVRuleId  	   	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 5) 	 update @AGVATheResults set Target=1,  	  	  	 TargetRuleId=@ATVRuleId   	  	  	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 6) 	 update @AGVATheResults set UpperUser=1,   	 UpperUserRuleId=@ATVRuleId   	  	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 7) 	 update @AGVATheResults set UpperWarning=1,UpperWarningRuleId=@ATVRuleId  where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 8) 	 update @AGVATheResults set UpperReject=1, UpperRejectRuleId=@ATVRuleId   	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 if (@RuleId = 9) 	 update @AGVATheResults set UpperEntry=1,  	 UpperEntryRuleId=@ATVRuleId   	 where ATId=@ATId and ATVRDId=@ATVRuleId
 	  	  	 SELECT @Current1 = @Current1 + 1
 	  	 END
 	 END
 	 SET @Current = @Current + 1 	 
END
select VarId, MasterPUId, ATDId, Priority, ATId, AlarmDesc, LowerEntry, 
 	  	 LowerReject, LowerWarning, LowerUser, Target, UpperUser, UpperWarning, 
 	  	 UpperReject, UpperEntry, SamplingType, CutoffVarId, CutoffCriteria, 
 	  	 CutoffValue,RangeAlarm,PUId,VarCommentId,TemplateVarCommentId, vardesc, CutoffVarDesc, LatestTime, EGId,
 	  	 LowerEntryRuleId, LowerRejectRuleId, LowerWarningRuleId, LowerUserRuleId, 
 	  	 TargetRuleId, UpperUserRuleId, UpperWarningRuleId, 
 	  	 UpperRejectRuleId, UpperEntryRuleId, StringSpecSetting,SPName,TimeZone,DataTypeId,EventType,UseAppliedProduct,
 	  	 EmailTableId
 	  	 from @AGVATheResults
 	  	 

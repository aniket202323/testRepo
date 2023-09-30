create PROCEDURE dbo.spServer_AMgrGetSPCAlarms
 AS
declare
  @@varid int,
  @@Cutoffvarid int,
  @@ATDId int,
  @result nvarchar(25),
  @AlarmMax nvarchar(25),
  @AlarmMin nvarchar(25),
  @StartResult nvarchar(25),
  @EndResult nvarchar(25),
  @result_on datetime,
  @StartTime datetime,
  @EndTime datetime,
  @UserId int,
  @@atsrdid int,
  @AlarmDesc nVarChar(1000),
  @CutoffVarDesc nVarChar(255),
  @SupportAppliedProdFlag int,
  @Value varchar(5000)
DECLARE @Start Int
DECLARE @End Int
Set NoCount On
select @SupportAppliedProdFlag = 0
select @Value = Null
exec spServer_CmnGetParameter 196, 20, HOST_NAME, @Value OUTPUT
if @Value is not null and @value = '1'
   select @SupportAppliedProdFlag = 1
declare @AGVATheResults table(Id Int Identity(1,1) primary key,VarId int, VarDesc nvarchar(255), PUId int, ATDId int NULL, Priority int NULL, ATId int NULL, 
 	  	  	 AlarmDesc nvarchar(1000) NULL, SamplingType int NULL, 
 	  	  	 CutoffVarId int null, CutoffCriteria int null, CutoffValue nvarchar(50) null, 
 	  	  	 RangeAlarm tinyint NULL, atsrd_id int NULL, atsrd_value nvarchar(30) NULL, atsrd_mvalue nVarChar(30) NULL, 
 	  	  	 SPCFiringPriority int null, MasterPUId int NULL, VarCommentId int NULL, 
 	  	  	 TemplateVarCommentId int NULL, SPC_alarm_rule_id int NULL,CutoffVarDesc nvarchar(255) NULL, 
 	  	  	 LatestTime datetime NULL, AlarmType int null, EGId int null, SPName nvarchar(255) NULL,TimeZone nvarchar(100) NULL,
 	  	  	 DataTypeId int, StringSpecSetting int NULL, EventType int, UseAppliedProduct int, SampleSize int, EmailTableId int,DeptID Int)
declare @DisabledProducts table(atsrd_id int NULL, Prod_Id int)
Insert Into @AGVATheResults(VarId, VarDesc, PUId,MasterPUId, ATDId, Priority, ATId, AlarmDesc, SamplingType, CutoffVarId,
 	  	  	  	  	  	  	 CutoffCriteria, CutoffValue, RangeAlarm, atsrd_id, atsrd_value, atsrd_mvalue, SPCFiringPriority,
 	  	  	  	  	  	  	 VarCommentId, TemplateVarCommentId, SPC_alarm_rule_id, EGId, SPName, TimeZone, DataTypeId, StringSpecSetting,
 	  	  	  	  	  	  	 EventType, UseAppliedProduct, SampleSize, EmailTableId)
Select ATV.Var_Id,
       v.Var_Desc,
       p.PU_Id, 
       COALESCE(Master_Unit, p.PU_Id), 
       ATD_Id,
       coalesce(rd.ap_id, t.ap_id),
       atv.AT_Id,
       Alarm_Desc = AT_Desc,
       v.Sampling_Type,
       coalesce (atv.Override_DQ_Var_Id, DQ_Var_Id),
       coalesce (atv.Override_DQ_Criteria, DQ_Criteria),
       coalesce (atv.Override_DQ_Value, DQ_Value),
       RangeAlarm = CASE
                      WHEN v.Data_Type_Id = 3 THEN 0
 	                   WHEN v.Data_Type_Id >= 50 THEN 2
 	                   ELSE 1
 	                 END,
       rd.atsrd_id,
       rpd.value,
       rpd.mvalue,
       rd.Firing_priority,
       v.Comment_Id,
       atv.Comment_Id,
       rd.alarm_spc_rule_id,
       atv.EG_Id,
       t.SP_Name,
       dp.Time_Zone,
       v.Data_Type_Id,
       v.String_Specification_Setting,
       v.Event_Type,
       @SupportAppliedProdFlag as UseAppliedProduct,
       coalesce (ATV.Sampling_Size, 0),
       t.Email_Table_Id
  FROM Alarm_Templates t 
  JOIN Alarm_Template_Var_Data ATV on t.AT_Id = ATV.AT_Id
  JOIN Variables_Base V on V.Var_Id = ATV.Var_Id
  JOIN Prod_Units_Base P on p.PU_Id = v.PU_Id
  JOIN alarm_template_spc_rule_data rd on rd.at_Id = t.at_Id and rd.atsrd_id = atv.atsrd_id
  JOIN alarm_template_SPC_rule_property_data rpd on rd.atsrd_id = rpd.atsrd_id
  Join Prod_Lines_Base pl on pl.PL_Id = p.PL_Id 
  JOIN Departments_Base dp on dp.Dept_Id = pl.Dept_Id 
  WHERE t.alarm_type_id = 4
Union
Select ATV.Var_Id,
       v.Var_Desc,
       MasterPU_Id = COALESCE(p.PU_Id,Master_Unit), 
       PU_Id = COALESCE(Master_Unit, p.PU_Id), 
       ATD_Id,
       coalesce(rd.ap_id, t.ap_id),
       atv.AT_Id,
       Alarm_Desc = AT_Desc,
       v.Sampling_Type,
       coalesce (atv.Override_DQ_Var_Id, DQ_Var_Id),
       coalesce (atv.Override_DQ_Criteria, DQ_Criteria),
       coalesce (atv.Override_DQ_Value, DQ_Value),
       RangeAlarm = CASE
                      WHEN v.Data_Type_Id = 3 THEN 0
                      WHEN v.Data_Type_Id >= 50 THEN 0
                      ELSE 1
                    END,
       rd.atsrd_id,
       rpd.value,
       rpd.mvalue,
       rd.Firing_priority,
       v.Comment_Id,
       atv.Comment_Id,
       rd.alarm_spc_rule_id,
       atv.EG_Id,
       t.SP_Name,
       dp.Time_Zone,
       v.Data_Type_Id,
       v.String_Specification_Setting,
       v.Event_Type,
       @SupportAppliedProdFlag as UseAppliedProduct,
       coalesce (ATV.Sampling_Size, 0),
       t.Email_Table_Id
  FROM Alarm_Templates t 
  JOIN Alarm_Template_Var_Data ATV on t.AT_Id = ATV.AT_Id
  JOIN Variables_Base V on V.Var_Id = ATV.Var_Id
  JOIN Prod_Units_Base P on p.PU_Id = v.PU_Id
  JOIN alarm_template_spc_rule_data rd on rd.at_Id = t.at_Id
  JOIN alarm_template_SPC_rule_property_data rpd on rd.atsrd_id = rpd.atsrd_id
  Join Prod_Lines_Base pl on pl.PL_Id = p.PL_Id 
  JOIN Departments_Base dp on dp.Dept_Id = pl.Dept_Id 
  WHERE t.alarm_type_id = 2
SET @End = @@ROWCOUNT
SET @Start = 1
WHILE @Start <= @end
BEGIN
 	 Select @@varid = varid, @@ATDId = atdid, @@CutoffVarId = CutoffVarId, @@atsrdid = atsrd_id from @AGVATheResults Where Id = @Start
 	 exec spServer_CmnAlarmDesc @@ATDId, @AlarmDesc output, @@atsrdid
 	 update @AGVATheResults set AlarmDesc=@AlarmDesc where Id = @Start
 	 if @@CutoffVarId is not null
 	 begin
 	  	 select @CutoffVarDesc=var_desc from Variables_Base where var_id=@@CutoffVarId
 	  	 update @AGVATheResults set CutoffVarDesc=@CutoffVarDesc where  Id = @Start
 	 end
 	 select @StartTime=NULL
 	 select @StartTime=max(Start_Time) from alarms where atd_id=@@atdid  and key_id = @@varid and Alarm_Type_Id=1
 	 if (@StartTime is not null)
 	 BEGIN
 	  	 select @EndTime=End_Time from alarms where atd_id=@@atdid and Start_Time = @StartTime and key_id = @@varid and Alarm_Type_Id=2
 	  	 if (@EndTime is not null) 	 select @StartTime = @EndTime
 	  	 update @AGVATheResults set LatestTime=@StartTime where  Id = @Start
 	 END
 	 SET @Start = @Start + 1
END
-- Get rid of the group alarms themselves
delete from @AGVATheResults where atdid in (select atd_id from Alarm_Template_Var_Data atv join alarm_templates a on a.at_id = atv.at_id  and a.alarm_type_id=4 and atsrd_id is null)
select 	 VarId, atsrd_id, atsrd_value, MasterPUId, ATDId, Priority, ATId, 
 	  	 AlarmDesc, SamplingType, CutoffVarId, CutoffCriteria, CutoffValue,
 	  	 RangeAlarm,SPCFiringPriority, PUId, VarCommentId, 
 	  	 TemplateVarCommentId, SPC_alarm_rule_id, vardesc, CutoffVarDesc,
 	  	 atsrd_mvalue, LatestTime, EGId, SPName, TimeZone, DataTypeId,
 	  	 StringSpecSetting, EventType, UseAppliedProduct, SampleSize, EmailTableId
 	 from @AGVATheResults 
 	 order by varid, atdid, SPCFiringPriority
--Disabled products
insert into @DisabledProducts(atsrd_id, Prod_Id)
select r.atsrd_id, p.Prod_Id
  from @AGVATheResults r
  join Alarm_SPC_Disabled_Products p on p.atsrd_id = r.atsrd_id
select atsrd_id, Prod_Id from @DisabledProducts

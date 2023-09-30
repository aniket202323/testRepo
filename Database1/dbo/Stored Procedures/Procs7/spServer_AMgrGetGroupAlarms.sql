CREATE PROCEDURE dbo.spServer_AMgrGetGroupAlarms
 AS
declare
  @@varid int,
  @@Cutoffvarid int,
  @@ATDId int,
  @@ATId int,
  @result nvarchar(25),
  @AlarmMax nvarchar(25),
  @AlarmMin nvarchar(25),
  @StartResult nvarchar(25),
  @EndResult nvarchar(25),
  @result_on datetime,
  @StartTime datetime,
  @EndTime datetime,
  @UserId int,
  @GroupATDId int,
  @@atsrdid int,
  @AlarmDesc nVarChar(1000),
  @CutoffVarDesc nVarChar(255),
  @SupportAppliedProdFlag int,
  @Value varchar(5000)
set NoCount On
select @SupportAppliedProdFlag = 0
select @Value = Null
exec spServer_CmnGetParameter 196, 20, HOST_NAME, @Value OUTPUT
if @Value is not null and @value = '1'
   select @SupportAppliedProdFlag = 1
declare @AGVATheResults table(VarId int, VarDesc nvarchar(255), PUId int, ATDId int NULL, Priority int NULL, ATId int NULL, 
 	  	  	 AlarmDesc nvarchar(1000) NULL, SamplingType int NULL, 
 	  	  	 CutoffVarId int null, CutoffCriteria int null, CutoffValue nvarchar(50) null, 
 	  	  	 RangeAlarm tinyint NULL, atsrd_id int NULL, atsrd_value nvarchar(30) NULL, atsrd_mvalue nvarchar(30) NULL, 
 	  	  	 SPCFiringPriority int null, MasterPUId int NULL, VarCommentId int NULL, 
 	  	  	 TemplateVarCommentId int NULL, SPC_alarm_rule_id int NULL,CutoffVarDesc nvarchar(255) NULL, LatestTime datetime NULL, 
 	  	  	 AlarmType int null, GroupATDId int null, EGId int null, SPName nvarchar(255) NULL,TimeZone nvarchar(100) NULL,
 	  	  	 DataTypeId int, EventType int, UseAppliedProduct int, EmailTableId int)
Insert Into @AGVATheResults(VarId, VarDesc, PUId, MasterPUId, ATDId, Priority, ATId, AlarmDesc, SamplingType, CutoffVarId,
 	  	  	  	  	  	  	 CutoffCriteria, CutoffValue, RangeAlarm, atsrd_id, atsrd_value, atsrd_mvalue, SPCFiringPriority,
 	  	  	  	  	  	  	 VarCommentId, TemplateVarCommentId, SPC_alarm_rule_id, EGId, SPName,TimeZone, DataTypeId, EventType,
 	  	  	  	  	  	  	 UseAppliedProduct, EmailTableId) 
Select 
  ATV.Var_Id,
  v.Var_Desc,
  p.PU_Id, 
  COALESCE(Master_Unit, p.PU_Id), 
  ATD_Id,
  rd.ap_id,
  atv.AT_Id,
  Alarm_Desc = AT_Desc,
  v.Sampling_Type,
  coalesce (atv.Override_DQ_Var_Id, DQ_Var_Id),
  coalesce (atv.Override_DQ_Criteria, DQ_Criteria),
  coalesce (atv.Override_DQ_Value, DQ_Value),
  RangeAlarm = 
 	    CASE
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
  atv.eg_id,
  t.SP_Name,
  dbo.fnServer_GetTimeZone(p.pu_id),
  v.Data_Type_Id,
  v.Event_Type,
  @SupportAppliedProdFlag as UseAppliedProduct,
  t.Email_Table_Id
 FROM   Alarm_Templates t 
 JOIN   Alarm_Template_Var_Data ATV on t.AT_Id = ATV.AT_Id
 JOIN   Variables_Base V on V.Var_Id = ATV.Var_Id
 JOIN   Prod_Units_Base P on p.PU_Id = v.PU_Id
 JOIN   alarm_template_spc_rule_data rd on rd.at_Id = t.at_Id --and (rd.atsrd_id = atv.atsrd_id or atv.atsrd_id is null)
 JOIN   alarm_template_SPC_rule_property_data rpd on rd.atsrd_id = rpd.atsrd_id
 where  t.alarm_type_id = 4 
Declare xxx_Cursor INSENSITIVE CURSOR 
  For (Select varid, atdid, atid, CutoffVarId, atsrd_id from @AGVATheResults)
  For Read Only
Open xxx_Cursor  
Fetch_Loop:
  Fetch Next From xxx_Cursor Into @@varid, @@ATDId, @@atid, @@CutoffVarId, @@atsrdid
  If (@@Fetch_Status = 0)
    Begin
      exec spServer_CmnAlarmDesc @@ATDId, @AlarmDesc output, @@atsrdid
      update @AGVATheResults set AlarmDesc=@AlarmDesc where varid = @@varid and ATDId=@@ATDId  and ATSRD_Id = @@atsrdid
   	   if @@CutoffVarId is not null
   	   begin
   	     select @CutoffVarDesc=var_desc from Variables_Base where var_id=@@CutoffVarId
   	  	   update @AGVATheResults set CutoffVarDesc=@CutoffVarDesc where varid = @@varid and ATDId=@@ATDId
   	   end
   	   select @StartTime=NULL
   	   select @StartTime=max(Start_Time) from alarms where atd_id=@@atdid
   	   if (@StartTime is not null)
   	   begin
        select @EndTime=End_Time from alarms where atd_id=@@atdid and Start_Time = @StartTime
   	  	   if (@EndTime is not null)
   	  	     select @StartTime = @EndTime
   	  	   update @AGVATheResults set LatestTime=@StartTime where varid = @@varid and ATDId=@@ATDId
   	   end
      select @GroupATDId=NULL
      select @GroupATDId=atv.atd_id from Alarm_Template_Var_Data atv 
   	 join variables_base v on v.Var_Id = @@varid
 	 where atv.at_id = @@ATID and atv.var_id=v.PVar_id and atsrd_id is null and v.PVar_id is not null
      if @GroupATDId is null
         select @GroupATDId=atv.atd_id from Alarm_Template_Var_Data atv 
     	    where atv.var_id=@@varid and atv.at_id = @@ATID and atsrd_id is null 
      update @AGVATheResults set GroupATDId=@GroupATDID where varid = @@varid and ATDId=@@ATDId
      Goto Fetch_Loop
    End
Close xxx_Cursor 
Deallocate xxx_Cursor
select 	 VarId, GroupATDId, MasterPUId, Priority, ATId, 
        AlarmDesc, SamplingType, CutoffVarId, CutoffCriteria, CutoffValue,
        RangeAlarm, PUId, VarCommentId, TemplateVarCommentId, SPC_alarm_rule_id, vardesc, CutoffVarDesc, 
        LatestTime, ATDId, atsrd_id, SPCFiringPriority, EGId, SPName, TimeZone,DataTypeId,EventType,UseAppliedProduct,
        EmailTableId
      from @AGVATheResults 
  order by GroupATDID, varid, atdid, SPCFiringPriority

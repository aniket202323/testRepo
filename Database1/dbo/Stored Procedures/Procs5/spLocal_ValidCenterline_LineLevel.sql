    CREATE   Procedure dbo.spLocal_ValidCenterline_LineLevel  
/*  
Stored Procedure  :  spLocal_ValidCenterline_UnitLevel  
Author     :  Matthew Wells (MSI)  
Date Created   :  11/27/01  
SP Type     :  CalculationMgr  
Editor Tab Spacing :  3  
  
Description:  
===========  
Returns a bit indicating whether the downtime alarming can be activated.  Returns a 1 if valid and 0 if not.  
  
CALLED BY    : Proficy Calculation (Valid Centerline Switch)  
  
  
Revision    Date    Who       What  
========  =========== ==================  =================================================================================  
N/A    11/27/01   MKW       Created procedure  
N/A    02/22/02   MKW       Modified select statement to check for downtimes less than the TimeStamp in case of reruns.  
N/A    07/17/02   MKW       Added check for product change and if so set valid centerline to 0 to clear out alarms.  
1.1.0    01/31/06   MC-STI      Added variable result set #6 to force all opened alarms to close in case of downtime  
                  or brand change  
1.2.0    2006-09-22  Marc Charest    SELECT, JOIN and GROUP BY statements have been revisited to speed up SP.  
  
  
*/  
@Output_Value     integer OUTPUT,  
@Var_Id       integer,  
@TimeStamp      datetime,  
@Downtime_PU_Id    integer,  
@Periods_Str     varchar(25),  
@intCommentID     integer  
  
as  
  
set nocount on  
  
Declare   
 @Sampling_Interval  integer,  
 @Var_PU_Id     integer,  
 @Downtime_End_Time  datetime,  
 @Product_Start_Time  datetime,  
 @Search_TimeStamp   datetime,  
 @Periods      integer,  
 @TEDet_Id     integer,  
 @intPLID      integer  
  
declare @Alarms table(  
 PreUpdate     integer DEFAULT 0,  
 TransNum      integer NULL,  
 AlarmId      integer NULL,  
 ATDId       integer NULL,  
 StartTime     varchar(50) NULL,  
 EndTime      varchar(50) NULL,  
 Duration      float NULL,  
 Ack       bit DEFAULT 0,  
 AckOn       varchar(50) NULL,  
 AckBy       integer NULL,  
 StartResult     varchar(50) NULL,  
 EndResult     varchar(50) NULL,  
 MinResult     varchar(50) NULL,  
 MaxResult     varchar(50) NULL,  
 Cause1      integer NULL,  
 Cause2      integer NULL,  
 Cause3      integer NULL,  
 Cause4      integer NULL,  
 CauseCommentId    integer NULL,  
 Action1      integer NULL,  
 Action2      integer NULL,  
 Action3      integer NULL,  
 Action4      integer NULL,  
 ActionCommentId   integer NULL,  
 ResearchUserId    integer NULL,  
 ResearchStatusId   integer NULL,  
 ResearchOpenDate   varchar(50) NULL,  
 ResearchCloseDate   varchar(50) NULL,  
 ResearchCommentId   integer NULL,  
 SourcePUId     integer NULL,  
 AlarmTypeId     integer NULL,  
 KeyId       integer NULL,  
 AlarmDesc     char(1000),  
 TransType     integer NULL,  
 TemplateVariableCommentId integer NULL,  
 APId       integer NULL,  
 ATId       integer NULL,  
 VarCommentId    integer NULL,  
 Cutoff      tinyint NULL  
)  
  
  
/* Initialization */  
If IsNumeric(@Periods_Str) = 1 begin  
 Select @Periods = convert(int, @Periods_Str) end  
Else begin  
 Select @Periods = 0  
end  
  
  
  
/*****************************************************************************************************************  
*  
* Get variable's sampling window & prod unit  
*  
******************************************************************************************************************/  
Select @Sampling_Interval = Sampling_Interval, @Var_PU_Id= PU_ID  
From dbo.Variables  
Where Var_Id = @Var_Id  
  
  
  
/*****************************************************************************************************************  
*  
* Get downtime end time  
*  
******************************************************************************************************************/  
Select TOP 1 @TEDet_Id = TEDet_Id, @Downtime_End_Time = End_Time  
From dbo.Timed_Event_Details  
Where PU_Id = @Downtime_PU_Id And Start_Time < @TimeStamp  
Order By Start_Time Desc  
  
  
/*****************************************************************************************************************  
*  
* Get product change time  
*  
******************************************************************************************************************/  
Select @Search_TimeStamp = dateadd(s, 60, @TimeStamp) -- Needed for pre-215 product/time records b/c of the :59 second thing (in 215 can reduce to 1 sec)  
Select @Product_Start_Time = Start_Time  
From dbo.Production_Starts  
Where PU_Id = @Var_PU_Id And Start_Time <= @Search_TimeStamp And (End_Time > @Search_TimeStamp Or End_Time Is Null)  
  
  
/*****************************************************************************************************************  
*  
* Case of grade change or downtime: Forcing all opened alarms to close. End time for each alarm  
*            is the time of the last OOS value.  
*  
******************************************************************************************************************/  
If (datediff(mi, @Product_Start_Time, @TimeStamp) < @Sampling_Interval * @Periods) Or (@TEDet_Id Is Not Null And   
   (@Downtime_End_Time Is Null Or datediff(mi, @Downtime_End_Time, @TimeStamp) < @Sampling_Interval * @Periods)) begin  
  
 set @intPLID = (select pl_id from dbo.prod_units where pu_id = @Var_pu_id)  
  
 --putting apart values for alarms result set  
 insert @Alarms(  
  PreUpdate,  
  TransNum,  
  AlarmId,  
  ATDId,  
  StartTime,  
  EndTime,  
  Duration,  
  Ack,  
  AckOn,  
  AckBy,  
  StartResult,  
  EndResult,  
  MinResult,  
  MaxResult,  
  Cause1,  
  Cause2,  
  Cause3,  
  Cause4,  
  CauseCommentId,  
  Action1,  
  Action2,  
  Action3,  
  Action4,  
  ActionCommentId,  
  ResearchUserId,  
  ResearchStatusId,  
  ResearchOpenDate,  
  ResearchCloseDate,  
  ResearchCommentId,  
  SourcePUId,  
  AlarmTypeId,  
  KeyId,  
  AlarmDesc,  
  TransType,  
  TemplateVariableCommentId,  
  APId,  
  ATId,  
  VarCommentId,  
  Cutoff)  
 select  
  0,  
  null,  
  a.Alarm_Id,  
  atvd.atd_id,  
  a.Start_Time,  
  max(t.result_on),  
  0,  
  a.Ack,  
  a.Ack_On,  
  a.Ack_By,  
  a.Start_Result,  
  a.Start_Result,  
  a.Min_Result,  
  a.Max_Result,  
  a.Cause1,  
  a.Cause2,  
  a.Cause3,  
  a.Cause4,  
  @intCommentID, --169647,  
  a.Action1,  
  a.Action2,  
  a.Action3,  
  a.Action4,  
  a.action_comment_id,  
  a.Research_User_Id,  
  a.Research_Status_Id,  
  a.Research_Open_Date,  
  a.Research_Close_Date,  
  a.Research_Comment_Id,  
  a.Source_PU_Id,  
  a.Alarm_Type_Id,  
  atvd.Var_Id,  
  a.Alarm_Desc,  
  2,  
  at.Comment_Id,  
  at.AP_Id,  
  at.AT_Id,  
  null, --v.Comment_Id,  
  a.Cutoff  
 from   
  dbo.alarm_templates at  
  join dbo.alarm_template_var_data atvd on (at.at_id = atvd.at_id)  
  join dbo.alarms a on (a.key_id = atvd.var_id and a.atd_id = atvd.atd_id and start_time is not null and end_time is null)  
  left join dbo.tests t on (t.var_id = a.key_id  and result is not null)  
  left join dbo.variables v on (t.var_id = v.var_id)  
  join dbo.prod_units pu on (v.pu_id = pu.pu_id and pu.pl_id = @intPLID)  
  
/*  
  dbo.alarm_templates at  
  left join dbo.alarm_template_var_data atvd on (at.at_id = atvd.at_id)  
  left join dbo.alarm_priorities ap on (at.ap_id = ap.ap_id)  
  left join dbo.alarms a on (a.key_id = atvd.var_id and start_time is not null and end_time is null)  
  left join dbo.tests t on (t.var_id = a.key_id and result is not null)  
  left join dbo.variables v on (t.var_id = v.var_id and v.pu_id = @Var_pu_id)  
  left join dbo.prod_units pu on (v.pu_id = pu.pu_id and pu.pl_id = @intPLID)  
*/  
  
 where  
  a.alarm_id is not null  
 group by  
  a.Alarm_Id,  
  atvd.atd_id,  
  a.Start_Time,  
  a.Ack,  
  a.Ack_On,  
  a.Ack_By,  
  a.Start_Result,  
  a.Start_Result,  
  a.Min_Result,  
  a.Max_Result,  
  a.Cause1,  
  a.Cause2,  
  a.Cause3,  
  a.Cause4,  
  a.Action1,  
  a.Action2,  
  a.Action3,  
  a.Action4,  
  a.action_comment_id,  
  a.Research_User_Id,  
  a.Research_Status_Id,  
  a.Research_Open_Date,  
  a.Research_Close_Date,  
  a.Research_Comment_Id,  
  a.Source_PU_Id,  
  a.Alarm_Type_Id,  
  atvd.Var_Id,  
  a.Alarm_Desc,  
  at.Comment_Id,  
  at.AP_Id,  
  at.AT_Id,  
  --v.Comment_Id,  
  a.Cutoff  
  
 --updating alarms table (need this because of RS #6 lacks)  
 update dbo.alarms  
 set  
  end_time = a1.EndTime,  
  end_result = a1.EndResult,  
  cause_comment_id = @intCommentID  --169647  
 from   
  dbo.alarms a0,  
  @Alarms a1  
 where  
  a1.AlarmId = a0.alarm_id  
   
 --executing alarms result set  
 select 6, * from @Alarms  
  
 select @Output_Value = '0' end  
  
else begin  
  
 select @Output_Value = '1'  
  
end  
  
set nocount off  
  
  
  
  
  
  

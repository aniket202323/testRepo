CREATE Procedure dbo.spDBR_AlarmDrill
@Unit int,
@EventNumber varchar(100),
@FilterNonProductiveTime int = 0,
@InTimeZone varchar(200)=''
AS
--**************************************************/
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Declare @Unit int
Declare @EventNumber varchar(100)
Select @Unit = 2
Select @EventNumber = 'P12F0508'
--*****************************************************/
Create Table #Prompts (
  [qualityexceptions] varchar(50),
  [madeas]            varchar(50),
  [on]                varchar(50), 
  [at]                varchar(50),
  [currentexceptions] varchar(50),
  [priority]          varchar(50),
  [variable]          varchar(50),
  [message]           varchar(50),
  [value]             varchar(50),
  [lrl]               varchar(50),
  [lwl]               varchar(50),
  [tgt]               varchar(50),
  [uwl]               varchar(50),
  [url]               varchar(50),
  [comments]          varchar(50),
  [nocomments]        varchar(50),
  [history]           varchar(50),
  [signoff1]          varchar(50),
  [signoff2]          varchar(50)
)
create table #ProductiveTimes
(
  StartTime datetime,
  EndTime   datetime
)
insert into #Prompts ([qualityexceptions],[madeas],[on],[at],[currentexceptions],[priority],[variable],[message],[value],[lrl],[lwl],[tgt],[uwl],[url],[comments],[nocomments],[history], [signoff1], [signoff2])
 values (dbo.fnDBTranslate(N'0', 38408, 'Quality Exceptions For'),dbo.fnDBTranslate(N'0', 38409, 'Made As'),dbo.fnDBTranslate(N'0', 38410, 'On'),
  dbo.fnDBTranslate(N'0', 38411, 'at'), dbo.fnDBTranslate(N'0', 38412, 'Current Exception List'), dbo.fnDBTranslate(N'0', 38413, 'Priority'),
  dbo.fnDBTranslate(N'0', 38414, 'Variable'), dbo.fnDBTranslate(N'0', 38415, 'Message'), dbo.fnDBTranslate(N'0', 38416, 'Value'),
  dbo.fnDBTranslate(N'0', 38417, 'LRL'), dbo.fnDBTranslate(N'0', 38418, 'LWL'), dbo.fnDBTranslate(N'0', 38419, 'TGT'),
  dbo.fnDBTranslate(N'0', 38420, 'UWL'), dbo.fnDBTranslate(N'0', 38421, 'URL'), dbo.fnDBTranslate(N'0', 38422, 'Comments'),
  dbo.fnDBTranslate(N'0', 38423, 'No Available Comments.'), dbo.fnDBTranslate(N'0', 38424, 'History'), dbo.fnDBTranslate(N'0', 38492, 'User'), dbo.fnDBTranslate(N'0', 38493, 'Approver')
)
--*********************************************************************************
-- Return Resultset #1 - Resultset Name List
--*********************************************************************************
Declare @UnitName varchar(100)
Declare @EventName varchar(50)
Declare @EventTime datetime
Declare @ETYear int
Declare @ETMonth int
Declare @ETDay int
Declare @ETTimePart varchar(10)
Declare @ETHour int
Declare @ETMinute int
Declare @ETSecond int
Declare @STHour int
Declare @STMinute int
Declare @STSecond int
Declare @StartTime datetime
Declare @STYear int
Declare @STMonth int
Declare @STDay int
Declare @STTimePart varchar(10)
Declare @EndTime datetime
Declare @EventId int
Declare @ProductId int
Declare @CommentId int
Declare @ProductCode varchar(100)
Declare @InTimeZoneStartTime datetime
Declare @InTimeZoneEndTime datetime
Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @Unit
select @EventName = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @EventId = e.Event_Id,
       @EventTime = e.timestamp,
       @ETYear = datepart(year, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)),
       @ETMonth = datepart(month, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)),
       @ETDay = datepart(day, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)),
       @ETTimePart = case when datepart(hour,dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)) < 10 then '0' else '' end +  convert(varchar(2),datepart(hour,dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone))) + ':' + case when datepart(minute, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)) < 10 then '0' else '' end + convert(varchar(2), datepart(minute, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone))) + ':' + case when datepart(second, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)) < 10 then '0' else '' end +  convert(varchar(2), datepart(second, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone))),
       @ETHour = datepart(hour, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)),
       @ETMinute = datepart(minute, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)),
       @ETSecond = datepart(second, dbo.fnServer_CmnConvertFromDbTime(e.timestamp,@InTimeZone)),
       @STHour = datepart(hour, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ),
       @STMinute = datepart(minute,dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ),
       @STSecond = datepart(second, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ),
       @StartTime = e.start_time,
 	    @InTimeZoneStartTime = dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone)  ,     
       @STYear = datepart(year, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ),
       @STMonth = datepart(month, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ),
       @STDay = datepart(day, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ),
       @STTimePart = case when datepart(hour,dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ) < 10 then '0' else '' end +  convert(varchar(2),datepart(hour,dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) )) + ':' + case when datepart(minute, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ) < 10 then '0' else '' end + convert(varchar(2), datepart(minute, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) )) + ':' + case when datepart(second, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) ) < 10 then '0' else '' end +  convert(varchar(2), datepart(second, dbo.fnServer_cmnConvertFromDBTime(e.start_time,@InTimeZone) )),
       @ProductId = case when e.applied_product is null then ps.prod_id else e.applied_product end,
       @CommentId = e.comment_id
  From Events e
  join production_starts ps on ps.pu_id = @Unit and ps.start_time < e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
  Where e.PU_Id = @Unit and 
        e.Event_Num = @EventNumber      
If @EventId Is Null Return
Select @EndTime = @EventTime
Select @InTimeZoneEndTime = dbo.fnServer_CmnConvertFromDbTime(@EndTime,@InTimeZone)
If @StartTime Is Null
begin
  Select @StartTime = max(Timestamp) From Events Where PU_id = @Unit and Timestamp < @EventTime
  Select @InTimeZoneStartTime = dbo.fnServer_CmnConvertFromDbTime(max(Timestamp),@InTimeZone) From Events Where PU_id = @Unit and Timestamp < @EventTime
  Select @STYear = datepart(year, @InTimeZoneStartTime)
  Select @STMonth = datepart(month, @InTimeZoneStartTime)
  Select @STDay = datepart(day, @InTimeZoneStartTime)
  Select @STTimePart = case when datepart(hour,@InTimeZoneStartTime) < 10 then '0' else '' end +  convert(varchar(2),datepart(hour,@InTimeZoneStartTime)) + ':' + case when datepart(minute, @InTimeZoneStartTime) < 10 then '0' else '' end + convert(varchar(2), datepart(minute, @InTimeZoneStartTime)) + ':' + case when datepart(second, @InTimeZoneStartTime) < 10 then '0' else '' end +  convert(varchar(2), datepart(second, @InTimeZoneStartTime))
  Select @STHour = datepart(hour, @InTimeZoneStartTime)
  Select @STMinute = datepart(minute, @InTimeZoneStartTime)
  Select @STSecond = datepart(second, @InTimeZoneStartTime)
end
--WM 5/12/2013 Commenting this out, this filters out
-- all of the alarm detail rows in the where clause for the 2nd result set
--select @Starttime=@EndTime
select @InTimeZoneStartTime = dbo.fnServer_CmnConvertFromDBTime(@EndTime,@InTimeZone)
Select @ProductCode = Prod_Code
  From Products 
  Where Prod_Id = @ProductId
Select EventName = @EventName,
       EventNumber = @EventNumber,
       EventTime = dbo.fnServer_CmnConvertFromDBTime(@EventTime,@InTimeZone),
       EventYear = @ETYear,
       EventMonth = @ETMonth,
       EventDay = @ETDay,
       EventHour = @ETHour,
       EventMinute = @ETMinute,
       EventSecond = @ETSecond,
       EventTimePart = @ETTimePart,
       StartTime = @InTimeZoneStartTime,
       StartYear = @STYear,
       StartMonth = @STMonth,
       StartDay = @STDay,
       StartHour = @STHour,
       StartMinute = @STMinute,
       StartSecond = @STSecond,
       StartTimePart = @STTimePart,
       EndTime = @InTimeZoneEndTime,
       EventStatus = s.prodstatus_desc,
       ProductCode = @ProductCode,
       UnitName = @UnitName,
       1 as RSID
  From events e
  join production_status s on s.prodstatus_id = e.event_status
  where e.event_id = @EventId
If @StartTime Is Null
  Select @StartTime = max(Timestamp)
    From Events
    Where PU_Id = @Unit and
          Timestamp < @EndTime
if (@FilterNonProductiveTime = 1)
begin
 	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @Unit, @StartTime, @EndTime
end
else
begin
 	 insert into #ProductiveTimes (StartTime, EndTime) select @StartTime, @EndTime
end
--*********************************************************************************
-- Return Resultset #2 - Alarm Detail Listing
--*********************************************************************************
Create Table #Report
(
 	 PriorityId int,
    Priority varchar(50),
    Message varchar(100),
    Var_Id int,
    Var_Desc varchar(50),
    LRL float,
    LWL float,
    TGT varchar(50),
    UWL float,
    URL float,
    Signoff1 varchar(50),
    Signoff2 varchar(50)
)
declare @curStartTime datetime, @curEndTime datetime
Declare TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select StartTime, EndTime From #ProductiveTimes
      )
  For Read Only
  Open TIME_CURSOR  
BEGIN_TIME_CURSOR:
Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
--Variable Alarms
Insert Into #Report
  Select PriorityId = r.ap_id,
         Priority = p.ap_desc,
         Message = a.Alarm_Desc,
         Var_Id = a.Key_Id,
         Var_Desc = v.var_desc,
         LRL = vs.L_Reject,
         LWL = vs.L_Warning,
         TGT = vs.Target,
         UWL = vs.U_Warning,
         URL = vs.U_Reject,
         Signoff1 = user1.username,
         Signoff2 = user2.username
      From Alarms a
      Join Prod_Units u on u.PU_id = @Unit or u.Master_Unit = @Unit
      Join Variables v on v.pu_id = u.pu_id and v.var_id = a.key_id and a.Alarm_Type_Id in (1,2)
 	  	   left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
 	  	   left outer Join Alarm_Templates t on t.at_id = vd.at_id
 	  	   Left Outer Join Alarm_Template_Variable_Rule_Data r on r.atvrd_id = a.atvrd_id
      left outer Join Alarm_Priorities p on p.ap_id = r.ap_id
      left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @curEndTime and ((vs.expiration_date > @curEndTime) or (vs.expiration_date Is NULL))
      left outer join esignature e on e.signature_id = a.signature_id
      left outer join users user1 on user1.[user_id] = e.perform_user_id
      left outer join users user2 on user2.[user_id] = e.verify_user_id
      Where a.Start_Time between @curStartTime and @curEndTime and a.Alarm_Type_Id = 1
Union
  Select PriorityId = r.ap_id,
         Priority = p.ap_desc,
         Message = a.Alarm_Desc,
         Var_Id = a.Key_Id,
         Var_Desc = v.var_desc,
         LRL = vs.L_Reject,
         LWL = vs.L_Warning,
         TGT = vs.Target,
         UWL = vs.U_Warning,
         URL = vs.U_Reject,
         Signoff1 = user1.username,
         Signoff2 = user2.username
      From Alarms a
      Join Prod_Units u on u.PU_id = @Unit or u.Master_Unit = @Unit
      Join Variables v on v.pu_id = u.pu_id and v.var_id = a.key_id and a.Alarm_Type_Id in (1,2)
 	  	   left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
 	  	   left outer Join Alarm_Templates t on t.at_id = vd.at_id
 	  	   Left Outer Join Alarm_Template_Variable_Rule_Data r on r.atvrd_id = a.atvrd_id
      left outer Join Alarm_Priorities p on p.ap_id = r.ap_id
      left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @curEndTime and ((vs.expiration_date > @curEndTime) or (vs.expiration_date Is NULL))
      left outer join esignature e on e.signature_id = a.signature_id
      left outer join users user1 on user1.[user_id] = e.perform_user_id
      left outer join users user2 on user2.[user_id] = e.verify_user_id
      Where a.Start_Time < @curStartTime and ((a.end_time > @curEndTime) or (a.end_time is null))
        and a.Alarm_Type_Id = 1
--SPC Alarms
Insert Into #Report
  Select PriorityId = r.ap_id,
         Priority = p.ap_desc,
         Message = a.Alarm_Desc,
         Var_Id = a.Key_Id,
         Var_Desc = v.var_desc,
         LRL = vs.L_Reject,
         LWL = vs.L_Warning,
         TGT = vs.Target,
         UWL = vs.U_Warning,
         URL = vs.U_Reject,
         Signoff1 = user1.username,
         Signoff2 = user2.username
      From Alarms a
      Join Prod_Units u on u.PU_id = @Unit or u.Master_Unit = @Unit
      Join Variables v on v.pu_id = u.pu_id and v.var_id = a.key_id and a.Alarm_Type_Id in (1,2)
 	  	   left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
 	  	   left outer Join Alarm_Templates t on t.at_id = vd.at_id
 	  	   Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
      left outer Join Alarm_Priorities p on p.ap_id = r.ap_id
      left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @curEndTime and ((vs.expiration_date > @curEndTime) or (vs.expiration_date Is NULL))
      left outer join esignature e on e.signature_id = a.signature_id
      left outer join users user1 on user1.[user_id] = e.perform_user_id
      left outer join users user2 on user2.[user_id] = e.verify_user_id
      Where a.Start_Time between @curStartTime and @curEndTime and a.Alarm_Type_Id in (2,4)
Union
  Select PriorityId = r.ap_id,
         Priority = p.ap_desc,
         Message = a.Alarm_Desc,
         Var_Id = a.Key_Id,
         Var_Desc = v.var_desc,
         LRL = vs.L_Reject,
         LWL = vs.L_Warning,
         TGT = vs.Target,
         UWL = vs.U_Warning,
         URL = vs.U_Reject,
         Signoff1 = user1.username,
         Signoff2 = user2.username
      From Alarms a
      Join Prod_Units u on u.PU_id = @Unit or u.Master_Unit = @Unit
      Join Variables v on v.pu_id = u.pu_id and v.var_id = a.key_id and a.Alarm_Type_Id in (1,2)
 	  	   left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
 	  	   left outer Join Alarm_Templates t on t.at_id = vd.at_id
 	  	   Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
      left outer Join Alarm_Priorities p on p.ap_id = r.ap_id
      left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @curEndTime and ((vs.expiration_date > @curEndTime) or (vs.expiration_date Is NULL))
      left outer join esignature e on e.signature_id = a.signature_id
      left outer join users user1 on user1.[user_id] = e.perform_user_id
      left outer join users user2 on user2.[user_id] = e.verify_user_id
      Where a.Start_Time < @curStartTime and ((a.end_time > @curEndTime) or (a.end_time is null))
        and a.Alarm_Type_Id in (2,4)
     GOTO BEGIN_TIME_CURSOR
End
Close TIME_CURSOR
Deallocate TIME_CURSOR
Select #Report.*, Value = t.Result, 2 as RSID
  From #Report
  left outer Join Tests t on t.var_id = #Report.Var_id and t.Result_On = @EndTime
Drop Table #Report
--*********************************************************************************
-- Return Resultset #3 - Comment Listing
--*********************************************************************************
Create Table #Comments (
  Comment varchar(1000),
)
If @CommentId Is Not Null
  Insert Into #Comments
    Select Comment = @EventNumber + ' [' + u.username + ']>> ' + convert(varchar(900), comment_text)  
      From Comments c
      Join Users u on u.User_Id = c.User_Id
      Where Comment_Id = @CommentId    
Insert Into #Comments
  Select Comment = v.var_desc + ' [' + u.username + ']>> ' + convert(varchar(900), c.comment_text)
    From variables v
    join tests t on t.var_id = v.var_id and t.result_on = @EndTime  
    join Comments c on c.Comment_Id = t.Comment_id
    Join Users u on u.User_Id = t.entry_by
    where v.pu_id in (Select PU_Id From Prod_Units Where PU_Id = @Unit or Master_Unit = @Unit)      
Select *, 3 as RSID From #Comments
Drop Table #Comments
--*********************************************************************************
-- Return Resultset #4 - Update Messages
--*********************************************************************************
Select Message = '[' + u.Username + '] ' + dbo.fnDBTranslate(N'0', 34649, 'Updated') + ' ' + h.Event_Num + + ' (' + ps.ProdStatus_Desc + ') ' + dbo.fnDBTranslate(N'0', 38411, 'at') + ' ' + replace(convert(varchar(11),h.entry_on,106),' ','-') + ' ' + convert(varchar(8),h.entry_on,108) + ' ' + dbo.fnDBTranslate(N'0', 38509, 'as') + ' ' +  case When h.Applied_Product Is Null Then @ProductCode Else p.Prod_Code End, 4 as RSID
  From Event_History h
  Join Production_Status ps on ps.ProdStatus_Id = h.Event_Status
  Join Users u on u.User_id = h.User_id
  Left outer Join Products p on p.prod_id = h.Applied_Product  
  Where h.Event_id = @EventId
select * from #Prompts
Drop Table #Prompts
Drop Table #ProductiveTimes

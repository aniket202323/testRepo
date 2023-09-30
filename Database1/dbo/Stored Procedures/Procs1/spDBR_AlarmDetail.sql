Create Procedure dbo.spDBR_AlarmDetail
@Unit int,
@Event_Num varchar(100)
AS
SET ANSI_WARNINGS off
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Product int
--*************************************************
-- Select @Unit = 2
-- Select @Event_Num = 'P12E0418'
--*************************************************
Select @Product = NULL
Select @StartTime = NULL
Select @StartTime = Start_Time,
       @EndTime = Timestamp,
       @Product = Applied_Product
  From Events 
  Where PU_Id = @Unit and
        Event_Num = @Event_Num  
If @StartTime Is Null
  Select @StartTime = max(Timestamp)
    From Events
    Where PU_Id = @Unit and
          Timestamp < @EndTime
If @Product Is Null
  Select @Product = Prod_id
    From Production_Starts 
    Where PU_id = @Unit and
          Start_Time <= @EndTime and
          ((End_Time > @EndTime) or (End_Time Is Null))  
Create Table #Report (
  PriorityId int,
  Priority varchar(50),
  Message varchar(255),
  Var_Id int,
  LRL varchar(25),
  LWL varchar(25),
  TGT varchar(25),
  UWL varchar(25),
  URL varchar(25)
)
--Variable alarms
Insert Into #Report
  Select PriorityId = r.ap_id,
         Priority = p.ap_desc,
         Message = a.Alarm_Desc,
         Var_Id = a.Key_Id,
         LRL = vs.L_Reject,
         LWL = vs.L_Warning,
         TGT = vs.Target,
         UWL = vs.U_Warning,
         URL = vs.U_Reject
      From Alarms a
      Join Alarm_Template_Var_Data tv on tv.atd_id = a.atd_id
      Join Alarm_Templates t on t.at_id = tv.at_id
      Join Alarm_Priorities p on p.ap_id = t.ap_id
      Join Prod_Units u on u.PU_Id = @Unit or u.Master_Unit = @Unit  
      Join Variables v on v.pu_id = u.pu_id and v.var_id = a.key_id
      Join Alarm_Template_Variable_Rule_Data r on r.at_Id = t.at_id and r.atvrd_id = a.atvrd_id
      left outer join var_specs vs on vs.prod_id = @Product and vs.var_id = v.var_id and vs.effective_date <= @EndTime and ((vs.expiration_date > @EndTime) or (vs.expiration_date Is NULL))
      Where a.Alarm_Type_Id = 1 and
            a.Start_Time <= @EndTime and
            ((a.End_Time > @StartTime) or (a.End_Time Is Null)) 
--SPC alarms
Insert Into #Report
  Select PriorityId = r.ap_id,
         Priority = p.ap_desc,
         Message = a.Alarm_Desc,
         Var_Id = a.Key_Id,
         LRL = vs.L_Reject,
         LWL = vs.L_Warning,
         TGT = vs.Target,
         UWL = vs.U_Warning,
         URL = vs.U_Reject
      From Alarms a
      Join Alarm_Template_Var_Data tv on tv.atd_id = a.atd_id
      Join Alarm_Templates t on t.at_id = tv.at_id
      Join Alarm_Priorities p on p.ap_id = t.ap_id
      Join Prod_Units u on u.PU_Id = @Unit or u.Master_Unit = @Unit  
      Join Variables v on v.pu_id = u.pu_id and v.var_id = a.key_id
      Join Alarm_Template_SPC_Rule_Data r on r.at_Id = t.at_id and r.atsrd_id = a.atsrd_id
      left outer join var_specs vs on vs.prod_id = @Product and vs.var_id = v.var_id and vs.effective_date <= @EndTime and ((vs.expiration_date > @EndTime) or (vs.expiration_date Is NULL))
      Where a.Alarm_Type_Id in (2,4) and
            a.Start_Time <= @EndTime and
            ((a.End_Time > @StartTime) or (a.End_Time Is Null)) 
Select #Report.*, Value = t.Result
  From #Report
  Join Tests t on t.var_id = #Report.Var_id and t.Result_On = @EndTime
Drop Table #Report

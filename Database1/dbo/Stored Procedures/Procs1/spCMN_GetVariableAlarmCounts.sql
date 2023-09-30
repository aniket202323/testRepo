CREATE Procedure dbo.spCMN_GetVariableAlarmCounts
@VariableList varchar(2000),
@StartTime datetime, 
@EndTime datetime,
@HighCount int OUTPUT,
@MediumCount int OUTPUT,
@LowCount int OUTPUT,
@ProductFilter int = null
AS
--*/
/*****************************************************
-- For Testing
--*****************************************************
Declare @VariableList varchar(2000),
@StartTime datetime, 
@EndTime datetime,
@HighCount int,
@MediumCount int,
@LowCount int
Select @VariableList = '2,3,4,5,6,7,8,9,10,182,183,557'
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2003'
--*****************************************************/
Declare @SQL varchar(3000)
Select @HighCount = 0
Select @MediumCount = 0
Select @LowCount = 0
Create Table #AlarmVariables (
  Item int
)
Select @SQL = 'Select Var_Id From Variables Where Var_Id in (' + @VariableList + ')'
Insert Into #AlarmVariables 
  exec(@SQL)
Select distinct @HighCount = @HighCount + coalesce(sum(Case When r.ap_id = 3 then 1 When vr.ap_id = 3 Then 1 Else 0 End),0), 
                @MediumCount = @MediumCount + coalesce(sum(Case When r.ap_id = 2 then 1 When vr.ap_id = 2 Then 1 Else 0 End),0), 
                @LowCount = @LowCount + coalesce(sum(Case When r.ap_id = 1 then 1 When vr.ap_id = 1 Then 1 Else 0 End),0) 
  From Alarms a
  Join #AlarmVariables v on v.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
  Left Outer Join Alarm_Template_Variable_Rule_Data vr on vr.atvrd_id = a.atvrd_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  Where a.Start_Time Between @StartTime and @EndTime and
((@ProductFilter is null) or (p1.prod_id = @ProductFilter))
Select distinct @HighCount = @HighCount + coalesce(sum(Case When r.ap_id = 3 then 1 When vr.ap_id = 3 Then 1 Else 0 End),0), 
                @MediumCount = @MediumCount + coalesce(sum(Case When r.ap_id = 2 then 1 When vr.ap_id = 2 Then 1 Else 0 End),0), 
                @LowCount = @LowCount + coalesce(sum(Case When r.ap_id = 1 then 1 When vr.ap_id = 1 Then 1 Else 0 End),0) 
  From Alarms a
  Join #AlarmVariables v on v.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
  Left Outer Join Alarm_Template_Variable_Rule_Data vr on vr.atvrd_id = a.atvrd_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  Where a.Start_Time < @StartTime and ((a.end_time > @StartTime) or (a.end_time is null)) and
((@ProductFilter is null) or (p1.prod_id = @ProductFilter))
Drop Table #AlarmVariables
/*****************************************************
-- For Testing
--*****************************************************
Select '@HighCount=' + convert(varchar(25), @HighCount)
Select '@MediumCount=' + convert(varchar(25), @MediumCount)
Select '@LowCount=' + convert(varchar(25), @LowCount)
--*****************************************************/

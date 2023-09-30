CREATE Procedure dbo.spBF_GetUnitAlarmCounts
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@HighCount int OUTPUT,
@MediumCount int OUTPUT,
@LowCount int OUTPUT
AS
Declare @VariableList nvarchar(2000)
Declare @VariableId int
DECLARE @DistinctVars TABLE (VarId Int)
DECLARE @Units  TABLE (PUId Int)
DECLARE @MasterUnit 	 Int
INSERT INTO @Units(PUId)
 	 SELECT pu_id 
 	  	 FROM prod_units 
 	  	 WHERE pu_id = @Unit or master_unit = @Unit
INSERT INTO @DistinctVars(VarId)
 Select Distinct  v.var_id 
    From variables v 
    JOIN alarm_template_var_data vd on vd.var_id = v.var_id
 	 JOIN @Units u ON u.PUId = v.pu_Id
Select @HighCount = 0
Select @MediumCount = 0
Select @LowCount = 0
Select distinct @HighCount = @HighCount + coalesce(sum(Case When r.ap_id = 3 then 1 When vr.ap_id = 3 Then 1 Else 0 End),0), 
                @MediumCount = @MediumCount + coalesce(sum(Case When r.ap_id = 2 then 1 When vr.ap_id = 2 Then 1 Else 0 End),0), 
                @LowCount = @LowCount + coalesce(sum(Case When r.ap_id = 1 then 1 When vr.ap_id = 1 Then 1 Else 0 End),0) 
  From Alarms a
  Join @DistinctVars v on v.VarId = a.Key_Id and a.Alarm_Type_Id in (1,2)
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
  Left Outer Join Alarm_Template_Variable_Rule_Data vr on vr.atvrd_id = a.atvrd_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  Where a.Start_Time Between @StartTime and @EndTime 
Select distinct @HighCount = @HighCount + coalesce(sum(Case When r.ap_id = 3 then 1 When vr.ap_id = 3 Then 1 Else 0 End),0), 
                @MediumCount = @MediumCount + coalesce(sum(Case When r.ap_id = 2 then 1 When vr.ap_id = 2 Then 1 Else 0 End),0), 
                @LowCount = @LowCount + coalesce(sum(Case When r.ap_id = 1 then 1 When vr.ap_id = 1 Then 1 Else 0 End),0) 
  From Alarms a
  Join @DistinctVars v on v.VarId = a.Key_Id and a.Alarm_Type_Id in (1,2)
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
  Left Outer Join Alarm_Template_Variable_Rule_Data vr on vr.atvrd_id = a.atvrd_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  Where a.Start_Time < @StartTime and ((a.end_time > @StartTime) or (a.end_time is null)) 

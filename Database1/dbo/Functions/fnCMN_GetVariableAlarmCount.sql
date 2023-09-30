create function dbo.[fnCMN_GetVariableAlarmCount]
(@VariableList nVarChar(2000), @StartTime datetime, @EndTime datetime, @AlarmLevel Int, @ProductFilter int = null)
 	 Returns Int
as
/*
 	 @AlarmLevel: High = 3, Medium = 2, Low = 1
*/
BEGIN
 	 Declare @returnValue Int
 	 Declare @AlarmVariables Table(
 	  	 Item int
 	 )
 	 Select @returnValue = 0
 	 Insert Into @AlarmVariables
 	  	 Select [Id] From dbo.[fnCMN_IdListToTable]('Variables', @VariableList, ',')
 	 Select distinct @returnValue = @returnValue + coalesce(sum(Case When r.ap_id = @AlarmLevel then 1 When vr.ap_id = @AlarmLevel Then 1 Else 0 End),0)
 	 From Alarms a
 	 Join @AlarmVariables v on v.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
 	 left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
 	 left outer Join Alarm_Templates t on t.at_id = vd.at_id
 	 Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
 	 Left Outer Join Alarm_Template_Variable_Rule_Data vr on vr.atvrd_id = a.atvrd_id
 	 join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
 	 join products p1 on p1.prod_id = ps.prod_id
 	 Where a.Start_Time Between @StartTime and @EndTime and
 	  	 ((@ProductFilter is null) or (p1.prod_id = @ProductFilter))
 	 Select distinct @returnValue = @returnValue + coalesce(sum(Case When r.ap_id = @AlarmLevel then 1 When vr.ap_id = @AlarmLevel Then 1 Else 0 End),0)
 	 From Alarms a
 	 Join @AlarmVariables v on v.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
 	 left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
 	 left outer Join Alarm_Templates t on t.at_id = vd.at_id
 	 Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
 	 Left Outer Join Alarm_Template_Variable_Rule_Data vr on vr.atvrd_id = a.atvrd_id
 	 join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
 	 join products p1 on p1.prod_id = ps.prod_id
 	 Where a.Start_Time < @StartTime and ((a.end_time > @StartTime) or (a.end_time is null)) and
 	  	 ((@ProductFilter is null) or (p1.prod_id = @ProductFilter)) 	 
 	 RETURN @returnValue
END

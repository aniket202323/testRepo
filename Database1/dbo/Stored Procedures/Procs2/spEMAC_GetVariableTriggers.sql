Create Procedure dbo.spEMAC_GetVariableTriggers
@ATId int,
@AlarmtypeId int
AS
IF @AlarmtypeId = - 2 
BEGIN
 	 Select r.Alarm_Variable_Rule_Id, Alarm_Variable_Rule_Desc, AP_Id = coalesce(rd.AP_Id,3), AP_Desc = Coalesce(ap.AP_Desc, 'High'),  UsesRule = 1
 	 from Alarm_Variable_Rules r
 	 Left Join Alarm_Template_Variable_Rule_Data rd On  rd.Alarm_Variable_Rule_Id = r.Alarm_Variable_Rule_Id and rd.AT_Id = @ATId
 	 left join Alarm_Priorities ap on ap.AP_Id = rd.AP_Id
 	 Where r.Alarm_Variable_Rule_Id = 5
END
ELSE
BEGIN
 	 Select r.Alarm_Variable_Rule_Id, Alarm_Variable_Rule_Desc, rd.AP_Id, AP_Desc = Coalesce(ap.AP_Desc, ''),
 	   UsesRule = case when rd.Alarm_Variable_Rule_Id > 0 Then 1
 	  	  	  	  	  	   Else 0
 	  	  	  	  	  End
 	 from Alarm_Variable_Rules r
 	 left join Alarm_Template_Variable_Rule_Data rd on rd.Alarm_Variable_Rule_Id = r.Alarm_Variable_Rule_Id and rd.AT_Id = @ATId
 	 left join Alarm_Priorities ap on ap.AP_Id = rd.AP_Id
 	 order by r.Alarm_Variable_Rule_Id asc
END

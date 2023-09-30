Create Procedure dbo.spSOE_GetAlarmType
 @AlarmId int,
 @AlarmType int output
As
 SElect @AlarmType=0
 Select @AlarmType= Case When r.AP_Id is not NULL then r.AP_Id Else vrd.AP_Id End
 From Alarm_Templates AT Inner Join Alarm_Template_Var_Data AD on AT.AT_Id = AD.AT_Id
                         Inner Join Alarms AL on AL.ATD_Id = AD.ATD_Id
                         Left Outer Join Alarm_Template_SPC_Rule_Data r on r.at_id = ad.AT_Id and r.ATSRD_Id = AL.ATSRD_Id
                         Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.at_id = ad.AT_Id and vrd.ATVRD_Id = AL.ATVRD_Id
   Where AL.ALarm_Id = @AlarmId
 Return @AlarmType 

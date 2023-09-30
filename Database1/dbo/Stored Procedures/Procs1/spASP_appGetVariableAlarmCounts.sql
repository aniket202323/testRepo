CREATE Procedure dbo.spASP_appGetVariableAlarmCounts
@VariableList nvarchar(2000),
@StartTime datetime, 
@EndTime datetime,
@HighCount int OUTPUT,
@MediumCount int OUTPUT,
@LowCount int OUTPUT
AS
--*/
/*****************************************************
-- For Testing
--*****************************************************
Declare @VariableList nvarchar(2000),
@StartTime datetime, 
@EndTime datetime,
@HighCount int,
@MediumCount int,
@LowCount int
Select @VariableList = '2,3,4,5,6,7,8,9,10,182,183,557'
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2003'
--*****************************************************/
Declare @SQL nvarchar(3000)
Select @HighCount = 0
Select @MediumCount = 0
Select @LowCount = 0
Create Table #AlarmVariables (
  Item int
)
Select @SQL = 'Select Var_Id From Variables Where Var_Id in (' + @VariableList + ')'
Insert Into #AlarmVariables 
  exec(@SQL)
--Alarms
Select @HighCount = @HighCount + Case When r.ap_id = 3 or r2.ap_id = 3 then 1 Else 0 End, 
       @MediumCount = @MediumCount + Case When r.ap_id = 2 or r2.ap_id = 2 then 1 Else 0 End, 
       @LowCount = @LowCount + Case When r.ap_id = 1 or r2.ap_id = 1 then 1 Else 0 End 
  From Alarms a
  Join #AlarmVariables v on v.Item = a.Key_Id 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id
 	 Left Outer Join Alarm_Template_Variable_Rule_Data r2 on r2.atvrd_Id = a.atvrd_id
  Where (a.Start_Time Between @StartTime and @EndTime)
  Or 	  	 (a.Start_Time < @StartTime and ((a.end_time > @StartTime) or (a.end_time is null)))
 	 And  	 a.Alarm_Type_Id In (1,2,4)
Drop Table #AlarmVariables
/*****************************************************
-- For Testing
--*****************************************************
Select '@HighCount=' + convert(nvarchar(25), @HighCount)
Select '@MediumCount=' + convert(nvarchar(25), @MediumCount)
Select '@LowCount=' + convert(nvarchar(25), @LowCount)
SELECT * from alarm_Template_SPC_Rule_Data
--*****************************************************/

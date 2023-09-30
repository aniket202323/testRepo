CREATE Procedure dbo.spASP_appGetUnitAlarmCounts
@Unit int,
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
Declare @Unit int,
@StartTime datetime, 
@EndTime datetime,
@HighCount int,
@MediumCount int,
@LowCount int
Select @Unit = 2
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2003'
--*****************************************************/
Declare @VariableList nvarchar(2000)
Declare @@VariableId int
Select @VariableList = NULL
Declare Alarm_Cursor Insensitive Cursor 
  For Select distinct v.var_id
    From variables v 
    join alarm_template_var_data vd on vd.var_id = v.var_id
    where pu_id in (Select pu_id from prod_units where pu_id = @Unit or master_unit = @Unit)
  For Read Only
Open Alarm_Cursor
Fetch Next From Alarm_Cursor Into @@VariableId
While @@Fetch_Status = 0
  Begin
    If @VariableList Is Null
      Select @VariableList = convert(nvarchar(25),@@VariableId)
    Else
      Select @VariableList = @VariableList + ',' + convert(nvarchar(25),@@VariableId)
 	  	 Fetch Next From Alarm_Cursor Into @@VariableId
  End
Close Alarm_Cursor
Deallocate Alarm_Cursor  
execute spASP_appGetVariableAlarmCounts
 	 @VariableList,
 	 @StartTime, 
 	 @EndTime,
 	 @HighCount OUTPUT,
 	 @MediumCount OUTPUT,
 	 @LowCount OUTPUT
/*****************************************************
-- For Testing
--*****************************************************
Select '@HighCount=' + convert(nvarchar(25), @HighCount)
Select '@MediumCount=' + convert(nvarchar(25), @MediumCount)
Select '@LowCount=' + convert(nvarchar(25), @LowCount)
--*****************************************************/

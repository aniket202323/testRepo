create function dbo.[fnCMN_GetUnitAlarmCount]
(@Unit int, @StartTime datetime, @EndTime datetime, @AlarmLevel Int)
 	 Returns Int
as
/*
 	 @AlarmLevel: High = 3, Medium = 2, Low = 1
*/
BEGIN
/*
 	 -- For Testing
 	 Declare @Unit Int,
 	  	  	  	  	 @StartTime DateTime,
 	  	  	  	  	 @EndTime DateTime,
 	  	  	  	  	 @AlarmLevel Int
 	 Select @Unit = 350, @StartTime = '8/8/06 12:00:00 AM', @EndTime = '8/9/06 12:00:00 AM', @AlarmLevel = 2
*/
 	 Declare @returnValue Int
 	 Declare @VariableTable Table (
 	  	 Var_Id Int
 	 )
 	 Declare @VariableList nVarChar(2000)
 	 Select @VariableList = ''
 	 
 	 Insert Into @VariableTable
 	  	 Select Distinct v.Var_Id
 	  	 From Variables v 
 	  	 Join Alarm_Template_Var_Data vd On vd.Var_Id = v.Var_Id
 	  	 Where PU_Id In (Select PU_Id From Prod_Units Where PU_Id = @Unit or Master_Unit = @Unit)
 	 Select @VariableList = @VariableList + Convert(nVarChar(25),v.Var_Id) + ','
 	 From @VariableTable v
/*
 	 --This returns multiple instances of the same Ids
  Select @VariableList = @VariableList + Convert(nVarChar(25),v.Var_Id) + ','
  From Variables v 
  Join Alarm_Template_Var_Data vd On vd.Var_Id = v.Var_Id
  Where PU_Id In (Select PU_Id From Prod_Units Where PU_Id = @Unit or Master_Unit = @Unit)
 	 --This only returns 1 row
 	 Select Distinct @VariableList = @VariableList + Convert(nVarChar(25),v.Var_Id) + ','
  From Variables v 
  Join Alarm_Template_Var_Data vd On vd.Var_Id = v.Var_Id
  Where PU_Id In (Select PU_Id From Prod_Units Where PU_Id = @Unit or Master_Unit = @Unit)
*/
/*
 	 -- For Testing
 	 Select @VariableList
*/
 	 Select @returnValue = dbo.[fnCMN_GetVariableAlarmCount](@VariableList, @StartTime, @EndTime, @AlarmLevel, Null)
 	 RETURN @returnValue
END

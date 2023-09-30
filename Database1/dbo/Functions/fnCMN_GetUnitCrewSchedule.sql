CREATE FUNCTION dbo.fnCMN_GetUnitCrewSchedule(@Unit int, @StartTime datetime, @EndTime datetime) 
     RETURNS @ModifiedCrewSchedule TABLE(PU_Id int, Start_Time datetime, End_Time datetime, Crew_Desc nVarChar(15), Shift_Desc nVarChar(15) )
AS 
Begin
--************************************************/
--------------------------------
-- Local Internal Variables
--------------------------------
Declare @RowId int, @MaxRowId int, @PrevST datetime, @PrevET datetime, @ST datetime, @ET datetime, @Crew_Desc nVarChar(10), @Shift_Desc nVarChar(10)
Declare @ExistingCrewSchedule TABLE(RowId int identity(1,1), PU_Id int, Start_Time datetime, End_Time datetime, Crew_Desc nVarChar(15), Shift_Desc nVarChar(15) )
Declare @UNSPECIFIED nVARCHAR(20)
Select @UNSPECIFIED = '<Unspecified>'
--------------------------------
-- Get Current Crew Schedule
--------------------------------
Insert into @ExistingCrewSchedule(PU_ID, Start_Time, End_Time, Crew_Desc, Shift_Desc)
 	 Select @Unit, Start_Time, End_Time, Crew_Desc, Shift_Desc
 	 From Crew_Schedule
 	 Where PU_ID = @Unit
 	 And End_Time > @StartTime
 	 and Start_Time < @EndTime
 	 Order by Start_Time
--------------------------------
-- Initialize Variables
--------------------------------
Select @MaxRowId = max(rowId) from @ExistingCrewSchedule
Select @RowId = 0, @PrevST = @StartTime, @PrevET = @StartTime
While @RowId < @MaxRowId
Begin 	 
 	 Select @RowId = @RowId + 1
 	 Select @ST = Start_Time, @ET = End_Time, @Crew_Desc = Crew_desc, @Shift_Desc = Shift_Desc from @ExistingCrewSchedule where RowId = @RowId
 	 -- Are the times continuous
 	 If @ST <> @PrevET
 	 Begin
 	  	 If @ST > @PrevET -- Then there is a missing gap of time - fill it
 	  	  	 Insert into @ModifiedCrewSchedule(PU_ID, Start_Time, End_Time, Shift_Desc, Crew_Desc) values(@Unit, @PrevET, @ST, @UNSPECIFIED, @UNSPECIFIED)
 	  	 Else -- @ST < @PrevET
 	  	  	 Select @ST = @PrevET
 	 End
 	 
 	 Insert into @ModifiedCrewSchedule(PU_ID, Start_Time, End_Time, Shift_Desc, Crew_Desc) values(@Unit, @ST, @ET, @Shift_Desc, @Crew_Desc)
 	 Select @PrevST = @ST, @PrevET = @ET
End
--------------------------------
-- Cleanup Last Row If Necessary
--------------------------------
If @PrevET < @EndTime
 	 Insert into @ModifiedCrewSchedule(PU_ID, Start_Time, End_Time, Shift_Desc, Crew_Desc) values(@Unit, @PrevET, @EndTime, @UNSPECIFIED, @UNSPECIFIED)
update @ModifiedCrewSchedule set Start_Time = @StartTime where Start_Time < @StartTime
update @ModifiedCrewSchedule set End_Time = @EndTime where End_Time > @EndTime
return
End

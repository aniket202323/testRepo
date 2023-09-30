/*
select * from dbo.fnCMN_GetProductionDayShiftCrewByTimeStamp('2005-01-25 7:00:00', 2)
*/
CREATE FUNCTION dbo.fnCMN_GetProductionDayShiftCrewByTimeStamp(@ProductionTimeStamp DateTime, @Unit int) 
     RETURNS @ProductionCategories Table (Production_Day datetime, Shift_Desc nVarChar(10), Crew_Desc nVarChar(10), Start_Time datetime, End_Time datetime)
AS 
Begin
     Declare @ProductionDay DateTime
     Declare @DayBefore datetime
     Declare @DayAfter datetime
     Declare @CrewSchedule Table(
          Start_Time datetime,
          End_Time datetime,
          Shift_Desc nVarChar(10),
          Crew_Desc nVarChar(10),
          Shift_Duration int
     )
     select @DayBefore = dateadd(day, -1, @ProductionTimeStamp)
     select @DayAfter = dateadd(day, 1, @ProductionTimeStamp)
     Insert Into @CrewSchedule(Start_Time, End_Time, Shift_Desc, Crew_Desc)
     select Start_Time, End_Time, Shift_Desc, Crew_Desc from dbo.fnRS_wrGetCrewSchedule(@DayBefore, @DayAfter, @Unit)
     Insert Into @ProductionCategories(Production_Day)
     Select dbo.fnCMN_GetProductionDayByTimeStamp(@ProductionTimeStamp)
     Update @ProductionCategories Set
          Shift_Desc = cs.Shift_Desc,
          Crew_Desc = cs.Crew_Desc,
          Start_Time = cs.Start_Time,
          End_Time = cs.End_Time
          From @CrewSchedule cs 
          Where cs.Start_Time < @ProductionTimeStamp
               and cs.End_Time >= @ProductionTimeStamp
     RETURN 
END

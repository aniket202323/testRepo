CREATE FUNCTION dbo.fnCMN_GetEfficiencyVariableOEE(@Unit INT, @StartTime DATETIME, @EndTime DATETIME) 
     RETURNS REAL 
AS 
Begin
--******************************/
-- Local Variables
Declare @EfficiencyVariableOEE real, @EfficiencyVariable int
Declare @PrevTS datetime, @PostTS datetime, @PostResult real
Declare @ST datetime, @ET datetime, @ID int, @TempTime datetime
Declare @TestData Table(
 	 id int NOT NULL IDENTITY (1, 1),
 	 Start_Time datetime,
 	 End_Time DAteTime,
 	 Duration INT,
 	 Result real,
 	 WeightedAmount FLOAT
)
---------------------------------------
-- Determine Efficiency Variable
-- If non configured, return NULL
---------------------------------------
Select @EfficiencyVariable = Efficiency_Variable From Prod_Units Where PU_ID = @Unit
If @EfficiencyVariable Is Null
 	 select @EfficiencyVariableOEE=  NULL
---------------------------------------
-- Get Timestamp of closest test value 
-- to @StartTime and @EndTime
---------------------------------------
select @PrevTS = Max(Result_On) From Tests where Var_Id=@EfficiencyVariable
 	 And Result_On <= @StartTime
Select @PostTS = Min(Result_On) from Tests where var_Id=@EfficiencyVariable
 	 And Result_On >= @EndTime
---------------------------------------
-- Get all test data between the 
-- start and end time
---------------------------------------
Insert into @TestData(End_Time, Result)
 	 select Result_On, Result from tests where var_id = @EfficiencyVariable
 	 and Result_On > @StartTime 
    and Result_On <= @EndTime
----------------------------------------
-- Get any test data that was "In Progress"
----------------------------------------
If (Select Count(*) From @TestData Where End_Time = @EndTime) = 0
  Begin
 	 Insert Into @TestData(End_Time, Result)
 	  	 select Result_On, Result from tests where var_id = @EfficiencyVariable
 	  	 and result_on = @PostTS
  End
-- Initialize TempTime
Select @TempTime=@PrevTS
-------------------------------------------------------------
-- Calculate the start_Times for each test value timestamp
-------------------------------------------------------------
Declare MyCursor  CURSOR
  For ( Select ID, Start_Time, End_Time From @TestData )
  For Read Only
  Open MyCursor  
  Fetch Next From MyCursor Into @ID, @ST, @ET 
  While (@@Fetch_Status = 0)
    Begin 	  	 
 	  	 Update @TestData Set Start_Time = @TempTime where id=@Id
 	  	  	 
 	  	 Select @TempTime = @ET
 	  	 Fetch Next From MyCursor Into @Id, @ST, @ET 
    End 
Close MyCursor
Deallocate MyCursor
---------------------------------------------------
-- Pro-rate any test value that was "In-Progress"
-- before @StartTime
---------------------------------------------------
update @TestData Set
 	 --Result = (Result / DateDiff(s, Start_Time, End_Time)) * DateDiff(s, @StartTime, End_Time),
 	 Start_Time = @StartTime
Where @StartTime between Start_Time and End_Time
---------------------------------------------------
-- Pro-rate any test value that was "In-Progress"
-- after @EndTime
---------------------------------------------------
update @TestData Set
 	 --Result = (Result / DateDiff(s, Start_Time, End_Time)) * DateDiff(s, Start_Time, @EndTime),
 	 End_Time = @EndTime
Where @EndTime between Start_Time and End_Time
Update @TestData Set Duration = DateDiff(s, Start_Time, End_Time)
Update @Testdata set WeightedAmount = duration * result
select @EfficiencyVariableOEE = (avg(WeightedAmount) / avg(duration))  from @Testdata
     RETURN @EfficiencyVariableOEE
END

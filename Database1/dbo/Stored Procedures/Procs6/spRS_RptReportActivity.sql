CREATE PROCEDURE [dbo].[spRS_RptReportActivity]
 AS
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Count int
Select @StartTime = '2002-02-05 7:00:00.000'
Select @EndTime = GetDate() --'2002-02-05 7:00:00.000'
--Get the total runs for each engine
CREATE TABLE #Temp_Runs(
    Engine_Id int,
    Run_Count int)
Insert Into #Temp_Runs(Engine_Id)(Select distinct(Engine_id) from report_runs)
Declare @MyId int
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select Engine_id
       From #Temp_Runs
      )
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      update #Temp_Runs
      Set Run_Count = (select count(*) from report_runs where engine_id = @MyId and Start_Time >= @StartTime and   End_Time < @EndTime)
      where Engine_Id = @MyId
      Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd1
myEnd1:
Close MyCursor
Deallocate MyCursor
Select * from #Temp_Runs
Select @Count =+ Sum(Run_Count) from #Temp_Runs
insert into #Temp_Runs(Engine_id, Run_Count)
Values(0, @Count)
CREATE TABLE #Temp_Definitions(
    Report_Id int,
    Report_Name varchar(50),
    Report_Type_Id int,
    Run_Count int)
    Insert Into #Temp_Definitions(Report_Id)
    select distinct(report_id) from report_runs where Start_Time >= @StartTime and End_Time < @EndTime
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select Report_id
       From #Temp_Definitions
      )
  For Read Only
  Open MyCursor  
MyLoop2:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      update #Temp_Definitions
        Set Run_Count = (select count(*) from report_runs 
          where Report_id = @MyId and Start_Time >= @StartTime and   End_Time < @EndTime)
      where Report_Id = @MyId
      update #Temp_Definitions
        Set Report_Type_Id = (Select Report_type_Id from report_definitions where report_id = @MyId),
 	     Report_Name = (Select Report_name from report_definitions where report_id = @MyId)
      where Report_id = @MyId  
      Goto MyLoop2
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd2
myEnd2:
Close MyCursor
Deallocate MyCursor
CREATE TABLE #Temp_Types(
    Report_Type_Id int,
    Description varchar(50),
    Template varchar(50),
    Run_Count int)
    Insert Into #Temp_Types(Report_Type_Id)
    select distinct(report_type_id) from #Temp_Definitions
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select Report_Type_Id
       From #Temp_Types
      )
  For Read Only
  Open MyCursor  
MyLoop3:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      update #Temp_Types
        Set Run_Count = (Select Sum(Run_Count) from #Temp_Definitions where Report_Type_Id = @MyId),
            Description = (Select Description from report_types where report_type_id = @MyId),
 	     Template = (Select Template_Path from report_types where report_type_id = @MyId)
      where Report_Type_Id = @MyId
      Goto MyLoop3
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd3
myEnd3:
Close MyCursor
Deallocate MyCursor
select * from #Temp_Definitions
order by report_type_id
select * from #Temp_Types
Drop Table #Temp_Definitions
Drop Table #Temp_Runs
Drop Table #Temp_Types

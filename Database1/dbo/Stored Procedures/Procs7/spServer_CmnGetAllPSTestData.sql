CREATE PROCEDURE dbo.spServer_CmnGetAllPSTestData
@PU_Id int,
@Start_Time datetime,
@End_Time datetime
AS
declare
  @Var_Id int,
  @Status int,
  @ErrorMsg nVarChar(255)
declare 	 @Vars Table(Var_Id int)
declare @Results Table(Var_Id int, Result nVarChar(30) COLLATE DATABASE_DEFAULT, Result_On Datetime)
Declare @VarData Table(Event_Id int null , Result_On datetime, Result nVarChar(255) null)
if (@Start_Time is null) return
if (@End_Time is null) return
Insert Into @Vars(Var_Id) (Select Var_Id From Variables_Base Where (PU_Id = @PU_Id) And (Unit_Summarize = 1) And (ShouldArchive = 1))
Declare Var_Cursor INSENSITIVE CURSOR 
  For Select Var_Id From @Vars
  For Read Only
Open Var_Cursor  
Var_Loop1:
  Fetch Next From Var_Cursor Into @Var_Id
  If (@@Fetch_Status = 0)
    begin
 	  	  	 -- Get a Start or Previous Value
 	  	  	 Delete From @VarData    
 	  	  	 Insert Into @VarData(Event_Id,Result,Result_On) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@Var_Id,@PU_Id,@Start_Time,NULL,0,0,0,'<=',1,1,0,0,0)
 	  	  	 Select @Status = NULL
 	  	  	 Select @Status = Event_Id, @ErrorMsg = Result From @VarData Where Event_Id = -1
 	  	  	 If (@Status Is NULL)
 	  	  	  	 Insert Into @Results(Var_Id, Result, Result_On) (Select @Var_Id,Result,Result_On From @VarData)
 	  	  	 -- Get a Next Value
 	  	  	 Delete From @VarData    
 	  	  	 Insert Into @VarData(Event_Id,Result,Result_On) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@Var_Id,@PU_Id,@End_Time,NULL,0,0,0,'>',1,1,0,0,0)
 	  	  	 Select @Status = NULL
 	  	  	 Select @Status = Event_Id, @ErrorMsg = Result From @VarData Where Event_Id = -1
 	  	  	 If (@Status Is NULL)
 	  	  	  	 Insert Into @Results(Var_Id, Result, Result_On) (Select @Var_Id,Result,Result_On From @VarData)
 	  	  	  	 
 	  	  	 -- Get the Normal Values
 	  	  	 Delete From @VarData    
 	  	  	 Insert Into @VarData(Event_Id,Result,Result_On) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@Var_Id,@PU_Id,@Start_Time,@End_Time,0,1,0,NULL,NULL,1,0,0,0)
 	  	  	 Select @Status = NULL
 	  	  	 Select @Status = Event_Id, @ErrorMsg = Result From @VarData Where Event_Id = -1
 	  	  	 If (@Status Is NULL)
 	  	  	  	 Insert Into @Results(Var_Id, Result, Result_On) (Select @Var_Id,Result,Result_On From @VarData)
 	  	  	  	 
      Goto Var_Loop1
    End
Close Var_Cursor 
Deallocate Var_Cursor
Select Var_Id,
       Result,
       Year = DatePart(Year,Result_On),
       Month = DatePart(Month,Result_On),
       Day = DatePart(Day,Result_On),
       Hour = DatePart(Hour,Result_On),
       Minute = DatePart(Minute,Result_On),
       Second = DatePart(Second,Result_On)
  from @Results
Order By Var_Id, Result_On

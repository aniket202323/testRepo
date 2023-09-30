CREATE PROCEDURE dbo.spRS_GetShellCommand
 AS
---------------------
-- LOCAL PARAMETERS
---------------------
Declare @ok int
Declare @Shell_Id int
Declare @Next_Run_Time datetime
Declare @Interval int
Declare @Now datetime
Declare @Next datetime
Declare @Command varchar(255)
Declare @Id int
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
----------------------------------
-- TEMP TABLE FOR OUTPUT RESULTS
----------------------------------
Create Table #TempTable (
  Shell_Id int,
  Interval int,
  Next_Run_Time datetime,
  Command varchar(255)
)
------------------------------------------
-- GET ALL COMMANDS THAT NEED TO RUN NOW
------------------------------------------
Declare MyShellCursor INSENSITIVE CURSOR
  For (
 	 Select Shell_Id
 	 From Report_Shell_Commands
 	 Where Next_Run_Time < @Now
      )
  For Read Only
  Open MyShellCursor  
------------------------------------------
-- LOOPING AND UPDATING NEXT RUN TIMES
------------------------------------------
MyLoop1:
  Fetch Next From MyShellCursor Into @Shell_Id 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      ---------------------------------------------------
      -- If this command begins with 'sp:' then 
      --   Execute it 
      --   *** NOTE *** NO RESULT SET SHOULD BE RETURNED
      -- Else
      --   Tell the client to shell it
      ---------------------------------------------------
      Select @Command = Command From Report_Shell_commands Where Shell_Id = @Shell_Id
      Select @Id = CharIndex('sp:',@Command)
      If @Id = 1
        Begin
          ------------------------
          -- EXECUTE THE COMMAND
          ------------------------       
          Select @Command =  SubString(@Command,4,LEN(@Command) - 3)
 	   Exec(@Command)        
        End
      Else
        Begin
          ------------------------
          -- UPDATE THE TEMP TABLE
          ------------------------
          Insert Into #TempTable
          Select Shell_Id, Interval, Next_Run_Time, Command
          From Report_Shell_commands
          Where Shell_Id = @Shell_Id
        End
      ------------------------------------------------
      -- Get Interval and Next Run Time of this record
      ------------------------------------------------
      Select @Interval = Interval, @Next_Run_Time = Next_Run_Time
      From Report_Shell_commands
      Where Shell_Id = @Shell_Id
UpdateNextRun:
      -------------------------------------------------------
      -- Increment Next Run Time until it is greater than now
      -------------------------------------------------------
      Select @Next = DateAdd(mi, @Interval, @Next_Run_Time)
      If @Next < @Now
        Begin
          Select @Next_Run_Time = @Next
          goto UpdateNextRun
        End
      ---------------------------
      -- Update the Next Run Time
      ---------------------------
      Update Report_Shell_Commands
      Set Next_Run_Time = @Next
      Where Shell_Id = @Shell_Id
      Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    Begin
      goto myEnd
    End
myEnd:
Close MyShellCursor
Deallocate MyShellCursor
---------------------
-- RETURN THE RESULTS
---------------------
Select * From #TempTable
Drop Table #TempTable

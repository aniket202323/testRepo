Create Procedure [dbo].[spSupport_ShowRunning]
@NumberOfRuns Int = Null,
@WaitDelaySeconds Int = 0,
@InSpid 	  	 Int = 0
AS
Select @WaitDelaySeconds = coalesce(@WaitDelaySeconds,0)
Select @InSpid = coalesce(@InSpid,0)
Declare @SPId int, @Program_Name VARCHAR(50), @HostName VARCHAR(50), @Found1 int,@SQL VarChar(255)
Declare @RunCounter Integer,@RunsToDo Integer,@WaitDelay varchar(9)
SET NOCOUNT ON
Create Table #RunningSpids (SPID Int, Program_Name VARCHAR(100), HostName VARCHAR(50))
select @RunsToDo = coalesce(@NumberOfRuns,1),@RunCounter = 0
If @WaitDelaySeconds > 59 
    Select  @WaitDelaySeconds = 59
if @WaitDelaySeconds < 10 
  Select @WaitDelay = '000:00:0' + convert(varchar(2),@WaitDelaySeconds)
Else
  Select @WaitDelay = '000:00:' + convert(varchar(2),@WaitDelaySeconds)
While @RunCounter < @RunsToDo
  Begin
   IF @InSpid = 0
     Insert InTo #RunningSpids 
       Select SPID, Program_Name, HostName 
 	 From Master.DBO.SysProcesses
        Where Status = 'runnable'
 	 and spId <> @@SPID
   Else
     Insert InTo #RunningSpids 
       Select SPID, Program_Name, HostName 
 	 From Master.DBO.SysProcesses
        Where Status = 'runnable'
 	 and spId = @InSpid
   Insert  InTo #RunningSpids 
     Select SPID, Program_Name, HostName 
 	 From Master.DBO.SysProcesses
        Where Blocked = 0 and spId in (select Blocked From Master.DBO.SysProcesses)
   If @RunsToDo = 999
   BEGIN
 	 If (Select  count(*) from #RunningSpids)  >  0
 	  	 Select @RunCounter = 999
   END
   If (Select  count(*) from #RunningSpids)  =  0 and @NumberOfRuns is null
 	 Select '*********** No Processes Running*************'
   If   @NumberOfRuns is Not null  and @RunsToDo <> 999 
        Print '********** Run #' + convert(varchar(10), @RunCounter +1) + '  ' + Convert(varchar(25),getdate()) + '**********'
   Declare c Cursor for
    Select  Distinct SPID, Program_Name, HostName  From #RunningSpids 
    For Read only
   Open C
   Loop:
     Fetch next from c into @SPId, @Program_Name, @HostName 
     If @@Fetch_Status = 0
       Begin
        Select  @SPId as [Running spid], @Program_Name AS [App Name], @HostName AS HostName 
        dbcc inputbuffer (@SPId)
        Goto Loop
       End
   Close c
   Deallocate C
   Delete From #RunningSpids
   Select @RunCounter = @RunCounter + 1
   WaitFor Delay @WaitDelay
  End
Drop Table #RunningSpids
If @NumberOfRuns is Not Null return
Print '***********All Processes *****************'
Select AppName =  program_name,
       Status = Status,
       Login = Substring(LogiName,1,12), --Substring(SUser_Name(SUId),1,12),
       Cmd = Cmd,
       Hostname = Substring(Hostname,1,15),
       [Blocked By] = case When Blocked = 0 Then Convert(Varchar(5),Blocked)
 	  	            Else Convert(Varchar(5),Blocked) + ' / ' + (Select coalesce(Master.DBO.SysProcesses.Program_Name,'') From Master.DBO.SysProcesses Where Master.DBO.SysProcesses.SpID = x.Blocked)
                           End,
       DBName = Substring(DB_Name(DBId),1,10),
 	    [SPId] = SPID
  From Master.DBO.SysProcesses x
  Order By Blocked Desc, AppName

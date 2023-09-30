CREATE PROCEDURE dbo.spEM_ShowProcessStats
 AS
Declare
  @@InstanceName nvarchar(255),
  @@ServiceId int,
  @ModifiedOn datetime,
  @UserCPU decimal(20,2),
  @SystemCPU decimal(20,2),
  @TotalProcCPU decimal(20,2),
  @ElapsedTime decimal(12,2),
  @VirtualMem decimal(20,2),
  @ResidentMem decimal(20,2),
  @ServiceDesc nvarchar(30),
  @TotalCPU decimal(20,2),
  @KeyId int,
  @StartTime datetime
select @TotalCPU = 0
DECLARE   @ProcStats Table(ServiceDesc nvarchar(255), InstanceName nvarchar(255), UserCPU decimal(20,2), SystemCPU decimal(20,2), TotalProcCPU decimal(20,2), ElapsedTime decimal(20,2),VirtualMem decimal(20,2) NULL,ResidentMem decimal(20,2)NULL, ModifiedOn Datetime NULL )
Declare ProcStat_Cursor INSENSITIVE CURSOR
  For Select Distinct Instance_Name,Service_Id from Performance_Statistics_Keys Where (Object_Id = 8) Order By Service_Id
  For Read Only
  Open ProcStat_Cursor  
Fetch_Loop:
  Fetch Next From ProcStat_Cursor Into @@InstanceName,@@ServiceId
  If (@@Fetch_Status = 0)
    Begin
      Select @StartTime = NULL
      Select @StartTime = max (Start_Time) from Performance_Statistics_Keys Where (Object_Id = 8) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId)
      If (@StartTime Is NULL)
        Goto Fetch_Loop
      Select @KeyId = NULL
      Select @KeyId=Key_Id from Performance_Statistics_Keys Where (Object_Id = 8) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId) and (@StartTime = Start_Time)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
      Select @ModifiedOn = NULL
      Select @ModifiedOn = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      If (@ModifiedOn Is NULL)
        Goto Fetch_Loop
      Select @ServiceDesc = Service_Desc From CXS_Service Where (Service_Id = @@ServiceId)
      Select @UserCPU = NULL
      Select @SystemCPU = NULL
      Select @TotalProcCPU = NULL
      Select @ElapsedTime = NULL
      Select @VirtualMem = NULL
      Select @ResidentMem = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @UserCPU     = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 1) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @SystemCPU   = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ElapsedTime = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @VirtualMem  = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 4) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ResidentMem = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      if @ElapsedTime = 0 or @ElapsedTime is NULL
 	  Select @TotalProcCPU = 0
      else
 	  Select @TotalProcCPU = (@UserCPU + @SystemCPU) * 100 / @ElapsedTime
      select @TotalCPU  = @TotalCPU  + @TotalProcCPU
      Insert Into @ProcStats (ServiceDesc, InstanceName, UserCPU, SystemCPU, TotalProcCPU, ElapsedTime, VirtualMem, ResidentMem, ModifiedOn) 
                    values (@ServiceDesc,@@InstanceName, @UserCPU, @SystemCPU, @TotalProcCPU, @ElapsedTime, @VirtualMem, @ResidentMem, @ModifiedOn)
      Goto Fetch_Loop
    End
Close ProcStat_Cursor 
Deallocate ProcStat_Cursor
select  'Percent Total CPU'=@TotalCPU
DECLARE  @TT Table(TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values ('Last Update')
select * from @TT
Select  	 Service = Substring(ServiceDesc,1,20), 
 	 '% CPU'=TotalProcCPU,
 	 'User CPU'=UserCPU, 'System CPU'=SystemCPU, 
 	 VirtualMem, ResidentMem, 
 	 ElapsedTime, 'Last Update'=ModifiedOn
  From @ProcStats
  order by TotalProcCPU desc, UserCPU desc

CREATE PROCEDURE dbo.spServer_CmnShowProcessStats
@TopNRows int = 0
AS
Declare
  @@InstanceName nVarChar(255),
  @@ServiceId int,
  @TrueModifiedOn datetime,
  @ModifiedOn datetime,
  @UserCPU decimal(8,2),
  @SystemCPU decimal(8,2),
  @TotalProcCPU decimal(8,2),
  @ElapsedTime decimal(8,2),
  @VirtualMem decimal(8,2),
  @ResidentMem decimal(8,2),
  @ServiceDesc nVarChar(30),
  @TotalCPU decimal(8,2),
  @KeyId int,
  @StartTime datetime
Set Nocount on
select @TotalCPU = 0
Declare @ProcStats Table(ServiceDesc nVarChar(255) COLLATE DATABASE_DEFAULT, InstanceName nVarChar(255) COLLATE DATABASE_DEFAULT, UserCPU decimal(8,2), SystemCPU decimal(8,2), TotalProcCPU decimal(8,2), ElapsedTime decimal(8,2),VirtualMem decimal(8,2) NULL,ResidentMem decimal(8,2)NULL, ModifiedOn Datetime NULL )
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
      Select @TrueModifiedOn=Modified_On, @KeyId=Key_Id from Performance_Statistics_Keys Where (Object_Id = 8) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId) and (@StartTime = Start_Time)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
 	  	  	 select @servicedesc = null
      Select @ServiceDesc = Service_Desc From CXS_Service Where (Service_Id = @@ServiceId)
      if (@ServiceDesc is null)
 	       Select @ServiceDesc = @@InstanceName
      Select @UserCPU = NULL
      Select @SystemCPU = NULL
      Select @TotalProcCPU = NULL
      Select @ElapsedTime = NULL
      Select @VirtualMem = NULL
      Select @ResidentMem = NULL
      Select @KeyId = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @UserCPU     = Convert(decimal(8,2),Value) / 1000.0      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 1) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @SystemCPU   = Convert(decimal(8,2),Value) / 1000.0     From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @ElapsedTime = Convert(decimal(8,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @VirtualMem  = Convert(decimal(8,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 4) And (Object_Id = 8) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @ResidentMem = Convert(decimal(8,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      if @ElapsedTime = 0 or @ElapsedTime is NULL
 	       Select @TotalProcCPU = 0
      else
        Select @TotalProcCPU = (@UserCPU + @SystemCPU) * 100 / @ElapsedTime
      select @TotalCPU  = @TotalCPU  + @TotalProcCPU
      Insert Into @ProcStats (ServiceDesc, InstanceName, UserCPU, SystemCPU, TotalProcCPU, ElapsedTime, VirtualMem, ResidentMem, ModifiedOn) 
                    values (@ServiceDesc,@@InstanceName, @UserCPU, @SystemCPU, @TotalProcCPU, @ElapsedTime, @VirtualMem, @ResidentMem, @TrueModifiedOn)
      Goto Fetch_Loop
    End
Close ProcStat_Cursor 
Deallocate ProcStat_Cursor
Set Rowcount @TopNRows
select  'Total CPU Percentage'=@TotalCPU, 'CurrentTime'=Current_Timestamp 
Select  	 ServiceDesc = Substring(ServiceDesc,1,20), 
 	 'CPU %'=TotalProcCPU,
 	 'UserCPU'=UserCPU, 'SystemCPU'=SystemCPU, 
 	 VirtualMem, ResidentMem, 
 	 ElapsedTime, 'LastUpdate'=ModifiedOn
  From @ProcStats
  order by TotalProcCPU desc, UserCPU desc
Set Rowcount 0

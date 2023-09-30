CREATE PROCEDURE dbo.spServer_CmnShowMsgProcStats
@TopNRows int = 0
AS
Declare
  @@InstanceName nVarChar(255),
  @@ServiceId int,
  @ModifiedOn datetime,
  @InCount decimal(13,2),
  @MaxInCount decimal(13,2),
  @ServiceDesc nVarChar(30),
  @StartTime datetime,
  @KeyId int
Set Nocount on
Declare @Stats Table(ServiceDesc nVarChar(255) COLLATE DATABASE_DEFAULT, InstanceName nVarChar(255) COLLATE DATABASE_DEFAULT,InCount decimal(13,2), MaxInCount decimal(13,2))
Declare Stat_Cursor INSENSITIVE CURSOR
  For Select Distinct Instance_Name,Service_Id from Performance_Statistics_Keys Where (Object_Id = 1) and Instance_Name <> 'Total' and Instance_Name not Like '%Reload' Order By Service_Id
  For Read Only
  Open Stat_Cursor  
Fetch_Loop:
  Fetch Next From Stat_Cursor Into @@InstanceName,@@ServiceId
  If (@@Fetch_Status = 0)
    Begin
      Select @StartTime = NULL
      Select @StartTime = max (Start_Time) from Performance_Statistics_Keys Where (Object_Id = 1) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId)
      If (@StartTime Is NULL)
        Goto Fetch_Loop
      Select @KeyId = NULL
      Select @KeyId=Key_Id from Performance_Statistics_Keys Where (Object_Id = 1) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId) and (@StartTime = Start_Time)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
      Select @ServiceDesc = Service_Desc From CXS_Service Where (Service_Id = @@ServiceId)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @InCount     = Convert(decimal(13,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @MaxInCount  = Convert(decimal(13,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
--      If (@Ave < @Min) Or (@Ave > @Max)
  --      Print 'Warning: Data appears to be inaccurate.'
      Insert Into @Stats (ServiceDesc,InstanceName,InCount,MaxInCount) Values(@ServiceDesc,@@InstanceName,@InCount,@MaxInCount)
      Goto Fetch_Loop
    End
Close Stat_Cursor 
Deallocate Stat_Cursor
Set Rowcount @TopNRows
Select  	 ServiceDesc = Substring(ServiceDesc,1,20), 
 	 InstanceName = Substring(InstanceName,1,20),
 	 InCount, MaxInCount
  From @Stats
  Order By servicedesc, InstanceName
Set Rowcount 0

CREATE PROCEDURE dbo.spEM_ShowMsgProcStats
 AS
Declare
  @@InstanceName nvarchar(255),
  @@ServiceId int,
  @ModifiedOn datetime,
  @Ave decimal(20,2),
  @Min decimal(20,2),
  @Max decimal(20,2),
  @Num decimal(20,2),
  @Last decimal(20,2),
  @InCount decimal(20,2),
  @OutCount decimal(20,2),
  @MaxInCount decimal(20,2),
  @MaxOutCount decimal(20,2),
  @ServiceDesc nvarchar(30),
  @Total decimal(20,2),
  @StartTime Datetime,
  @KeyId 	  	 Int
DECLARE  @Stats Table(ServiceDesc nvarchar(255), InstanceName nvarchar(255), Ave decimal(20,2), Minimum decimal(20,2), Maximum decimal(20,2), Last decimal(20,2), Num decimal(20,2), Total decimal(20,2), InCount decimal(20,2), OutCount decimal(20,2), MaxInCount decimal(20,2), MaxOutCount decimal(20,2))
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
      Select @ModifiedOn = NULL
      Select @ModifiedOn = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      If (@ModifiedOn Is NULL)
        Goto Fetch_Loop
      Select @ServiceDesc = Service_Desc From CXS_Service Where (Service_Id = @@ServiceId)
      Select @Ave = NULL
      Select @Min = NULL
      Select @Max = NULL
      Select @Num = NULL
      Select @Last = NULL
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 13) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Ave         = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 14) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Last        = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 15) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Min         = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 16) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Max         = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 17) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Num         = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @InCount     = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @OutCount    = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 4) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @MaxInCount  = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId       = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 5) And (Object_Id = 1) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @MaxOutCount = Convert(decimal(20,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @Total = (@Ave * @Num) / 1000.0
      Insert Into @Stats (ServiceDesc,InstanceName,Ave,Minimum,Maximum,Last,Num,Total,InCount,OutCount,MaxInCount,MaxOutCount) Values(@ServiceDesc,@@InstanceName,@Ave,@Min,@Max,@Last,@Num,@Total,@InCount,@OutCount,@MaxInCount,@MaxOutCount)
      Goto Fetch_Loop
    End
Close Stat_Cursor 
Deallocate Stat_Cursor
Select  	 [To Service] = Substring(ServiceDesc,1,20), 
 	 [From Service] = Substring(InstanceName,1,20),[Processed] = Num, [In] = InCount, [Out] = OutCount, [Max In] = MaxInCount,[Max Out] = MaxOutCount,
 	 [Avg] = Convert(decimal(20,2),(Ave / 1000.0)),
 	 [Total (sec)] = Total,
 	 Minimum = Convert(decimal(20,2),(Minimum / 1000.0)),
 	 Maximum = Convert(decimal(20,2),(Maximum / 1000.0)),
 	 Last = Convert(decimal(20,2),(Last / 1000.0))
 	 
  From @Stats
  Order By servicedesc, Num Desc, InstanceName

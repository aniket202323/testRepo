CREATE PROCEDURE dbo.spServer_CmnShowHistorianStats
@TopNRows int = 0
AS
Declare
  @@InstanceName nVarChar(255),
  @@ServiceId int,
  @ModifiedOn datetime,
  @PrevModifiedOn datetime,
  @Ave decimal(20,5),
  @Min decimal(20,5),
  @Max decimal(20,5),
  @Last decimal(20,5),
  @Num decimal(20,5),
  @PrevNum decimal(20,5),
  @ServiceDesc nVarChar(30),
  @TotalPct decimal(20,5),
  @StartTime datetime,
  @TimeDiff decimal(20,5),
  @KeyId int
Set Nocount on
Declare @Stats Table(TotalPct decimal(20,5), ServiceDesc nVarChar(255) COLLATE DATABASE_DEFAULT, SPName nVarChar(255) COLLATE DATABASE_DEFAULT, Ave decimal(20,5), Minimum decimal(20,5), Maximum decimal(20,5), Last decimal(20,5), Num decimal(20,5), PrevNum decimal(20,5))
Declare Stat_Cursor INSENSITIVE CURSOR
  For Select Distinct Instance_Name,Service_Id from Performance_Statistics_Keys Where (Object_Id = 9) Order By Service_Id
  For Read Only
  Open Stat_Cursor  
Fetch_Loop:
  Fetch Next From Stat_Cursor Into @@InstanceName,@@ServiceId
  If (@@Fetch_Status = 0)
    Begin
      Select @StartTime = NULL
      Select @StartTime = max (Start_Time) from Performance_Statistics_Keys Where (Object_Id = 9) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId)
      If (@StartTime Is NULL)
        Goto Fetch_Loop
      Select @KeyId = NULL
      Select @KeyId=Key_Id from Performance_Statistics_Keys Where (Object_Id = 9) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId) and (@StartTime = Start_Time)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
      Select @ServiceDesc = Service_Desc From CXS_Service Where (Service_Id = @@ServiceId)
      Select @Ave = NULL
      Select @Min = NULL
      Select @Max = NULL
      Select @Last = NULL
      Select @Num = NULL
      Select @PrevNum = NULL
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 9) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Ave     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 1) And (Object_Id = 9) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Last    = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 9) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Min     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 9) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Max     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 4) And (Object_Id = 9) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Num     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @PrevModifiedOn = NULL
      Select @PrevModifiedOn = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On < @ModifiedOn)
            Select @PrevNum = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @PrevModifiedOn)
      If (@PrevNum Is NULL)
        Select @PrevNum = 0
      Select @TimeDiff = Convert(decimal(20,5),DateDiff(Second,@StartTime,@ModifiedOn))
      If (@TimeDiff <= 0.00000)
        Select @TotalPct = 0.0000
      Else
        Select @TotalPct = (@Ave * @Num / 1000.00000) / @TimeDiff
      If (@Ave < @Min) Or (@Ave > @Max)
        Select InError = Substring(@ServiceDesc,1,20),SPName = SubString(@@InstanceName,1,30)
      Insert Into @Stats (TotalPct,ServiceDesc,SPName,Ave,Minimum,Maximum,Last,Num,PrevNum) Values(@TotalPct,@ServiceDesc,@@InstanceName,@Ave,@Min,@Max,@Last,@Num,@PrevNum)
      Goto Fetch_Loop
    End
Close Stat_Cursor 
Deallocate Stat_Cursor
Select OverallTotalPct = Convert(decimal(6,2),Sum(TotalPct) * 100.00)
  From @Stats
Select ServiceDesc = Substring(ServiceDesc,1,17),TotalPct = Convert(decimal(6,2),Sum(TotalPct) * 100.00)
  From @Stats
  Group By ServiceDesc
  Order By TotalPct Desc
Set Rowcount @TopNRows
Select  	 ServiceDesc = Substring(ServiceDesc,1,17), 
 	 SPName = Substring(SPName,1,28),
 	 TotalPct = Convert(decimal(6,2),TotalPct * 100.00),
 	 Ave = Convert(decimal(6,2),Ave / 1000.0),
 	 Num = Convert(int,Num),
 	 RecentNum = Convert(int,Num - PrevNum),
 	 Minimum = Convert(decimal(6,2),Minimum / 1000.0),
 	 Maximum = Convert(decimal(6,2),Maximum / 1000.0),
 	 Last = Convert(decimal(6,2),Last / 1000.0)
  From @Stats
  Order By TotalPct Desc, SPName
Select  	 ServiceDesc = Substring(ServiceDesc,1,17), 
 	 SPName = Substring(SPName,1,28),
 	 TotalPct = Convert(decimal(6,2),TotalPct * 100.0),
 	 Ave = Convert(decimal(6,2),Ave / 1000.0),
 	 Num = Convert(int,Num),
 	 RecentNum = Convert(int,Num - PrevNum),
 	 Minimum = Convert(decimal(6,2),Minimum / 1000.0),
 	 Maximum = Convert(decimal(6,2),Maximum / 1000.0),
 	 Last = Convert(decimal(6,2),Last / 1000.0)
  From @Stats
  Order By RecentNum Desc, SPName
Set Rowcount 0

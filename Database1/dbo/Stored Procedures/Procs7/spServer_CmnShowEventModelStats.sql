CREATE PROCEDURE dbo.spServer_CmnShowEventModelStats
AS
Declare
  @@InstanceName nVarChar(255),
  @ModifiedOn datetime,
  @Ave decimal(20,5),
  @Min decimal(20,5),
  @Max decimal(20,5),
  @Last decimal(20,5),
  @Num decimal(20,5),
  @TotalPct decimal(20,5),
  @TimeDiff decimal(20,5),
  @StartTime datetime,
  @KeyId int
Set Nocount on
Declare @Stats Table(TotalPct decimal(20,5), ModelDesc nVarChar(255) COLLATE DATABASE_DEFAULT, Ave decimal(20,5), Minimum decimal(20,5), Maximum decimal(20,5), Last decimal(20,5), Num decimal(20,5))
Declare Stat_Cursor INSENSITIVE CURSOR
  For Select Distinct Instance_Name from Performance_Statistics_Keys Where (Object_Id = 7) And (Service_Id = 4) And (Instance_Name <> 'Total')
  For Read Only
  Open Stat_Cursor  
Fetch_Loop:
  Fetch Next From Stat_Cursor Into @@InstanceName
  If (@@Fetch_Status = 0)
    Begin
      Select @StartTime = NULL
      Select @StartTime = max (Start_Time) from Performance_Statistics_Keys Where (Object_Id = 7) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = 4)
      If (@StartTime Is NULL)
        Goto Fetch_Loop
      Select @KeyId = NULL
      Select @KeyId=Key_Id from Performance_Statistics_Keys Where (Object_Id = 7) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = 4) and (@StartTime = Start_Time)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
      Select @Ave = NULL
      Select @Min = NULL
      Select @Max = NULL
      Select @Last = NULL
      Select @Num = NULL
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Ave     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 1) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Last    = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Min     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Max     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 4) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ModifiedOn  	 = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      Select @Num     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @TimeDiff = Convert(decimal(20,5),DateDiff(Second,@StartTime,@ModifiedOn))
      If (@TimeDiff <= 0.00000)
        Select @TotalPct = 0.0000
      Else
        Select @TotalPct = (@Ave * @Num / 1000.00000) / @TimeDiff
      If (@Ave < @Min) Or (@Ave > @Max)
        Select InError = SubString(@@InstanceName,1,30)
      Insert Into @Stats (TotalPct,ModelDesc,Ave,Minimum,Maximum,Last,Num) Values(@TotalPct,@@InstanceName,@Ave,@Min,@Max,@Last,@Num)
      Goto Fetch_Loop
    End
Close Stat_Cursor 
Deallocate Stat_Cursor
Select OverallTotalPct = Convert(decimal(20,2),Sum(TotalPct) * 100.0)
  From @Stats
Select  	 ModelDesc = Substring(ModelDesc,1,30),
 	 TotalPct = Convert(decimal(10,2),TotalPct * 100.0),
 	 Ave = Convert(decimal(10,2),Ave / 1000.0),
 	 Num = Convert(int,Num),
 	 Minimum = Convert(decimal(10,2),Minimum / 1000.0),
 	 Maximum = Convert(decimal(10,2),Maximum / 1000.0),
 	 Last = Convert(decimal(10,2),Last / 1000.0)
  From @Stats
  Order By TotalPct Desc, ModelDesc

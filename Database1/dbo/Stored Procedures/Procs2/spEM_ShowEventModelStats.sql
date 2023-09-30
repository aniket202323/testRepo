CREATE PROCEDURE dbo.spEM_ShowEventModelStats
 AS
Declare
  @@InstanceName nvarchar(255),
  @ModifiedOn datetime,
  @Ave decimal(20,5),
  @Min decimal(20,5),
  @Max decimal(20,5),
  @Last decimal(20,5),
  @Num decimal(20,5),
  @TotalPct decimal(20,5),
  @TimeDiff decimal(20,5),
  @StartTime datetime,
  @PU_Desc 	 nvarchar(50),
  @Event_Desc 	 nvarchar(50),
  @KeyId 	  	 Int
Declare @Start Int,@Length Int,@ECID nvarchar(255)
DECLARE  @Stats Table(TotalPct decimal(20,5), ModelDesc nvarchar(255), Ave decimal(20,5), Minimum decimal(20,5), Maximum decimal(20,5), Last decimal(20,5), Num decimal(20,5),PU_Desc nvarchar(50),Event_Desc nvarchar(50))
Declare Stat_Cursor INSENSITIVE CURSOR
  For Select Distinct Instance_Name from Performance_Statistics_Keys Where (Object_Id = 7) And (Service_Id = 4) And (Instance_Name <> 'Total')
  For Read Only
  Open Stat_Cursor  
Fetch_Loop:
  Fetch Next From Stat_Cursor Into @@InstanceName
  If (@@Fetch_Status = 0)
    Begin
 	   Select @Start  = charindex('ECId ',@@InstanceName,1)
 	   If @Start > 0 
 	  	 Begin
 	    	   Select @Start = @Start + 5
 	    	   Select @Length =  charindex(')',@@InstanceName,@Start)
 	    	   Select @Length =  @Length - @Start
 	    	   Select @ECID = Substring(@@InstanceName,@Start,@Length)
 	  	 End
 	   If isnumeric(@ECID) <> 0
 	  	 Begin
 	  	   Select @PU_Desc = Case When PU_Desc = '<PU Deleted>' Then 'none' Else PU_Desc End,@Event_Desc = ET_Desc
 	  	  	 From Event_Configuration ec
 	  	  	 Join Prod_Units pu on pu.PU_Id = ec.PU_Id
 	  	  	 Join Event_Types et on et.ET_Id = ec.ET_Id
 	  	  	 Where Ec_Id = Convert(Int,@ECID)
 	  	 End
      Select @StartTime = NULL
      Select @StartTime = max (Start_Time) from Performance_Statistics_Keys Where (Object_Id = 7) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = 4)
      If (@StartTime Is NULL)
        Goto Fetch_Loop
      Select @KeyId = NULL
      Select @KeyId=Key_Id from Performance_Statistics_Keys Where (Object_Id = 7) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = 4) and (@StartTime = Start_Time)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
      Select @ModifiedOn = NULL
      Select @ModifiedOn = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      If (@ModifiedOn Is NULL)
        Goto Fetch_Loop
      Select @Ave = NULL
      Select @Min = NULL
      Select @Max = NULL
      Select @Last = NULL
      Select @Num = NULL
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Ave     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 1) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Last    = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 2) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Min     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 3) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Max     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId   = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 4) And (Object_Id = 7) And (Service_Id = 4) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Num     = Convert(decimal(20,5),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
 	  	 
      Select @TimeDiff = Convert(decimal(20,5),DateDiff(Second,@StartTime,@ModifiedOn))
      If (@TimeDiff <= 0.00000)
        Select @TotalPct = 0.0000
      Else
        Select @TotalPct = (@Ave * @Num / 1000.00000) / @TimeDiff
      If (@Ave < @Min) Or (@Ave > @Max)
        Select InError = SubString(@@InstanceName,1,30)
      Insert Into @Stats (TotalPct,ModelDesc,Ave,Minimum,Maximum,Last,Num,PU_Desc,Event_Desc) 
 	  	  	 Values(@TotalPct,@@InstanceName,@Ave,@Min,@Max,@Last,@Num,@PU_Desc,@Event_Desc)
      Goto Fetch_Loop
    End
Close Stat_Cursor 
Deallocate Stat_Cursor
Select [Percent Clock Time] = Convert(decimal(20,2),Sum(TotalPct) * 100.0)
  From @Stats
Select  	 [Event Type] = Event_Desc,
 	 [Production Unit] = PU_Desc,
 	 [Percent] = Convert(decimal(10,2),TotalPct * 100.0),
 	 [Avg] = Convert(decimal(10,2),Ave / 1000.0),
 	 [Runs] = Convert(int,Num),
 	 Minimum = Convert(decimal(10,2),Minimum / 1000.0),
 	 Maximum = Convert(decimal(10,2),Maximum / 1000.0),
 	 Last = Convert(decimal(10,2),Last / 1000.0),
 	 Model = Substring(ModelDesc,1,30)
  From @Stats
  Order By TotalPct Desc, ModelDesc

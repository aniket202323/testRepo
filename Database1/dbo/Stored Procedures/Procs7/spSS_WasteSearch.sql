Create Procedure dbo.spSS_WasteSearch
 @ProductionUnits nVarChar(1024) = NULL,
 @EventIds nVarChar(1024)=NULL,
 @StartDate DateTime = NULL,
 @EndDate DateTime = NULL,
 @WasteTypeId Int = NULL, 
 @EventSubTypeId Int = NULL,
 @ResearchStatusOpen Int = NULL, 
 @Products nVarChar(1024) = NULL, 
 @CauseComment nVarChar(50) = NULL, 
 @ActionComment nVarChar(50) = NULL,
 @Statistics nVarChar(1024) = NULL,
 @CrewDescParam nVarChar(10) = NULL,
 @ShiftDescParam nVarChar(10) = NULL,
 @Cause1 int = NULL,
 @Cause2 int = NULL,
 @Cause3 int = NULL,
 @Cause4 int = NULL,
 @Action1 int = NULL,
 @Action2 int = NULL,
 @Action3 int = NULL,
 @Action4 int = NULL,
 @DecimalSep char(1) = '.',
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Select @DecimalSep = COALESCE(@DecimalSep,'.')
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @WedId int, 
         @EventId int,
         @TimeStamp DateTime, 
         @PUId int,
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int,
         @CrewDesc nVarChar(10),
         @ShiftDesc nVarChar(10)
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select W.Wed_Id, W.PU_Id, W.TimeStamp, W.Event_Id, W.Wet_Id, W.Amount, ' +
                       'W.Reason_Level1, W.Reason_Level2, W.Reason_Level3, W.Reason_Level4, ' +
                       'W.Action_Level1, W.Action_Level2, W.Action_Level3, W.Action_Level4, ' +
                       'W.Research_Status_Id, W.Research_Open_Date, W.Research_Close_Date, ' +
                       'W.Research_User_Id, Null As Prod_Id, Null As Crew_Desc, Null as Shift_Desc, ' +
                       'PU.PU_Desc, PU.Group_Id, W.Cause_Comment_Id ' +
                       'From Waste_Event_Details W ' +
                       'Inner Join Prod_Units PU On W.PU_Id = PU.PU_Id ' + 
                       'Left Outer Join Events EV On W.Event_Id = EV.Event_Id ' +
 	  	        'Left Outer Join Event_SubTypes ES On EV.Event_SubType_Id = ES.Event_SubType_Id ' +
                       'Left Outer Join Research_Status RS On W.Research_Status_Id = RS.Research_Status_Id ' +
 	  	        'Left Outer Join Comments CO On W.Cause_Comment_Id = CO.Comment_Id ' +
                       'Left Outer Join Comments CO2 On W.Action_Comment_Id = CO2.Comment_Id '   
-------------------------------------------------------------------
-- Between Dates
--------------------------------------------------------------------
 If (@StartDate Is Not Null And @StartDate>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " W.TimeStamp Between '" + Convert(nVarChar(30), @StartDate) + "' And '" +
                      Convert(nVarChar(30), @EndDate) + "'"   
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End
   End
------------------------------------------------------
--  Research status Open
------------------------------------------------------
 Select @SQLCond0 = NULL
 Select @SQLCond0 = 
 Case @ResearchStatusOpen
  When 1 Then 'W.Research_Open_Date Is Not Null And W.Research_CLose_Date Is Null'
  When 2 Then 'W.Research_Open_Date Is Not Null And W.Research_CLose_Date Is Not Null'
 End
 If (@SQLCond0 Is Not Null)
  Begin
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Cause Comment Description
-----------------------------------------------------------------------
 If (@CauseComment Is Not Null And Len(@CauseComment)>0)
  Begin
   Select @SQLCond0 = "CO.Comment Like '%" + @CauseComment + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Action Comment Description
-----------------------------------------------------------------------
 If (@ActionComment Is Not Null And Len(@ActionComment)>0)
  Begin
   Select @SQLCond0 = "CO2.Comment Like '%" + @ActionComment + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Statistics 
------------------------------------------------------------------
 If (@Statistics Is Not Null And Len(@Statistics)>0)
  Begin
   Select @SQLCond0 = Null
   Select @EndPosition=CharIndex("\",@Statistics)
   While (@EndPosition<>0)
    Begin 
     Select @SQLCond0 =  Substring(@Statistics,1,(@EndPosition-1))
     If (@FlgAnd=1)
      Begin
       Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
      End
     Else
      Begin
       Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
       Select @FlgAnd = 1  
      End  	  
     Select @Statistics =  Right(@Statistics, Len(@Statistics)- @EndPosition)
     Select @EndPosition=CharIndex("\",@Statistics)
    End -- while loop
  End
---------------------------------------------
-- Causes
----------------------------------------------
 If (@Cause4 Is Not Null And @Cause4<>0)
  Begin
   Select @SQLCond0 = 'W.Reason_Level4=' + Convert(nVarChar(05),@Cause4 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
 If (@Cause3 Is Not Null And @Cause3<>0)
  Begin
   Select @SQLCond0 = 'W.Reason_Level3=' + Convert(nVarChar(05),@Cause3 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
 If (@Cause2 Is Not Null And @Cause2<>0)
  Begin
   Select @SQLCond0 = 'W.Reason_Level2=' + Convert(nVarChar(05),@Cause2 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
 If (@Cause1 Is Not Null And @Cause1<>0)
  Begin
   Select @SQLCond0 = 'W.Reason_Level1=' + Convert(nVarChar(05),@Cause1 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
---------------------------------------------
-- Actions
----------------------------------------------
 If (@Action4 Is Not Null And @Action4<>0)
  Begin
   Select @SQLCond0 = 'W.Action_Level4=' + Convert(nVarChar(05),@Action4 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
 If (@Action3 Is Not Null And @Action3<>0)
  Begin
   Select @SQLCond0 = 'W.Action_Level3=' + Convert(nVarChar(05),@Action3 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
 If (@Action2 Is Not Null And @Action2<>0)
  Begin
   Select @SQLCond0 = 'W.Action_Level2=' + Convert(nVarChar(05),@Action2 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
 If (@Action1 Is Not Null And @Action1<>0)
  Begin
   Select @SQLCond0 = 'W.Action_Level1=' + Convert(nVarChar(05),@Action1 )
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Waste Tipe
------------------------------------------------------------------
 If (@WasteTypeId Is Not Null And @WasteTypeId<>0)
  Begin
   Select @SQLCond0 = 'W.WET_Id = ' + Convert(nVarChar(05),@WasteTypeId)
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
-----------------------------------------------------------------
-- Event SubType
-----------------------------------------------------------------
If (@EventSubTypeId Is Not Null And @EventSubTypeId<>0)
  Begin
   Select @SQLCond0 = 'ES.Event_SubType_Id = ' + Convert(nVarChar(05),@EventSubTypeId)
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
----------------------------------------------------------------
--  Output partial result to a temp table
-----------------------------------------------------------------
 Create Table #WasteTemp (
  Wed_Id Int NULL,
  PU_Id Int NULL,
  TimeStamp DateTime NULL,
  Event_Id Int NULL,
  Wet_Id Int NULL,
  Amount Real NULL,
  Reason_Level1 Int NULL,
  Reason_Level2 Int NULL,
  Reason_Level3 Int NULL,
  Reason_Level4 Int NULL,
  Action_Level1 Int NULL,
  Action_Level2 Int NULL,
  Action_Level3 Int NULL,
  Action_Level4 Int NULL,
  Research_Status_Id Int NULL,
  Research_Open_Date DateTime NULL, 
  Research_Close_Date DateTIme NULL,
  Research_User_Id Int NULL,
  Prod_Id int NULL,
  Crew_Desc nVarChar(10) Null,
  Shift_Desc nVarChar(10) Null,
  PU_Desc nVarChar(50) Null,
  Group_Id Int Null,
  Comment_Id Int Null
 )
 Select @SQLCommand = 'Insert Into #WasteTemp ' + @SQLCommand 
  Exec (@SQLCommand)
---------------------------------------------------------------
-- If passed EventIds, filter them
---------------------------------------------------------------
 If (@EventIds Is Not Null and Len(@EventIds)>0)
  Begin
   Create Table #EI(
    Event_Id Int Null
   )
   Create Table #WasteEvent (
    Wed_Id Int NULL,
    PU_Id Int NULL,
    TimeStamp DateTime NULL,
    Event_Id Int NULL,
    Wet_Id Int NULL,
    Amount Real NULL,
    Reason_Level1 Int NULL,
    Reason_Level2 Int NULL,
    Reason_Level3 Int NULL,
    Reason_Level4 Int NULL,
    Action_Level1 Int NULL,
    Action_Level2 Int NULL,
    Action_Level3 Int NULL,
    Action_Level4 Int NULL,
    Research_Status_Id Int NULL,
    Research_Open_Date DateTime NULL, 
    Research_Close_Date DateTIme NULL,
    Research_User_Id Int NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   Select @EndPosition=0
   Select @EndPosition=CharIndex("\",@EventIDs)
   While (@EndPosition<>0)
    Begin
     Select @EventId = Convert(Int,Substring(@EventIds,1,(@EndPosition-1)))
     Insert Into #EI Values (@EventId)
     Select @EventIds =  Right(@EventIds, Len(@EventIds)- @EndPosition)
     Select @EndPosition=CharIndex("\",@EventIds)
    End -- while loop
   Insert Into #WasteEvent
    Select T.Wed_Id,T.PU_Id, T.TimeStamp, T.Event_Id, T.Wet_Id, T.Amount, T.Reason_Level1, 
    T.Reason_Level2, T.Reason_Level3, T.Reason_Level4, T.Action_Level1, T.Action_Level2, 
    T.Action_Level3, T.Action_Level4, T.Research_Status_Id, T.Research_Open_Date, 
    T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
    T.PU_Desc, T.Group_Id, T.Comment_Id  
     From #WasteTemp T Inner Join #EI E On T.Event_Id=E.Event_Id
   Delete From #WasteTemp
   Insert Into #WasteTemp
    Select * From #WasteEvent
   Drop Table #WasteEvent
   Drop Table #EI
  End
----------------------------------------------------------------
-- If passed ProductionUnits, filter them: parse @ProductionUnits dumping it
-- on PU table and inner join it with UDETemp
-----------------------------------------------------------------
 If (@ProductionUnits Is Not Null And Len(@ProductionUnits) > 0) 
  Begin
   Create Table #PU (
    PU_id Int Null
   )
   Create Table #WastePU (
    Wed_Id Int NULL,
    PU_Id Int NULL,
    TimeStamp DateTime NULL,
    Event_Id Int NULL,
    Wet_Id Int NULL,
    Amount Real NULL,
    Reason_Level1 Int NULL,
    Reason_Level2 Int NULL,
    Reason_Level3 Int NULL,
    Reason_Level4 Int NULL,
    Action_Level1 Int NULL,
    Action_Level2 Int NULL,
    Action_Level3 Int NULL,
    Action_Level4 Int NULL,
    Research_Status_Id Int NULL,
    Research_Open_Date DateTime NULL, 
    Research_Close_Date DateTIme NULL,
    Research_User_Id Int NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   Select @EndPosition=0
   Select @EndPosition=CharIndex("\",@ProductionUnits)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
     Insert Into #PU Values (@PUId)
     Select @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
     Select @EndPosition=CharIndex("\",@ProductionUnits)
    End -- while loop
   Insert Into #WastePU 
    Select T.Wed_Id,T.PU_Id, T.TimeStamp, T.Event_Id, T.Wet_Id, T.Amount, T.Reason_Level1, 
     T.Reason_Level2, T.Reason_Level3, T.Reason_Level4, T.Action_Level1, T.Action_Level2, 
     T.Action_Level3, T.Action_Level4, T.Research_Status_Id, T.Research_Open_Date, 
     T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
     T.PU_Desc, T.Group_Id, T.Comment_Id    
      From #WasteTemp T Inner Join #PU P On  T.PU_id = P.PU_Id
   Delete From #WasteTemp
   Insert Into #WasteTemp
    Select * From #WastePU 
   Drop Table #WastePU
   Drop Table #PU
  End
----------------------------------------------------------------------
-- If passed products filter them
---------------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0) 
  Begin
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select WED_Id, TimeStamp, PU_Id From #WasteTemp)
     For Read Only
   Open ProdCursor
 ProdLoop:
   Fetch Next From ProdCursor Into  @WedId, @TimeStamp, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ProdId = NULL
    Select @ProdId = Prod_Id 
     From Production_Starts 
      Where PU_Id = @PUId 
       And @TimeStamp >=Start_Time 
        And (@TimeStamp < End_Time Or End_Time Is Null)
     If (@ProdId Is Not Null) 
      Update #WasteTemp Set Prod_Id = @ProdId Where Wed_Id = @WedId
    Goto ProdLoop
   End
  Close ProdCursor
  Deallocate ProdCursor
  Create Table #Prod (
   Prod_id Int Null
  )
  Create Table #WasteProd (
   Wed_Id Int NULL,
   PU_Id Int NULL,
   TimeStamp DateTime NULL,
   Event_Id Int NULL,
   Wet_Id Int NULL,
   Amount Real NULL,
   Reason_Level1 Int NULL,
   Reason_Level2 Int NULL,
   Reason_Level3 Int NULL,
   Reason_Level4 Int NULL,
   Action_Level1 Int NULL,
   Action_Level2 Int NULL,
   Action_Level3 Int NULL,
   Action_Level4 Int NULL,
   Research_Status_Id Int NULL,
   Research_Open_Date DateTime NULL, 
   Research_Close_Date DateTIme NULL,
   Research_User_Id Int NULL,
   Prod_Id int NULL,
   Crew_Desc nVarChar(10) Null,
   Shift_Desc nVarChar(10) Null,
   PU_Desc nVarChar(50) Null,
   Group_Id Int Null,
   Comment_Id Int Null
  )
  Select @EndPosition=CharIndex("\",@Products)
  While (@EndPosition<>0)
   Begin
    Select @ProdId = Convert(Int,Substring(@Products,1,(@EndPosition-1)))
    Insert Into #Prod Values (@ProdId)
    Select @Products =  Right(@Products, Len(@Products)- @EndPosition)
    Select @EndPosition=CharIndex("\",@Products)
   End -- while loop
  Insert Into #WasteProd 
   Select T.Wed_Id,T.PU_Id, T.TimeStamp, T.Event_Id, T.Wet_Id, T.Amount, T.Reason_Level1, 
    T.Reason_Level2, T.Reason_Level3, T.Reason_Level4, T.Action_Level1, T.Action_Level2, 
    T.Action_Level3, T.Action_Level4, T.Research_Status_Id, T.Research_Open_Date, 
    T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
    T.PU_Desc, T.Group_Id, T.Comment_Id   
    From #WasteTemp T Inner Join #Prod P On  T.Prod_id = P.Prod_Id
  Delete From #WasteTemp
  Insert Into #WasteTemp
   Select * From #WasteProd 
  Drop Table #WasteProd
  Drop Table #Prod
 End
----------------------------------------------------------------------
-- If passed CrewDescParam filter it
---------------------------------------------------------------------
 If (@CrewDescParam Is Not Null And Len(@CrewDescParam) > 0) 
  Begin
   Declare CrewCursor INSENSITIVE CURSOR
    For (Select Wed_Id, TimeStamp, PU_Id From #WasteTemp)
     For Read Only
   Open CrewCursor
 CrewLoop:
   Fetch Next From CrewCursor Into  @WedId, @TimeStamp, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @CrewDesc = NULL
    Select @CrewDesc = Crew_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @TimeStamp >=Start_Time 
        And (@TimeStamp < End_Time Or End_Time Is Null)
     If (@CrewDesc Is Not Null) 
      Update #WasteTemp Set Crew_Desc = @CrewDesc Where Wed_Id = @WedId
     Goto CrewLoop
   End
   Close CrewCursor
   Deallocate CrewCursor
   Delete From #WasteTemp 
    Where Crew_Desc <> @CrewDescParam Or Crew_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed ShiftDescParam filter it
---------------------------------------------------------------------
 If (@ShiftDescParam Is Not Null And Len(@ShiftDescParam) > 0) 
  Begin
   Declare ShiftCursor INSENSITIVE CURSOR
    For (Select Wed_Id, TimeStamp, PU_Id From #WasteTemp)
     For Read Only
   Open ShiftCursor
 ShiftLoop:
   Fetch Next From ShiftCursor Into  @WedId, @TimeStamp, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ShiftDesc = NULL
    Select @ShiftDesc = Shift_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @TimeStamp >=Start_Time 
        And (@TimeStamp < End_Time Or End_Time Is Null)
     If (@ShiftDesc Is Not Null) 
      Update #WasteTemp Set Shift_Desc = @ShiftDesc Where Wed_Id = @WEdId
     Goto ShiftLoop
   End
   Close ShiftCursor
   Deallocate ShiftCursor
   Delete From #WasteTemp 
    Where Shift_Desc <> @ShiftDescParam Or Shift_Desc Is Null
  End
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Time Stamp')
 	 Insert into @T(TimeColumns) Values ('Research Open Date')
 	 Insert into @T(TimeColumns) Values ('Research Close Date')
 	 Insert into @CHT(HeaderTag,Idx) Values (16304,1) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16466,2) -- Time Stamp
 	 Insert into @CHT(HeaderTag,Idx) Values (16478,3) -- Amount
 	 Insert into @CHT(HeaderTag,Idx) Values (16106,4) -- Description
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Unit] = T.PU_Desc,
 	  	  	 [Time Stamp] = T.TimeStamp,
 	  	  	 [Amount] = T.Amount, 
 	  	  	 [Description] = 'Waste' + ' ' + Replace(RTrim(Convert(nVarChar(25), Convert(decimal(10,1), WD.Amount))), '.', @DecimalSep) + ' ' + Coalesce(M.Wemt_Name,'') + 
 	  	  	  	 ' at ' + + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
 	  	  	  	 Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
 	  	  	  	 Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
 	  	  	  	 Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End, 
 	  	  	 [Waste Detail Id] = T.Wed_Id, 
 	  	  	 [Unit Id] = T.PU_Id, 
 	  	  	 [Event Id] = T.Event_Id, 
 	  	  	 [Waste Id] = T.Wet_Id, 
 	  	  	 [Reason 1] = T.Reason_Level1, 
 	  	  	 [Reason 2] = T.Reason_Level2, 
 	  	  	 [Reason 3] = T.Reason_Level3, 
 	  	  	 [Reason 4] = T.Reason_Level4, 
 	  	  	 [Action 1] = T.Action_Level1, 
 	  	  	 [Action 2] = T.Action_Level2, 
 	  	  	 [Action 3] = T.Action_Level3, 
 	  	  	 [Action 4] = T.Action_Level4, 
 	  	  	 [Research Status Id] = T.Research_Status_Id, 
 	  	  	 [Research Open Date] = T.Research_Open_Date, 
 	  	  	 [Research Close Date] = T.Research_Close_Date, 
 	  	  	 [Research User Id] = T.Research_User_Id, 
 	  	  	 [Product Id] = T.Prod_Id, 
 	  	  	 [Crew Desc] = T.Crew_Desc, 
 	  	  	 [Shift Desc] = T.Shift_Desc, 
 	  	  	 [Group Id] = T.Group_Id, 
 	  	  	 [Comment Id] = T.Comment_Id
 	 From #WasteTemp T 
 	 Join Prod_Units P on P.PU_Id = T.PU_Id
 	 Inner Join Waste_Event_Details WD On WD.Wed_Id = T.Wed_Id
 	 Left Outer Join Waste_Event_Meas M On WD.WEMT_Id = M.WEMT_Id
 	 Left Outer Join Event_Reasons RE  On WD.Reason_Level1 = RE.Event_Reason_Id
 	 Left Outer Join Event_Reasons RE2 On WD.Reason_Level2 = RE2.Event_Reason_Id
 	 Left Outer Join Event_Reasons RE3 On WD.Reason_Level3 = RE3.Event_Reason_Id
 	 Left Outer Join Event_Reasons RE4 On WD.Reason_Level4 = RE4.Event_Reason_Id
   Order By  T.TimeStamp desc
END
ELSE
BEGIN
Select T.PU_Desc as 'Unit Desc', T.TimeStamp as 'Time Stamp', T.Amount, 
  'Waste' + ' ' + Replace(RTrim(Convert(nVarChar(25), Convert(decimal(10,1), WD.Amount))), '.', @DecimalSep) + ' ' + Coalesce(M.Wemt_Name,'') + 
    ' at ' + + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
    Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
    Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
    Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End as 'SOE Desc', 
 T.Wed_Id as 'Waste Detail Id', T.PU_Id as 'Unit Id', T.Event_Id as 'Event Id', 
 T.Wet_Id as 'Waste Id', T.Reason_Level1 as 'Reason 1', T.Reason_Level2 as 'Reason 2', T.Reason_Level3 as 'Reason 3', T.Reason_Level4 as 'Reason 4', T.Action_Level1 as 'Action 1', 
 T.Action_Level2 as 'Action 2', T.Action_Level3 as 'Action 3', T.Action_Level4 as 'Action 4', T.Research_Status_Id as 'Research Status Id', T.Research_Open_Date as 'Research Open Date', 
 T.Research_Close_Date as 'Research Close Date', T.Research_User_Id as 'Research User Id', T.Prod_Id as 'Product Id', T.Crew_Desc as 'Crew Desc', 
 T.Shift_Desc as 'Shift Desc', T.Group_Id as 'Group Id', T.Comment_Id as 'Comment Id'
   From #WasteTemp T 
    Join Prod_Units P on P.PU_Id = T.PU_Id
    Inner Join Waste_Event_Details WD On WD.Wed_Id = T.Wed_Id
    Left Outer Join Waste_Event_Meas M On WD.WEMT_Id = M.WEMT_Id
    Left Outer Join Event_Reasons RE  On WD.Reason_Level1 = RE.Event_Reason_Id
    Left Outer Join Event_Reasons RE2 On WD.Reason_Level2 = RE2.Event_Reason_Id
    Left Outer Join Event_Reasons RE3 On WD.Reason_Level3 = RE3.Event_Reason_Id
    Left Outer Join Event_Reasons RE4 On WD.Reason_Level4 = RE4.Event_Reason_Id
   Order By  T.TimeStamp desc
END
 Drop Table #WasteTemp

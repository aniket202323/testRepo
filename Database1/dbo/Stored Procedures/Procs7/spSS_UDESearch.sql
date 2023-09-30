Create Procedure dbo.spSS_UDESearch
 @ProductionUnits nVarChar(1024) = NULL,
 @EventSubTypes nVarChar(1024) = NULL,
 @StartDate1 DateTime = NULL,
 @StartDate2 DateTime = NULL,
 @FilterOpen int = NULL,
 @UDEDescription nVarChar(50) = NULL,
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
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @UDEId int, 
         @StartTime DateTime, 
         @PUId int,
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int,
         @CrewDesc nVarChar(10),
         @ShiftDesc nVarChar(10)
-- Insert Into DebugSearchAlarm Values (getDate(), @StartDate1, @StartDate2)
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select U.UDE_Id, U.UDE_Desc, U.PU_Id, U.Event_SubType_Id, U.Start_Time, ' +
                       'U.End_Time, U.Ack, U.Ack_On, U.Ack_By, U.Cause1, U.Cause2, ' +
                       'U.Cause3, U.Cause4, U.Action1, U.Action2, U.Action3, U.Action4, ' +
                       'U.Research_User_Id, U.Research_Status_Id, U.Research_Open_Date, ' + 
                       'U.Research_Close_Date, Null as Prod_Id, Null as Crew_Desc,  ' +
                       'Null as Shift_Desc, PU.PU_Desc, PU.Group_Id, U.Cause_Comment_Id ' +
                       'From User_Defined_Events U ' +
                       'Inner Join Prod_Units PU On U.PU_Id = PU.PU_Id ' +
                       'Left Outer Join Event_SubTypes ES On U.Event_SubType_Id = ES.Event_SubType_Id ' +
                       'Left Outer Join Research_Status RS On U.Research_Status_Id = RS.Research_Status_Id ' +
 	  	        'Left Outer Join Comments CO On U.Cause_Comment_Id = CO.Comment_Id ' +
                       'Left Outer Join Comments CO2 On U.Action_Comment_Id = CO2.Comment_Id '        	       
--------------------------------------------------------------------
-- Start Dates
--------------------------------------------------------------------
 If (@StartDate1 Is Not Null And @StartDate1>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " U.Start_Time Between '" + Convert(nVarChar(30), @StartDate1) + "' And '" +
                      Convert(nVarChar(30), @StartDate2) + "'"   
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
------------------------------------------------------------------------
-- Filter Open
-----------------------------------------------------------------------
 If (@FilterOpen Is Not Null) 
  Begin
   If (@FilterOpen = 1) -- only opened alarms
    Begin
     Select @SQLCond0 = 'U.End_Time Is NULL'
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
   End
-------------------------------------------------------------------
-- UDE Description
-----------------------------------------------------------------------
 If (@UDEDescription Is Not Null And Len(@UDEDescription)>0)
  Begin
   Select @SQLCond0 = "U.UDE_Desc Like '%" + @UDEDescription + "%'"
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
  When 1 Then 'U.Research_Open_Date Is Not Null And U.Research_CLose_Date Is Null'
  When 2 Then 'U.Research_Open_Date Is Not Null And U.Research_CLose_Date Is Not Null'
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
   Select @SQLCond0 = 'U.Cause4=' + Convert(nVarChar(05),@Cause4 )
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
   Select @SQLCond0 = 'U.Cause3=' + Convert(nVarChar(05),@Cause3 )
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
   Select @SQLCond0 = 'U.Cause2=' + Convert(nVarChar(05),@Cause2 )
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
   Select @SQLCond0 = 'U.Cause1=' + Convert(nVarChar(05),@Cause1 )
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
   Select @SQLCond0 = 'U.Action4=' + Convert(nVarChar(05),@Action4 )
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
   Select @SQLCond0 = 'U.Action3=' + Convert(nVarChar(05),@Action3 )
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
   Select @SQLCond0 = 'U.Action2=' + Convert(nVarChar(05),@Action2 )
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
   Select @SQLCond0 = 'U.Action1=' + Convert(nVarChar(05),@Action1 )
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
 Create Table #UDETemp (
  UDE_Id int NULL,
  UDE_Desc nVarChar(50) NULL,
  PU_Id Int NULL,
  Event_SubType_Id Int NULL,
  Start_Time DateTime NULL,
  End_Time DateTime NULL,
  Ack Int NULL,
  Ack_On DateTime NULL, 
  Ack_By nVarChar(50) NULL,
  Cause1 int NULL,
  Cause2 int NULL,
  Cause3 int NULL,
  Cause4 int NULL,
  Action1 int NULL,
  Action2 int NULL,
  Action3 int NULL,
  Action4 int NULL,
  Research_User_Id int NULL,
  Research_Status_Id int NULL,
  Research_Open_Date DateTime NULL,
  Research_Close_Date DateTime NULL, 
  Prod_Id int NULL,
  Crew_Desc nVarChar(10) Null,
  Shift_Desc nVarChar(10) Null,
  PU_Desc nVarChar(50) Null,
  Group_Id Int Null,
  Comment_Id Int Null
 )
 Select @SQLCommand = 'Insert Into #UDETemp ' + @SQLCommand 
/*
   Select Substring(@SQLCommand,1,100)
   Select Substring(@SQLCommand,101,200)
   Select Substring(@SQLCommand,201,300)
   Select Substring(@SQLCommand,301,400)
   Select Substring(@SQLCommand,201,50)
   Select Substring(@SQLCommand,251,50)
   Select Substring(@SQLCommand,301,50)
   Select Substring(@SQLCommand,351,50)
   Select Substring(@SQLCommand,401,50)
   Select Substring(@SQLCommand,451,50)
   Select Substring(@SQLCommand,501,50)
   Select Substring(@SQLCommand,551,50)
   Select Substring(@SQLCommand,601,50)
   Select Substring(@SQLCommand,651,50)
   Select Substring(@SQLCommand,701,50)
   Select Substring(@SQLCommand,751,50)
   Select Substring(@SQLCommand,801,50)
   Select Substring(@SQLCommand,851,50)
   Select Substring(@SQLCommand,901,50)
   Select Substring(@SQLCommand,951,50)
   Select Substring(@SQLCommand,1001,50)
   Select Substring(@SQLCommand,1051,50)
   Select Substring(@SQLCommand,1101,50)
*/
  Exec (@SQLCommand)
----------------------------------------------------------------
-- If passed ProductionUnits, filter them: parse @ProductionUnits dumping it
-- on PU table and inner join it with UDETemp
-----------------------------------------------------------------
 If (@ProductionUnits Is Not Null And Len(@ProductionUnits) > 0) 
  Begin
   Create Table #PU (
    PU_id Int Null
   )
   Create Table #UDEPU (
    UDE_Id int NULL,
    UDE_Desc nVarChar(50) NULL,
    PU_Id Int NULL,
    Event_SubType_Id Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Ack Int NULL,
    Ack_On DateTime NULL, 
    Ack_By nVarChar(50) NULL,
    Cause1 int NULL,
    Cause2 int NULL,
    Cause3 int NULL,
    Cause4 int NULL,
    Action1 int NULL,
    Action2 int NULL,
    Action3 int NULL,
    Action4 int NULL,
    Research_User_Id int NULL,
    Research_Status_Id int NULL,
    Research_Open_Date DateTime NULL,
    Research_Close_Date DateTime NULL, 
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   Select @EndPosition=CharIndex("\",@ProductionUnits)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
     Insert Into #PU Values (@PUId)
     Select @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
     Select @EndPosition=CharIndex("\",@ProductionUnits)
    End -- while loop
   Insert Into #UDEPU 
   Select T.UDE_Id, T.UDE_Desc, T.PU_Id, T.Event_SubType_Id, T.Start_Time, T.End_Time, T.Ack,
    T.Ack_On, T.Ack_By, T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, T.Action2,
    T.Action3, T.Action4, T.Research_User_Id, T.Research_Status_Id, T.Research_Open_Date,
    T.Research_Close_Date, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.PU_Desc, T.Group_Id, T.Comment_Id
     From #UDETemp T Inner Join #PU P On  T.PU_id = P.PU_Id
   Delete From #UDETemp
   Insert Into #UDETemp
    Select * From #UDEPU 
   Drop Table #UDEPU
   Drop Table #PU
  End
----------------------------------------------------------------
-- If passed ProductionUnits, filter them: parse @ProductionUnits dumping it
-- on PU table and inner join it with UDETemp
-----------------------------------------------------------------
 If (@EventSubTypes Is Not Null And Len(@EventSubTypes) > 0) 
  Begin
   Create Table #ES (
    Event_SubType_id Int Null
   )
   Create Table #UDEES (
    UDE_Id int NULL,
    UDE_Desc nVarChar(50) NULL,
    PU_Id Int NULL,
    Event_SubType_Id Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Ack Int NULL,
    Ack_On DateTime NULL, 
    Ack_By nVarChar(50) NULL,
    Cause1 int NULL,
    Cause2 int NULL,
    Cause3 int NULL,
    Cause4 int NULL,
    Action1 int NULL,
    Action2 int NULL,
    Action3 int NULL,
    Action4 int NULL,
    Research_User_Id int NULL,
    Research_Status_Id int NULL,
    Research_Open_Date DateTime NULL,
    Research_Close_Date DateTime NULL, 
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   Select @EndPosition=CharIndex("\",@EventSubTypes)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@EventSubTypes,1,(@EndPosition-1)))
     Insert Into #ES Values (@PUId)
     Select @EventSubTypes =  Right(@EventSubTypes, Len(@EventSubTypes)- @EndPosition)
     Select @EndPosition=CharIndex("\",@EventSubTypes)
    End -- while loop
   Insert Into #UDEES 
   Select T.UDE_Id, T.UDE_Desc, T.PU_Id, T.Event_SubType_Id, T.Start_Time, T.End_Time, T.Ack,
    T.Ack_On, T.Ack_By, T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, T.Action2,
    T.Action3, T.Action4, T.Research_User_Id, T.Research_Status_Id, T.Research_Open_Date,
    T.Research_Close_Date, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,T.PU_Desc, T.Group_Id, T.Comment_Id
     From #UDETemp T Inner Join #ES E On  T.Event_SubType_Id = E.Event_SubType_Id
   Delete From #UDETemp
   Insert Into #UDETemp
    Select * From #UDEES 
   Drop Table #UDEES
   Drop Table #ES
  End
----------------------------------------------------------------------
-- If passed products filter them
---------------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0) 
  Begin
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select UDE_Id, Start_Time, PU_Id From #UDETemp)
     For Read Only
   Open ProdCursor
 ProdLoop:
   Fetch Next From ProdCursor Into  @UDEId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ProdId = NULL
    Select @ProdId = Prod_Id 
     From Production_Starts 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ProdId Is Not Null) 
      Update #UDETemp Set Prod_Id = @ProdId Where UDE_Id = @UDEId
    Goto ProdLoop
   End
  Close ProdCursor
  Deallocate ProdCursor
  Create Table #Prod (
   Prod_id Int Null
  )
  Create Table #UDEProd (
   UDE_Id int NULL,
   UDE_Desc nVarChar(50) NULL,
   PU_Id Int NULL,
   Event_SubType_Id Int NULL,
   Start_Time DateTime NULL,
   End_Time DateTime NULL,
   Ack Int NULL,
   Ack_On DateTime NULL, 
   Ack_By nVarChar(50) NULL,
   Cause1 int NULL,
   Cause2 int NULL,
   Cause3 int NULL,
   Cause4 int NULL,
   Action1 int NULL,
   Action2 int NULL,
   Action3 int NULL,
   Action4 int NULL,
   Research_User_Id int NULL,
   Research_Status_Id int NULL,
   Research_Open_Date DateTime NULL,
   Research_Close_Date DateTime NULL, 
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
  Insert Into #UDEProd 
   Select T.UDE_Id, T.UDE_Desc, T.PU_Id, T.Event_SubType_Id, T.Start_Time, T.End_Time, T.Ack,
    T.Ack_On, T.Ack_By, T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, T.Action2,
    T.Action3, T.Action4, T.Research_User_Id, T.Research_Status_Id, T.Research_Open_Date,
    T.Research_Close_Date, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.PU_Desc, T.Group_Id, T.Comment_Id
     From #UDETemp T Inner Join #Prod P On  T.Prod_id = P.Prod_Id
  Delete From #UDETemp
  Insert Into #UDETemp
   Select * From #UDEProd 
  Drop Table #UDEProd
  Drop Table #Prod
 End
----------------------------------------------------------------------
-- If passed CrewDescParam filter it
---------------------------------------------------------------------
 If (@CrewDescParam Is Not Null And Len(@CrewDescParam) > 0) 
  Begin
   Declare CrewCursor INSENSITIVE CURSOR
    For (Select UDE_Id, Start_Time, PU_Id From #UDETemp)
     For Read Only
   Open CrewCursor
 CrewLoop:
   Fetch Next From CrewCursor Into  @UDEId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @CrewDesc = NULL
    Select @CrewDesc = Crew_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@CrewDesc Is Not Null) 
      Update #UDETemp Set Crew_Desc = @CrewDesc Where UDE_Id = @UDEId
     Goto CrewLoop
   End
   Close CrewCursor
   Deallocate CrewCursor
   Delete From #UDETemp 
    Where Crew_Desc <> @CrewDescParam Or Crew_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed ShiftDescParam filter it
---------------------------------------------------------------------
 If (@ShiftDescParam Is Not Null And Len(@ShiftDescParam) > 0) 
  Begin
   Declare ShiftCursor INSENSITIVE CURSOR
    For (Select UDE_Id, Start_Time, PU_Id From #UDETemp)
     For Read Only
   Open ShiftCursor
 ShiftLoop:
   Fetch Next From ShiftCursor Into  @UDEId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ShiftDesc = NULL
    Select @ShiftDesc = Shift_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ShiftDesc Is Not Null) 
      Update #UDETemp Set Shift_Desc = @ShiftDesc Where UDE_Id = @UDEId
     Goto ShiftLoop
   End
   Close ShiftCursor
   Deallocate ShiftCursor
   Delete From #UDETemp 
    Where Shift_Desc <> @ShiftDescParam Or Shift_Desc Is Null
  End
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (16304,1) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,2) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16333,3) -- End Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16106,4) -- Description
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Unit] = T.PU_Desc, 
 	  	  	 [Start Time] = T.Start_Time,
 	  	  	 [End Time] = T.End_Time, 
 	  	  	 [Description] = Case  When T.Cause1 is Null Then Coalesce(ES.Event_SubType_Desc,'')Else
 	  	  	  	 Coalesce(ES.Event_SubType_Desc,'') + ' for ' + Coalesce(RTrim(ER.EVent_Reason_Name),'') End,
 	  	  	 [Tag] = T.UDE_Id, 
 	  	  	 [UDE Desc] = T.UDE_Desc, 
 	  	  	 [Unit Id] = T.PU_Id, 
 	  	  	 [Event Subtype Id] = T.Event_SubType_Id, 
 	  	  	 [Acknowledged] = T.Ack, 
 	  	  	 [Acknowledged On] = T.Ack_On, 
 	  	  	 [Acknowledged By] = T.Ack_By, 
 	  	  	 [Cause 1] = T.Cause1, 
 	  	  	 [Cause 2] = T.Cause2, 
 	  	  	 [Cause 3] = T.Cause3, 
 	  	  	 [Cause 4] = T.Cause4, 
 	  	  	 [Action 1] = T.Action1, 
 	  	  	 [Action 2] = T.Action2,
 	  	  	 [Action 3] = T.Action3,
 	  	  	 [Action 4] = T.Action4, 
 	  	  	 [Research User Id] = T.Research_User_Id, 
 	  	  	 [Research Status Id] = T.Research_Status_Id, 
 	  	  	 [Research Open Date] = T.Research_Open_Date, 
 	  	  	 [Research Close Date] = T.Research_Close_Date, 
 	  	  	 [Product Id] = T.Prod_Id, 
 	  	  	 [Crew Desc] = T.Crew_Desc, 
 	  	  	 [Shift Desc] = T.Shift_Desc, 
 	  	  	 [Group Id] = T.Group_Id, 
 	  	  	 [Comment Id] = T.Comment_Id
 	 From #UDETemp T 
 	 Left Join Event_SubTypes ES on T.Event_SubType_Id = ES.Event_SubType_Id
 	 Left Join Event_Reasons ER On T.Cause1 = ER.Event_Reason_Id
 	 Order By T.Start_Time desc
END
ELSE
BEGIN
 Select T.PU_Desc as 'Unit Desc', T.Start_Time as 'Start Time', T.End_Time as 'End Time', 
   Case  When T.Cause1 is Null Then Coalesce(ES.Event_SubType_Desc,'')Else
   Coalesce(ES.Event_SubType_Desc,'') + ' for ' + Coalesce(RTrim(ER.EVent_Reason_Name),'') End as 'SOE Desc',
   T.UDE_Id as 'UDE Id', T.UDE_Desc as 'UDE Desc', T.PU_Id as 'Unit Id', T.Event_SubType_Id as 'Event Subtype Id', 
   T.Ack as 'Acknowledged', T.Ack_On as 'Acknowledged On', T.Ack_By as 'Acknowledged By', T.Cause1 as 'Cause 1', 
   T.Cause2 as 'Cause 2', T.Cause3 as 'Cause 3', T.Cause4 as 'Cause 4', T.Action1 as 'Action 1', T.Action2 as 'Action 2',
   T.Action3 as 'Action 3', T.Action4 as 'Action 4', T.Research_User_Id as 'Research User Id', 
   T.Research_Status_Id as 'Research Status Id', T.Research_Open_Date as 'Research Open Date', 
   T.Research_Close_Date as 'Research Close Date', T.Prod_Id as 'Product Id', T.Crew_Desc as 'Crew Desc', 
   T.Shift_Desc as 'Shift Desc', T.Group_Id as 'Group Id', T.Comment_Id as 'Comment Id'
  From #UDETemp T 
   Left Outer Join Event_SubTypes ES on T.Event_SubType_Id = ES.Event_SubType_Id
   Left Outer Join Event_Reasons ER On T.Cause1 = ER.Event_Reason_Id
   Order By T.Start_Time desc
END
 Drop Table #UDETemp

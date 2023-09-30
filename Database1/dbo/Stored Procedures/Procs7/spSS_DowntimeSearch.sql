CREATE Procedure dbo.spSS_DowntimeSearch
 @ProductionUnits nVarChar(1024) = NULL,
 @FaultIds nVarChar(1024)=NULL,
 @StartDate1 DateTime = NULL,
 @StartDate2 DateTime = NULL,
 @FilterOpen int = NULL,
 @StatusDescription nVarChar(50) = NULL, 
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
 	 SELECT @RegionalServer = 0
 SELECT @DecimalSep = COALESCE(@DecimalSep,'.')
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @DowntimeId int, 
         @TEDetId int, 
         @StartTime DateTime, 
         @PUId int,
         @FaultId int, 
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int,
         @CrewDesc nVarChar(10),
         @ShiftDesc nVarChar(10)
--------------------------------------------
-- Initialize variables
---------------------------------------------
 SELECT @FlgFirst= 0
 SELECT @FlgAnd = 0
 SELECT @SQLCOnd0 = NULL
-- Any modification to this SELECT statement should also be done on the #alarm table
  SELECT @SQLCommand = 'SELECT D.TEDET_Id, D.PU_Id, D.Start_Time, D.End_Time, D.Reason_Level1, ' +
                       'D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, ' + 
                       'D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEStatus_Id, ' + 
                       'D.TEFault_Id, D.Research_Status_Id, D.Research_Open_Date, ' +
                       'D.Research_Close_Date, D.Research_User_Id, Null As Prod_Id, ' + 
                       'Null As Crew_Desc, Null As Shift_Desc, ' +
                       'PU.PU_Desc, PU.Group_Id, D.Cause_Comment_Id ' +
                       'From Timed_Event_Details D ' +
                       'Inner Join Prod_Units PU On D.PU_Id = PU.PU_Id ' + 
                       'Left Outer Join Research_Status RS On D.Research_Status_Id = RS.Research_Status_Id ' +
 	  	  	  	  	    'Left Outer Join Comments CO On D.Cause_Comment_Id = CO.Comment_Id ' +
                       'Left Outer Join Comments CO2 On D.Action_Comment_Id = CO2.Comment_Id '   
--------------------------------------------------------------------
-- Start Dates
--------------------------------------------------------------------
 If (@StartDate1 Is Not Null And @StartDate1>'01-Jan-1970')
  Begin
   SELECT @SQLCond0 = " D.Start_Time Between '" + Convert(nVarChar(30), @StartDate1) + "' And '" +
                      Convert(nVarChar(30), @StartDate2) + "'"   
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End
   End
------------------------------------------------------------------------
-- Filter Open
-----------------------------------------------------------------------
 If (@FilterOpen Is Not Null) 
  Begin
   If (@FilterOpen = 1) -- only opened alarms
    Begin
     SELECT @SQLCond0 = 'D.End_Time Is NULL'
     If (@FlgAnd=1)
      Begin
       SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
      End
     Else
      Begin
       SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
       SELECT @FlgAnd = 1  
      End 
    End  
   End
------------------------------------------------------
--  Research status Open
------------------------------------------------------
 SELECT @SQLCond0 = NULL
 SELECT @SQLCond0 = 
 Case @ResearchStatusOpen
  When 1 Then 'D.Research_Open_Date Is Not Null And D.Research_CLose_Date Is Null'
  When 2 Then 'D.Research_Open_Date Is Not Null And D.Research_CLose_Date Is Not Null'
 End
 If (@SQLCond0 Is Not Null)
  Begin
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Cause Comment Description
-----------------------------------------------------------------------
 If (@CauseComment Is Not Null And Len(@CauseComment)>0)
  Begin
   SELECT @SQLCond0 = "CO.Comment Like '%" + @CauseComment + "%'"
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Action Comment Description
-----------------------------------------------------------------------
 If (@ActionComment Is Not Null And Len(@ActionComment)>0)
  Begin
   SELECT @SQLCond0 = "CO2.Comment Like '%" + @ActionComment + "%'"
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Statistics 
------------------------------------------------------------------
 If (@Statistics Is Not Null And Len(@Statistics)>0)
  Begin
   SELECT @SQLCond0 = Null
   SELECT @EndPosition=CharIndex("\",@Statistics)
   While (@EndPosition<>0)
    Begin 
     SELECT @SQLCond0 =  Substring(@Statistics,1,(@EndPosition-1))
     If (@FlgAnd=1)
      Begin
       SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
      End
     Else
      Begin
       SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
       SELECT @FlgAnd = 1  
      End  	  
     SELECT @Statistics =  Right(@Statistics, Len(@Statistics)- @EndPosition)
     SELECT @EndPosition=CharIndex("\",@Statistics)
    End -- while loop
  End
---------------------------------------------
-- Causes
----------------------------------------------
 If (@Cause4 Is Not Null And @Cause4<>0)
  Begin
   SELECT @SQLCond0 = 'D.Reason_Level4=' + Convert(nVarChar(05),@Cause4 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
 If (@Cause3 Is Not Null And @Cause3<>0)
  Begin
   SELECT @SQLCond0 = 'D.Reason_Level3=' + Convert(nVarChar(05),@Cause3 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
 If (@Cause2 Is Not Null And @Cause2<>0)
  Begin
   SELECT @SQLCond0 = 'D.Reason_Level2=' + Convert(nVarChar(05),@Cause2 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
 If (@Cause1 Is Not Null And @Cause1<>0)
  Begin
   SELECT @SQLCond0 = 'D.Reason_Level1=' + Convert(nVarChar(05),@Cause1 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
---------------------------------------------
-- Actions
----------------------------------------------
 If (@Action4 Is Not Null And @Action4<>0)
  Begin
   SELECT @SQLCond0 = 'D.Action_Level4=' + Convert(nVarChar(05),@Action4 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
 If (@Action3 Is Not Null And @Action3<>0)
  Begin
   SELECT @SQLCond0 = 'D.Action_Level3=' + Convert(nVarChar(05),@Action3 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
 If (@Action2 Is Not Null And @Action2<>0)
  Begin
   SELECT @SQLCond0 = 'D.Action_Level2=' + Convert(nVarChar(05),@Action2 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
 If (@Action1 Is Not Null And @Action1<>0)
  Begin
   SELECT @SQLCond0 = 'D.Action_Level1=' + Convert(nVarChar(05),@Action1 )
   If (@FlgAnd=1)
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     SELECT @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     SELECT @FlgAnd = 1  
    End 
  End  
----------------------------------------------------------------
--  Output partial result to a temp table
-----------------------------------------------------------------
 CREATE Table #DowntimeTemp (
  TEDET_Id Int NULL,
  PU_Id Int NULL,
  Start_Time DateTime NULL,
  End_Time DateTime NULL,
  Reason_Level1 Int NULL,
  Reason_Level2 Int NULL,
  Reason_Level3 Int NULL,
  Reason_Level4 Int NULL,
  Action_Level1 Int NULL,
  Action_Level2 Int NULL,
  Action_Level3 Int NULL,
  Action_Level4 Int NULL,
  TEStatus_Id Int NULL,
  TEFault_Id Int NULL,
  Research_Status_Id int NULL,
  Research_Open_Date DateTime NULL,
  Research_Close_Date DateTime NULL,
  Research_User_Id Int NULL,
  Prod_Id Int NULL,
  Crew_Desc nVarChar(10) NULL,
  Shift_Desc nVarChar(10) NULL,
  PU_Desc nVarChar(50) Null,
  Group_Id Int Null,
  Comment_Id Int Null
 )
 SELECT @SQLCommand = 'INSERT INTO #DowntimeTemp ' + @SQLCommand 
/*
   SELECT Substring(@SQLCommand,1,100)
   SELECT Substring(@SQLCommand,101,200)
   SELECT Substring(@SQLCommand,201,300)
   SELECT Substring(@SQLCommand,301,400)
   SELECT Substring(@SQLCommand,401,500)
   SELECT Substring(@SQLCommand,501,600)
   SELECT Substring(@SQLCommand,601,700)
   SELECT Substring(@SQLCommand,701,800)
   SELECT Substring(@SQLCommand,801,900)
   SELECT Substring(@SQLCommand,901,1000)
   SELECT Substring(@SQLCommand,1001,1100)
   SELECT Substring(@SQLCommand,1101,1200)
   SELECT Substring(@SQLCommand,1201,1300)
*/
  Exec (@SQLCommand)
---------------------------------------------------------------
-- If passed FaultIds, filter them
---------------------------------------------------------------
 If (@FaultIds Is Not Null and Len(@FaultIds)>0)
  Begin
   CREATE Table #FI(
    Fault_Id Int Null
   )
   CREATE Table #DowntimeFault (
    TEDET_Id Int NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Reason_Level1 Int NULL,
    Reason_Level2 Int NULL,
    Reason_Level3 Int NULL,
    Reason_Level4 Int NULL,
    Action_Level1 Int NULL,
    Action_Level2 Int NULL,
    Action_Level3 Int NULL,
    Action_Level4 Int NULL,
    TEStatus_Id Int NULL,
    TEFault_Id Int NULL,
    Research_Status_Id int NULL,
    Research_Open_Date DateTime NULL,
    Research_Close_Date DateTime NULL,
    Research_User_Id Int NULL,
    Prod_Id Int NULL,
    Crew_Desc nVarChar(10) NULL,
    Shift_Desc nVarChar(10) NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   SELECT @EndPosition=0
   SELECT @EndPosition=CharIndex("\",@FaultIDs)
   While (@EndPosition<>0)
    Begin
     SELECT @FaultId = Convert(Int,Substring(@FaultIds,1,(@EndPosition-1)))
     INSERT INTO #FI Values (@FaultId)
     SELECT @FaultIds =  Right(@FaultIds, Len(@FaultIds)- @EndPosition)
     SELECT @EndPosition=CharIndex("\",@FaultIds)
    End -- while loop
   INSERT INTO #DowntimeFault
    SELECT T.TEDET_Id, T.PU_Id, T.Start_Time, T.End_Time, T.Reason_Level1, T.Reason_Level2, 
    T.Reason_Level3,T.Reason_Level4,T.Action_Level1, T.Action_Level2, T.Action_Level3, 
    T.Action_Level4, T.TEStatus_Id, T.TEFault_Id, T.Research_Status_Id, T.Research_Open_Date, 
    T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
    T.PU_Desc, T.Group_Id, T.Comment_Id  
     From #DowntimeTemp T Inner Join #FI E On T.TEFault_Id=E.Fault_Id
   Delete From #DowntimeTemp
   INSERT INTO #DowntimeTemp
    SELECT TEDET_Id, PU_Id, Start_Time, End_Time, Reason_Level1, Reason_Level2, 
    Reason_Level3,Reason_Level4,Action_Level1, Action_Level2, Action_Level3, 
    Action_Level4, TEStatus_Id, TEFault_Id, Research_Status_Id, Research_Open_Date, 
    Research_Close_Date, Research_User_Id, Prod_Id, Crew_Desc, Shift_Desc,
    PU_Desc, Group_Id, Comment_Id    
     From #DowntimeFault
   Drop Table #DowntimeFault
   Drop Table #FI
  End
---------------------------------------------------------------
-- If passed StatusDescrption, filter it
---------------------------------------------------------------
 If (@StatusDescription Is Not Null and Len(@StatusDescription)>0)
  Begin
   CREATE Table #ST(
    TEStatus_Id Int Null
   )
   CREATE Table #DowntimeST (
    TEDET_Id Int NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Reason_Level1 Int NULL,
    Reason_Level2 Int NULL,
    Reason_Level3 Int NULL,
    Reason_Level4 Int NULL,
    Action_Level1 Int NULL,
    Action_Level2 Int NULL,
    Action_Level3 Int NULL,
    Action_Level4 Int NULL,
    TEStatus_Id Int NULL,
    TEFault_Id Int NULL,
    Research_Status_Id int NULL,
    Research_Open_Date DateTime NULL,
    Research_Close_Date DateTime NULL,
    Research_User_Id Int NULL,
    Prod_Id Int NULL,
    Crew_Desc nVarChar(10) NULL,
    Shift_Desc nVarChar(10) NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   INSERT INTO #ST
    SELECT TEStatus_Id
     From Timed_Event_Status
      Where TEStatus_Name = @StatusDescription
   INSERT INTO #DowntimeST
    SELECT T.TEDET_Id, T.PU_Id, T.Start_Time, T.End_Time, T.Reason_Level1, T.Reason_Level2, 
    T.Reason_Level3,T.Reason_Level4,T.Action_Level1, T.Action_Level2, T.Action_Level3, 
    T.Action_Level4, T.TEStatus_Id, T.TEFault_Id, T.Research_Status_Id, T.Research_Open_Date, 
    T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
    T.PU_Desc, T.Group_Id, T.Comment_Id  
     From #DowntimeTemp T Inner Join #ST E On T.TEStatus_Id=E.TEStatus_Id
   Delete From #DowntimeTemp
   INSERT INTO #DowntimeTemp
    SELECT TEDET_Id, PU_Id, Start_Time, End_Time, Reason_Level1, Reason_Level2, 
    Reason_Level3,Reason_Level4,Action_Level1, Action_Level2, Action_Level3, 
    Action_Level4, TEStatus_Id, TEFault_Id, Research_Status_Id, Research_Open_Date, 
    Research_Close_Date, Research_User_Id, Prod_Id, Crew_Desc, Shift_Desc,
    PU_Desc, Group_Id, Comment_Id   
     From #DowntimeST
   Drop Table #DowntimeST
   Drop Table #ST
  End
----------------------------------------------------------------
-- If passed ProductionUnits, filter them: parse @ProductionUnits dumping it
-- on PU table and inner join it with UDETemp
-----------------------------------------------------------------
 If (@ProductionUnits Is Not Null And Len(@ProductionUnits) > 0) 
  Begin
   CREATE Table #PU (
    PU_id Int Null
   )
   CREATE Table #DowntimePU (
    TEDET_Id Int NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Reason_Level1 Int NULL,
    Reason_Level2 Int NULL,
    Reason_Level3 Int NULL,
    Reason_Level4 Int NULL,
    Action_Level1 Int NULL,
    Action_Level2 Int NULL,
    Action_Level3 Int NULL,
    Action_Level4 Int NULL,
    TEStatus_Id Int NULL,
    TEFault_Id Int NULL,
    Research_Status_Id int NULL,
    Research_Open_Date DateTime NULL,
    Research_Close_Date DateTime NULL,
    Research_User_Id Int NULL,
    Prod_Id Int NULL,
    Crew_Desc nVarChar(10) NULL,
    Shift_Desc nVarChar(10) NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null
   )
   SELECT @EndPosition=0
   SELECT @EndPosition=CharIndex("\",@ProductionUnits)
   While (@EndPosition<>0)
    Begin
     SELECT @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
     INSERT INTO #PU Values (@PUId)
     SELECT @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
     SELECT @EndPosition=CharIndex("\",@ProductionUnits)
    End -- while loop
   INSERT INTO #DowntimePU 
    SELECT T.TEDET_Id, T.PU_Id, T.Start_Time, T.End_Time, T.Reason_Level1, T.Reason_Level2, 
     T.Reason_Level3,T.Reason_Level4,T.Action_Level1, T.Action_Level2, T.Action_Level3, 
     T.Action_Level4, T.TEStatus_Id, T.TEFault_Id, T.Research_Status_Id, T.Research_Open_Date, 
     T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
     T.PU_Desc, T.Group_Id, T.Comment_Id  
      From #DowntimeTemp T Inner Join #PU P On  T.PU_id = P.PU_Id
   Delete From #DowntimeTemp
   INSERT INTO #DowntimeTemp
    SELECT TEDET_Id, PU_Id, Start_Time, End_Time, Reason_Level1, Reason_Level2, 
    Reason_Level3,Reason_Level4,Action_Level1, Action_Level2, Action_Level3, 
    Action_Level4, TEStatus_Id, TEFault_Id, Research_Status_Id, Research_Open_Date, 
    Research_Close_Date, Research_User_Id, Prod_Id, Crew_Desc, Shift_Desc,
    PU_Desc, Group_Id, Comment_Id   
     From #DowntimePU 
   Drop Table #DowntimePU
   Drop Table #PU
  End
----------------------------------------------------------------------
-- If passed products filter them
---------------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0) 
  Begin
   Declare ProdCursor INSENSITIVE CURSOR
    For (SELECT TEDet_Id, Start_Time, PU_Id From #DowntimeTemp)
     For Read Only
   Open ProdCursor
 ProdLoop:
   Fetch Next From ProdCursor Into  @TEDetId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    SELECT @ProdId = NULL
    SELECT @ProdId = Prod_Id 
     From Production_Starts 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ProdId Is Not Null) 
      Update #DowntimeTemp Set Prod_Id = @ProdId Where TEDET_Id = @TEDetId
    Goto ProdLoop
   End
  Close ProdCursor
  Deallocate ProdCursor
  CREATE Table #Prod (
   Prod_id Int Null
  )
  CREATE Table #DowntimeProd (
   TEDET_Id Int NULL,
   PU_Id Int NULL,
   Start_Time DateTime NULL,
   End_Time DateTime NULL,
   Reason_Level1 Int NULL,
   Reason_Level2 Int NULL,
   Reason_Level3 Int NULL,
   Reason_Level4 Int NULL,
   Action_Level1 Int NULL,
   Action_Level2 Int NULL,
   Action_Level3 Int NULL,
   Action_Level4 Int NULL,
   TEStatus_Id Int NULL,
   TEFault_Id Int NULL,
   Research_Status_Id int NULL,
   Research_Open_Date DateTime NULL,
   Research_Close_Date DateTime NULL,
   Research_User_Id Int NULL,
   Prod_Id Int NULL,
   Crew_Desc nVarChar(10) NULL,
   Shift_Desc nVarChar(10) NULL,
   PU_Desc nVarChar(50) Null,
   Group_Id Int Null,
   Comment_Id Int Null
  )
  SELECT @EndPosition=CharIndex("\",@Products)
  While (@EndPosition<>0)
   Begin
    SELECT @ProdId = Convert(Int,Substring(@Products,1,(@EndPosition-1)))
    INSERT INTO #Prod Values (@ProdId)
    SELECT @Products =  Right(@Products, Len(@Products)- @EndPosition)
    SELECT @EndPosition=CharIndex("\",@Products)
   End -- while loop
  INSERT INTO #DowntimeProd 
   SELECT T.TEDET_Id, T.PU_Id, T.Start_Time, T.End_Time, T.Reason_Level1, T.Reason_Level2, 
     T.Reason_Level3,T.Reason_Level4,T.Action_Level1, T.Action_Level2, T.Action_Level3, 
     T.Action_Level4, T.TEStatus_Id, T.TEFault_Id, T.Research_Status_Id, T.Research_Open_Date, 
     T.Research_Close_Date, T.Research_User_Id, T.Prod_Id, T.Crew_Desc, T.Shift_Desc,
     T.PU_Desc, T.Group_Id, T.Comment_Id  
    From #DowntimeTemp T Inner Join #Prod P On  T.Prod_id = P.Prod_Id
  Delete From #DowntimeTemp
  INSERT INTO #DowntimeTemp
   SELECT TEDET_Id, PU_Id, Start_Time, End_Time, Reason_Level1, Reason_Level2, 
    Reason_Level3,Reason_Level4,Action_Level1, Action_Level2, Action_Level3, 
    Action_Level4, TEStatus_Id, TEFault_Id, Research_Status_Id, Research_Open_Date, 
    Research_Close_Date, Research_User_Id, Prod_Id, Crew_Desc, Shift_Desc,
    PU_Desc, Group_Id, Comment_Id    
     From #DowntimeProd 
  Drop Table #DowntimeProd
  Drop Table #Prod
 End
----------------------------------------------------------------------
-- If passed CrewDescParam filter it
---------------------------------------------------------------------
 If (@CrewDescParam Is Not Null And Len(@CrewDescParam) > 0) 
  Begin
   Declare CrewCursor INSENSITIVE CURSOR
    For (SELECT TEDet_Id, Start_Time, PU_Id From #DowntimeTemp)
     For Read Only
   Open CrewCursor
 CrewLoop:
   Fetch Next From CrewCursor Into  @TEDetId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    SELECT @CrewDesc = NULL
    SELECT @CrewDesc = Crew_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@CrewDesc Is Not Null) 
      Update #DowntimeTemp Set Crew_Desc = @CrewDesc Where TEDet_Id = @TEDetId
     Goto CrewLoop
   End
   Close CrewCursor
   Deallocate CrewCursor
   Delete From #DowntimeTemp 
    Where Crew_Desc <> @CrewDescParam Or Crew_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed ShiftDescParam filter it
---------------------------------------------------------------------
 If (@ShiftDescParam Is Not Null And Len(@ShiftDescParam) > 0) 
  Begin
   Declare ShiftCursor INSENSITIVE CURSOR
    For (SELECT TEDet_Id, Start_Time, PU_Id From #DowntimeTemp)
     For Read Only
   Open ShiftCursor
 ShiftLoop:
   Fetch Next From ShiftCursor Into  @TEDetId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    SELECT @ShiftDesc = NULL
    SELECT @ShiftDesc = Shift_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ShiftDesc Is Not Null) 
      Update #DowntimeTemp Set Shift_Desc = @ShiftDesc Where TEDet_Id = @TEDetId
     Goto ShiftLoop
   End
   Close ShiftCursor
   Deallocate ShiftCursor
   Delete From #DowntimeTemp 
    Where Shift_Desc <> @ShiftDescParam Or Shift_Desc Is Null
  End
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 INSERT INTO @T(TimeColumns) Values ('Start Time')
 	 INSERT INTO @T(TimeColumns) Values ('End Time')
 	 INSERT INTO @T(TimeColumns) Values ('Research Open Date')
 	 INSERT INTO @T(TimeColumns) Values ('Research Close Date')
 	 INSERT INTO @CHT(HeaderTag,Idx) Values (16304,1) -- Unit
 	 INSERT INTO @CHT(HeaderTag,Idx) Values (16342,2) -- Start Time
 	 INSERT INTO @CHT(HeaderTag,Idx) Values (16333,3) -- End Time
 	 INSERT INTO @CHT(HeaderTag,Idx) Values (16106,4) --Description
 	 SELECT TimeColumns From @T
 	 SELECT HeaderTag From @CHT Order by Idx
 	 SELECT 	 [Unit] = T.PU_Desc, 
 	  	  	 [Start Time] = T.Start_Time, 
 	  	  	 [End Time] = T.End_Time,
 	  	  	 [Description] = 	 'Downtime' + Case When T.End_Time is NOT NULL Then ' ' + Replace(Convert(nVarChar(10),Convert(Decimal(6,1),Datediff(s, T.Start_Time , T.End_Time)/Convert(real, 60))), '.', @DecimalSep) + ' minutes' Else '' End 
 	  	  	  	 + ' at ' + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
 	  	  	  	 Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
 	  	  	  	 Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
 	  	  	  	 Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End,
 	  	  	 [Reason 1] = T.Reason_Level1, 
 	  	  	 [Reason 2] = T.Reason_Level2, 
 	  	  	 [Reason 3] = T.Reason_Level3,
 	  	  	 [Reason 4] = T.Reason_Level4,
 	  	  	 [Action 1] = T.Action_Level1,
 	  	  	 [Action 2] = T.Action_Level2,
 	  	  	 [Action 3] = T.Action_Level3,
 	  	  	 [Action 4] = T.Action_Level4,
 	  	  	 [Status] = T.TEStatus_Id,
 	  	  	 [Fault Id] = T.TEFault_Id, 
 	  	  	 [Research Status Id] = T.Research_Status_Id, 
 	  	  	 [Research Open Date] = T.Research_Open_Date, 
 	  	  	 [Research Close Date] = T.Research_Close_Date,
 	  	  	 [Research User Id] = T.Research_User_Id,
 	  	  	 [Product Id] = T.Prod_Id, 
 	  	  	 [Crew Desc] = T.Crew_Desc,
 	  	  	 [Shift Desc] = T.Shift_Desc,
 	  	  	 [Group Id] = T.Group_Id, 
 	  	  	 [Comment Id] = T.Comment_Id,
 	  	  	 [Downtime Detail Id] = T.TEDET_Id,
 	  	  	 [Unit Id] = T.PU_Id
 	 From #DowntimeTemp T 
 	 Join Prod_Units P on P.PU_Id = T.PU_Id
 	 Left Outer Join Event_Reasons RE  On T.Reason_Level1 = RE.Event_Reason_Id
 	 Left Outer Join Event_Reasons RE2 On T.Reason_Level2 = RE2.Event_Reason_Id
 	 Left Outer Join Event_Reasons RE3 On T.Reason_Level3 = RE3.Event_Reason_Id
 	 Left Outer Join Event_Reasons RE4 On T.Reason_Level4 = RE4.Event_Reason_Id
 	 Order By T.Start_Time desc
END
ELSE
BEGIN
 SELECT T.PU_Desc as 'Unit Desc', T.Start_Time as 'Start Time', T.End_Time as 'End Time',
  'Downtime' + Case When T.End_Time is NOT NULL Then ' ' + Replace(Convert(nVarChar(10),Convert(Decimal(6,1),Datediff(s, T.Start_Time , T.End_Time)/Convert(real, 60))), '.', @DecimalSep) + ' minutes' Else '' End 
          + ' at ' + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
          Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
          Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
          Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End as 'SOE Desc',
  T.Reason_Level1 as 'Reason 1', T.Reason_Level2 as 'Reason 2', T.Reason_Level3 as 'Reason 3',T.Reason_Level4 as 'Reason 4',
  T.Action_Level1 as 'Action 1', T.Action_Level2 as 'Action 2', T.Action_Level3 as 'Action 3', T.Action_Level4 as 'Action 4',
  T.TEStatus_Id as 'Status', T.TEFault_Id as 'Fault Id', T.Research_Status_Id as 'Research Status Id', T.Research_Open_Date as 'Research Open Date', 
  T.Research_Close_Date as 'Research Close Date', T.Research_User_Id as 'Research User Id', T.Prod_Id as 'Product Id', 
  T.Crew_Desc as 'Crew Desc', T.Shift_Desc as 'Shift Desc', T.Group_Id as 'Group Id', 
  T.Comment_Id as 'Comment Id', T.TEDET_Id as 'Downtime Detail Id', T.PU_Id as 'Unit Id'
   From #DowntimeTemp T 
    Join Prod_Units P on P.PU_Id = T.PU_Id
    Left Outer Join Event_Reasons RE  On T.Reason_Level1 = RE.Event_Reason_Id
    Left Outer Join Event_Reasons RE2 On T.Reason_Level2 = RE2.Event_Reason_Id
    Left Outer Join Event_Reasons RE3 On T.Reason_Level3 = RE3.Event_Reason_Id
    Left Outer Join Event_Reasons RE4 On T.Reason_Level4 = RE4.Event_Reason_Id
    Order By T.Start_Time desc
END
Drop Table #DowntimeTemp

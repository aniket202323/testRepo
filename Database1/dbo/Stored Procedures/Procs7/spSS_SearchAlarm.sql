Create Procedure dbo.spSS_SearchAlarm
 @ProductionUnits nVarChar(1024) = NULL,
 @Variables nVarChar(1024) = NULL,
 @StartDate1 DateTime = NULL,
 @StartDate2 DateTime = NULL,
 @OpenStatus int = NULL,
 @AlarmDescription nVarChar(50) = NULL,
 @Priority Int = NULL, 
 @AckStatus Int = NULL, 
 @ResearchStatusOpen Int = NULL, 
 @AckUserId int = NULL,
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
 @StartDate3 DateTime = NULL,
 @EndDate1 DateTime = NULL,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @AlarmId int, 
         @VarId int,
         @StartTime DateTime, 
         @PUId int,
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int,
         @CrewDesc nVarChar(10),
         @ShiftDesc nVarChar(10),
         @LocalPriority int
-- Insert Into DebugSearchAlarm Values (getDate(), @StartDate1, @StartDate2)
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select AL.Alarm_Id, AL.Alarm_Desc, AL.ATD_Id, AL.Alarm_Type_Id, AL.Key_Id, ' + 
                       'AL.Start_Time, AL.End_Time, AL.Source_PU_Id, Null As Prod_Id , AD.Var_id, ' +
                       'Null as Crew_Desc, Null as Shift_Desc, AL.Cause1, AL.Cause2, AL.Cause3, ' +
                       'AL.Cause4, AL.Action1, AL.Action2, AL.Action3, AL.Action4, ' +
                       'PU.PU_Desc, PU.Group_Id, AL.Cause_Comment_Id, AT.AP_id, V.Group_Id, ' +
                       'Coalesce(AT.ESignature_Level,0) ' +
                       'From Alarms AL ' +
                       'Inner Join Prod_Units PU On AL.Source_PU_Id = PU.PU_Id ' + 
                       'Inner Join Alarm_Template_Var_Data AD On AL.ATD_Id = AD.ATD_Id ' +
                       'Inner Join Alarm_Templates AT On AD.AT_Id = AT.At_Id ' +
                       'Left Outer Join Variables V On AD.Var_Id = V.Var_Id ' +
                       'Left Outer Join Comments CO On AL.Cause_Comment_Id = CO.Comment_Id ' +
                       'Left Outer Join Comments CO2 On AL.Action_Comment_Id = CO2.Comment_Id '                    
--------------------------------------------------------------------
-- Bwtween Start Dates
--------------------------------------------------------------------
 If (@StartDate1 Is Not Null And @StartDate1>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " AL.Start_Time Between '" + Convert(nVarChar(30), @StartDate1) + "' And '" +
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
--------------------------------------------------------------------
-- Start/End Dates
--------------------------------------------------------------------
 If (@StartDate3 Is Not Null And @StartDate3>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " AL.Start_Time >= '" + Convert(nVarChar(30), @StartDate3) + "' " +
                      "AND  AL.Start_Time <= '" + Convert(nVarChar(30), @EndDate1) + "' " +
                      "AND (AL.End_Time Is Null Or AL.End_Time <= '" +
                      Convert(nVarChar(30), @EndDate1) + "')"
--   Select @SQLCond0 = " AL.Start_Time >= '" + Convert(nVarChar(30), @StartDate3) + "' " +
--                      "AND AL.End_Time <= '" + Convert(nVarChar(30), @EndDate1) + "' "
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
-- Open Status
-----------------------------------------------------------------------
 If (@OpenStatus=1 Or @OpenStatus=2) 
  Begin
   If (@OpenStatus = 1) -- only opened alarms
    Select @SQLCond0 = 'AL.End_Time Is NULL'
   Else -- only closed alarms
    Select @SQLCond0 = 'AL.End_Time Is Not NULL'
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
-- Alarm Description
-----------------------------------------------------------------------
 If (@AlarmDescription Is Not Null And Len(@AlarmDescription)>0)
  Begin
   Select @SQLCond0 = "AL.Alarm_Desc Like '%" + @AlarmDescription + "%'"
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
--  ACK status
------------------------------------------------------
 Select @SQLCond0 = NULL
 Select @SQLCond0 = 
 Case @AckStatus
  When 1 Then 'AL.Ack=1'
  When 2 Then 'AL.Ack=0'
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
------------------------------------------------------
--  Research status Open
------------------------------------------------------
 Select @SQLCond0 = NULL
 Select @SQLCond0 = 
 Case @ResearchStatusOpen
  When 1 Then 'AL.Research_Open_Date Is Not Null And AL.Research_CLose_Date Is Null'
  When 2 Then 'AL.Research_Open_Date Is Not Null And AL.Research_CLose_Date Is Not Null'
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
---------------------------------------------------------------------
-- Ack User
--------------------------------------------------------------------- 
 If (@AckUserID Is Not Null) And (@AckUserID <>0)
  Begin
   Select @SQLCond0 =  ' AL.Ack_By = ' + Convert(nVarChar(5), @AckUserId)
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
   Select @SQLCond0 = 'AL.Cause4=' + Convert(nVarChar(05),@Cause4 )
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
   Select @SQLCond0 = 'AL.Cause3=' + Convert(nVarChar(05),@Cause3 )
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
   Select @SQLCond0 = 'AL.Cause2=' + Convert(nVarChar(05),@Cause2 )
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
   Select @SQLCond0 = 'AL.Cause1=' + Convert(nVarChar(05),@Cause1 )
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
   Select @SQLCond0 = 'AL.Action4=' + Convert(nVarChar(05),@Action4 )
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
   Select @SQLCond0 = 'AL.Action3=' + Convert(nVarChar(05),@Action3 )
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
   Select @SQLCond0 = 'AL.Action2=' + Convert(nVarChar(05),@Action2 )
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
   Select @SQLCond0 = 'AL.Action1=' + Convert(nVarChar(05),@Action1 )
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
 Create Table #AlarmTemp (
  Alarm_Id int NULL,
  Alarm_Desc nVarChar(1000) NULL,
  ATD_Id int NULL,
  Alarm_Type_Id int NULL,
  Key_Id  int NULL,
  Start_Time DateTime NULL,
  End_Time DateTime NULL,
  Source_PU_Id int NULL,
  Prod_Id int NULL,
  Var_Id int NULL,
  Crew_Desc nVarChar(10) Null,
  Shift_Desc nVarChar(10) Null,
  Cause1 int NULL,
  Cause2 int NULL,
  Cause3 int NULL,
  Cause4 int NULL,
  Action1 int NULL,
  Action2 int NULL,
  Action3 int NULL,
  Action4 int NULL,
  PU_Desc nVarChar(50) Null,
  Group_Id Int Null,
  Comment_Id Int Null,
  AP_id Int Null,
  Var_Group_Id Int Null,
  ESignature_Level Int Null
 )
 Select @SQLCommand = 'Insert Into #AlarmTemp ' + @SQLCommand 
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
   Create Table #AlarmPU (
    Alarm_Id int NULL,
    Alarm_Desc nVarChar(1000) NULL,
    ATD_Id int NULL,
    Alarm_Type_Id int NULL,
    Key_Id  int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Source_PU_Id int NULL,
    Prod_Id int NULL,
    Var_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Cause1 int NULL,
    Cause2 int NULL,
    Cause3 int NULL,
    Cause4 int NULL,
    Action1 int NULL,
    Action2 int NULL,
    Action3 int NULL,
    Action4 int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    AP_id Int Null,
    Var_Group_Id Int Null,
    ESignature_Level Int Null
   )
   Select @EndPosition=CharIndex("\",@ProductionUnits)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
     Insert Into #PU Values (@PUId)
     Select @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
     Select @EndPosition=CharIndex("\",@ProductionUnits)
    End -- while loop
   Insert Into #AlarmPU
    Select T.Alarm_Id, T.Alarm_Desc, T.ATD_Id, T.Alarm_Type_Id, T.Key_Id, T.Start_Time,
          T.End_Time, T.Source_PU_Id, T.Prod_Id, T.Var_Id, T.Crew_Desc, T.Shift_Desc,
          T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, T.Action2, T.Action3, T.Action4,
          T.PU_Desc, T.Group_Id, T.Comment_Id, T.AP_Id, T.Var_Group_Id, T.ESignature_Level
     From #AlarmTemp T Inner Join #PU P On  T.Source_PU_Id = P.PU_Id
   Delete From #AlarmTemp
   Insert Into #AlarmTemp
    Select * From #AlarmPU 
   Drop Table #AlarmPU
   Drop Table #PU
  End
----------------------------------------------------------------
-- If passed variables, filter them: parse @variables dumping it
-- on Var table and inner join it with AlarmTemp
-----------------------------------------------------------------
 If (@Variables Is Not Null And Len(@Variables) > 0) 
  Begin
   Create Table #Var (
    Var_id Int Null
   )
   Create Table #AlarmVar (
    Alarm_Id int NULL,
    Alarm_Desc nVarChar(1000) NULL,
    ATD_Id int NULL,
    Alarm_Type_Id int NULL,
    Key_Id  int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Source_PU_Id int NULL,
    Prod_Id int NULL,
    Var_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Cause1 int NULL,
    Cause2 int NULL,
    Cause3 int NULL,
    Cause4 int NULL,
    Action1 int NULL,
    Action2 int NULL,
    Action3 int NULL,
    Action4 int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    AP_id Int Null,
    Var_Group_Id Int Null,
    ESignature_Level Int Null
   )
   Select @EndPosition=CharIndex("\",@Variables)
   While (@EndPosition<>0)
    Begin
     Select @VarId = Convert(Int,Substring(@Variables,1,(@EndPosition-1)))
     Insert Into #Var Values (@VarId)
     Select @Variables =  Right(@Variables, Len(@Variables)- @EndPosition)
     Select @EndPosition=CharIndex("\",@Variables)
    End -- while loop
   Insert Into #AlarmVar 
   Select T.Alarm_Id, T.Alarm_Desc, T.ATD_Id, T.Alarm_Type_Id, T.Key_Id, T.Start_Time,
          T.End_Time, T.Source_PU_Id, T.Prod_Id, T.Var_Id, T.Crew_Desc, T.Shift_Desc,
          T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, T.Action2, T.Action3, T.Action4,
          T.PU_Desc, T.Group_Id, T.Comment_Id, T.AP_Id, T.Var_Group_Id, T.ESignature_Level
    From #AlarmTemp T Inner Join #Var V On  T.Var_id = V.Var_Id
   Delete From #AlarmTemp
   Insert Into #AlarmTemp
    Select * From #AlarmVar 
   Drop Table #AlarmVar
   Drop Table #Var
  End
----------------------------------------------------------------------
-- If passed products filter them
---------------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0) 
  Begin
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select Alarm_Id, Start_Time, Source_PU_Id From #AlarmTemp)
     For Read Only
   Open ProdCursor
 ProdLoop:
   Fetch Next From ProdCursor Into  @AlarmId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ProdId = NULL
    Select @ProdId = Prod_Id 
     From Production_Starts 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ProdId Is Not Null) 
      Update #AlarmTemp Set Prod_Id = @ProdId Where Alarm_Id = @AlarmId
    Goto ProdLoop
   End
  Close ProdCursor
  Deallocate ProdCursor
  Create Table #Prod (
   Prod_id Int Null
  )
  Create Table #AlarmProd (
   Alarm_Id int NULL,
   Alarm_Desc nVarChar(1000) NULL,
   ATD_Id int NULL,
   Alarm_Type_Id int NULL,
   Key_Id  int NULL,
   Start_Time DateTime NULL,
   End_Time DateTime NULL,
   Source_PU_Id int NULL,
   Prod_Id int NULL,
   Var_Id int NULL,
   Crew_Desc nVarChar(10) Null,
   Shift_Desc nVarChar(10) Null,
   Cause1 int NULL,
   Cause2 int NULL,
   Cause3 int NULL,
   Cause4 int NULL,
   Action1 int NULL,
   Action2 int NULL,
   Action3 int NULL,
   Action4 int NULL,
   PU_Desc nVarChar(50) Null,
   Group_Id Int Null,
   Comment_Id Int Null,
   AP_id Int Null,
   Var_Group_Id Int Null,
   ESignature_Level Int Null
  )
  Select @EndPosition=CharIndex("\",@Products)
  While (@EndPosition<>0)
   Begin
    Select @ProdId = Convert(Int,Substring(@Products,1,(@EndPosition-1)))
    Insert Into #Prod Values (@ProdId)
    Select @Products =  Right(@Products, Len(@Products)- @EndPosition)
    Select @EndPosition=CharIndex("\",@Products)
   End -- while loop
   Insert Into #AlarmProd 
  Select T.Alarm_Id, T.Alarm_Desc, T.ATD_Id, T.Alarm_Type_Id, T.Key_Id, T.Start_Time,
         T.End_Time, T.Source_PU_Id, T.Prod_Id, T.Var_Id, T.Crew_Desc, T.Shift_Desc,
         T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, T.Action2, T.Action3, T.Action4,
         T.PU_Desc, T.Group_Id, T.Comment_Id, T.AP_Id, T.Var_Group_Id, T.ESignature_Level
   From #AlarmTemp T Inner Join #Prod P On  T.Prod_id = P.Prod_Id
   Delete From #AlarmTemp
  Insert Into #AlarmTemp
   Select * From #AlarmProd 
  Drop Table #AlarmProd
  Drop Table #Prod
 End
----------------------------------------------------------------------
-- If passed CrewDescParam filter it
---------------------------------------------------------------------
 If (@CrewDescParam Is Not Null And Len(@CrewDescParam) > 0) 
  Begin
   Declare CrewCursor INSENSITIVE CURSOR
    For (Select Alarm_Id, Start_Time, Source_PU_Id From #AlarmTemp)
     For Read Only
   Open CrewCursor
 CrewLoop:
   Fetch Next From CrewCursor Into  @AlarmId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @CrewDesc = NULL
    Select @CrewDesc = Crew_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@CrewDesc Is Not Null) 
      Update #AlarmTemp Set Crew_Desc = @CrewDesc Where Alarm_Id = @AlarmId
     Goto CrewLoop
   End
   Close CrewCursor
   Deallocate CrewCursor
   Delete From #AlarmTemp 
    Where Crew_Desc <> @CrewDescParam Or Crew_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed ShiftDescParam filter it
---------------------------------------------------------------------
 If (@ShiftDescParam Is Not Null And Len(@ShiftDescParam) > 0) 
  Begin
   Declare ShiftCursor INSENSITIVE CURSOR
    For (Select Alarm_Id, Start_Time, Source_PU_Id From #AlarmTemp)
     For Read Only
   Open ShiftCursor
 ShiftLoop:
   Fetch Next From ShiftCursor Into  @AlarmId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ShiftDesc = NULL
    Select @ShiftDesc = Shift_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ShiftDesc Is Not Null) 
      Update #AlarmTemp Set Shift_Desc = @ShiftDesc Where Alarm_Id = @AlarmId
     Goto ShiftLoop
   End
   Close ShiftCursor
   Deallocate ShiftCursor
   Delete From #AlarmTemp 
    Where Shift_Desc <> @ShiftDescParam Or Shift_Desc Is Null
  End
--Get updated Priority
 	 Declare PriorityCursor INSENSITIVE CURSOR For   
 	   Select Alarm_Id
 	   From #AlarmTemp
 	   For Read Only
 	   Open PriorityCursor  
 	 MyPriorityLoop1:
 	   Fetch Next From PriorityCursor Into @AlarmID
 	 
 	   If (@@Fetch_Status = 0)
 	     Begin
 	       exec spServer_AMgrGetAlarmPriority @AlarmID, @LocalPriority output
 	       Update #AlarmTemp Set AP_Id = @LocalPriority Where Alarm_Id = @AlarmID  
 	       Goto MyPriorityLoop1
 	     End
 	 Close PriorityCursor
 	 Deallocate PriorityCursor
------------------------------------------------------
--  Filter Alarm Priority 
------------------------------------------------------
 Select @SQLCond0 = NULL
 Select @SQLCond0 = 
 Case @Priority
  When 1 Then 'AP_Id=1 Or AP_Id=2'
  When 2 Then 'AP_Id=1 Or AP_Id=3'
  When 3 Then 'AP_Id=1'
  When 4 Then 'AP_Id=2 Or AP_Id=3'
  When 5 Then 'AP_Id=2'
  When 6 Then 'AP_Id=3'
 End
-- insert into local_debug (time, msg) values (getdate(), Convert(nVarChar(10), @priority))
 If (@Priority Is Not Null and @Priority <> 7)
  Begin
    Select @SQLCommand = 'Delete from #AlarmTemp Where ' + @SQLCond0
    Exec (@SQLCommand)
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
 	 Insert into @CHT(HeaderTag,Idx) Values (16380,1)
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,2) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16333,3) -- End Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16304,4) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16039,5) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16040,6) -- 
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 /* Only 1st 5 visible*/ 
 	  Select [Alarm] = T.Alarm_Desc, 	  	  	 --0
 	  	  	 [Start Time] = T.Start_Time, 	 --1
 	  	  	 [End Time] = T.End_Time, 	  	 --2
 	  	  	 [Unit] = T.PU_Desc, 	  	  	  	 --3
 	  	  	 [Crew] = T.Crew_Desc, 	  	  	 --4
 	  	  	 [Shift] = T.Shift_Desc, 	  	  	 --5
 	  	  	 [Cause1] = T.Cause1, 	  	  	 --6
 	  	  	 [Cause2] = T.Cause2, 	  	  	 --7
 	  	  	 [Cause3] = T.Cause3, 	  	  	 --8
 	  	  	 [Cause4] = T.Cause4, 	  	  	 --9
 	  	  	 [Action1] = T.Action1, 	  	  	 --10
 	  	  	 [Action2] = T.Action2, 	  	  	 --11
 	  	  	 [Action3] = T.Action3, 	  	  	 --12
 	  	  	 [Action4] = T.Action4,  	  	  	 --13
 	  	  	 [Group Id] = T.Group_Id,  	  	 --14
 	  	  	 [Comment Id] = T.Comment_Id, 	 --15
 	  	  	 [AP Id] = T.AP_Id,  	  	  	  	 --16
 	  	  	 [Variable Group Id] = T.Var_Group_Id, 	 --17
 	  	  	 [Alarm Id] = T.Alarm_Id,  	  	 --18
 	  	  	 [ATD Id] = T.ATD_Id,  	  	  	 --19
 	  	  	 [Alarm Type Id] = T.Alarm_Type_Id, 	 --20
 	  	  	 [Key Id] = T.Key_Id,  	  	  	 --21
 	  	  	 [Source Unit Id] = T.Source_PU_Id, 	 --22
 	  	  	 [Product Id] = T.Prod_Id,  	  	 --23
 	  	  	 [Variable Id] = T.Var_Id, 	  	 --24
 	  	  	 [ESignature Level] = T.ESignature_Level 	 --25
 	   From #AlarmTemp T 
 	   Order By T.Start_Time desc
END
ELSE
BEGIN
 Select  T.Alarm_Desc as 'Alarm Desc', T.Start_Time as 'Start Time', T.End_Time as 'End Time', T.PU_Desc as 'Unit Desc',  
         T.Crew_Desc as 'Crew Desc', T.Shift_Desc as 'Shift Desc', T.Cause1, T.Cause2, T.Cause3, T.Cause4, T.Action1, 
         T.Action2, T.Action3, T.Action4, T.Group_Id as 'Group Id', T.Comment_Id as 'Comment Id', T.AP_Id as 'AP Id', 
         T.Var_Group_Id as 'Variable Group Id', T.Alarm_Id as 'Alarm Id', T.ATD_Id as 'ATD Id', 
         T.Alarm_Type_Id as 'Alarm Type Id', T.Key_Id as 'Key Id', T.Source_PU_Id as 'Source Unit Id', 
         T.Prod_Id as 'Product Id', T.Var_Id as 'Variable Id', T.ESignature_Level as 'ESignature Level'
  From #AlarmTemp T 
   Order By T.Start_Time desc
END
Drop Table #AlarmTemp

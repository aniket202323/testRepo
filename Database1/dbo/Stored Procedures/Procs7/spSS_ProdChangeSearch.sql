Create Procedure dbo.spSS_ProdChangeSearch
 @ProductionUnits nVarChar(1024) = NULL,
 @StartDate1 DateTime = NULL,
 @StartDate2 DateTime = NULL,
 @EndDate1 DateTime = NULL,
 @EndDate2 DateTime = NULL,
 @Products nVarChar(1024) = NULL, 
 @Comment nVarChar(50) = NULL, 
 @Statistics nVarChar(1024) = NULL,
 @CrewDescParam nVarChar(10) = NULL,
 @ShiftDescParam nVarChar(10) = NULL,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @StartId int, 
         @StartTime DateTime, 
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
 Select @SQLCommand = 'Select S.Start_Id, S.PU_Id, S.Start_Time, S.End_Time, S.Comment_Id, ' +
                      'S.Event_SubType_Id,S.Prod_Id, PU.PU_Desc, P.Prod_Code, P.Prod_Desc, ' +
                      'PU.Group_Id, Null as Crew_Desc, Null as Shift_Desc ' +
                      'From Production_Starts S ' +
                      'Inner Join Prod_Units PU On S.PU_Id = PU.PU_Id ' +
                      'Inner Join Products P On S.Prod_Id = P.Prod_Id ' +
                      'Left Outer Join Comments CO On S.Comment_Id = CO.Comment_Id ' 
--------------------------------------------------------------------
-- between Start Date Dates
--------------------------------------------------------------------
 If (@StartDate1 Is Not Null And @StartDate1>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " S.Start_Time Between '" + Convert(nVarChar(30), @StartDate1) + "' And '" +
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
-- between End Date Dates
--------------------------------------------------------------------
 If (@EndDate1 Is Not Null And @EndDate1>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " S.End_Time Between '" + Convert(nVarChar(30), @EndDate1) + "' And '" +
                      Convert(nVarChar(30), @EndDate2) + "'"   
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
--  Comment Description
-----------------------------------------------------------------------
 If (@Comment Is Not Null And Len(@Comment)>0)
  Begin
   Select @SQLCond0 = "CO.Comment Like '%" + @Comment + "%'"
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
----------------------------------------------------------------
--  Output partial result to a temp table
-----------------------------------------------------------------
 Create Table #ProdChangeTemp (
  Start_Id Int NULL,
  PU_Id  Int NULL,
  Start_Time DateTime NULL,
  End_Time DateTime NULL,
  Comment_Id  Int NULL,
  Event_SubType_Id Int NULL,
  Prod_Id Int NULL,
  PU_Desc nVarChar(50) NULL,
  Prod_Code nVarChar(20) NULL,
  Prod_Desc nVarChar(50) NULL,
  Group_Id int NULL,
  Crew_Desc nVarChar(10) NULL,
  Shift_Desc nVarChar(10) NULL 
  )
 Select @SQLCommand = 'Insert Into #ProdChangeTemp ' + @SQLCommand 
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
   Create Table #ProdChangePU (
    Start_Id Int NULL,
    PU_Id  Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Comment_Id  Int NULL,
    Event_SubType_Id Int NULL,
    Prod_Id Int NULL,
    PU_Desc nVarChar(50) NULL,
    Prod_Code nVarChar(20) NULL,
    Prod_Desc nVarChar(50) NULL,
    Group_Id int NULL,
    Crew_Desc nVarChar(10) NULL,
    Shift_Desc nVarChar(10) NULL 
   )
   Select @EndPosition=CharIndex("\",@ProductionUnits)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
     Insert Into #PU Values (@PUId)
     Select @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
     Select @EndPosition=CharIndex("\",@ProductionUnits)
    End -- while loop
   Insert Into #ProdChangePU 
   Select T.Start_Id, T.PU_Id, T.Start_Time, T.End_Time, T.Comment_Id, T.Event_SubType_Id, 
    T.Prod_Id, T.PU_Desc, T.Prod_Code, T.Prod_Desc,  T.Group_Id, T.Crew_Desc, T.Shift_Desc
     From #ProdChangeTemp T Inner Join #PU P On  T.PU_id = P.PU_Id
   Delete From #ProdChangeTemp
   Insert Into #ProdChangeTemp
    Select * From #ProdChangePU 
   Drop Table #ProdChangePU
   Drop Table #PU
  End
----------------------------------------------------------------------
-- If passed products filter them
---------------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0) 
  Begin
   Create Table #Prod (
   Prod_id Int Null
  )
   Create Table #ProdChangeProd (
    Start_Id Int NULL,
    PU_Id  Int NULL,
    Start_Time DateTime NULL,
    End_Time DateTime NULL,
    Comment_Id  Int NULL,
    Event_SubType_Id Int NULL,
    Prod_Id Int NULL,
    PU_Desc nVarChar(50) NULL,
    Prod_Code nVarChar(20) NULL,
    Prod_Desc nVarChar(50) NULL,
    Group_Id int NULL,
    Crew_Desc nVarChar(10) NULL,
    Shift_Desc nVarChar(10) NULL 
   )
  Select @EndPosition=CharIndex("\",@Products)
  While (@EndPosition<>0)
   Begin
    Select @ProdId = Convert(Int,Substring(@Products,1,(@EndPosition-1)))
    Insert Into #Prod Values (@ProdId)
    Select @Products =  Right(@Products, Len(@Products)- @EndPosition)
    Select @EndPosition=CharIndex("\",@Products)
   End -- while loop
  Insert Into #ProdChangeProd
   Select T.Start_Id, T.PU_Id, T.Start_Time, T.End_Time, T.Comment_Id, T.Event_SubType_Id, 
    T.Prod_Id, T.PU_Desc, T.Prod_Code, T.Prod_Desc, T.Group_Id, T.Crew_Desc, T.Shift_Desc
     From #ProdChangeTemp T Inner Join #Prod P On  T.Prod_id = P.Prod_Id 
  Delete From #ProdChangeTemp
  Insert Into #ProdChangeTemp
   Select * From #ProdChangeProd
  Drop Table #ProdChangeProd
  Drop Table #Prod
 End
----------------------------------------------------------------------
-- If passed CrewDescParam filter it
---------------------------------------------------------------------
 If (@CrewDescParam Is Not Null And Len(@CrewDescParam) > 0) 
  Begin
   Declare CrewCursor INSENSITIVE CURSOR
    For (Select Start_Id, Start_Time, PU_Id From #ProdChangeTemp)
     For Read Only
   Open CrewCursor
 CrewLoop:
   Fetch Next From CrewCursor Into  @StartId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @CrewDesc = NULL
    Select @CrewDesc = Crew_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@CrewDesc Is Not Null) 
      Update #ProdChangeTemp Set Crew_Desc = @CrewDesc Where Start_Id = @StartId
     Goto CrewLoop
   End
   Close CrewCursor
   Deallocate CrewCursor
   Delete From #ProdChangeTemp 
    Where Crew_Desc <> @CrewDescParam Or Crew_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed ShiftDescParam filter it
---------------------------------------------------------------------
 If (@ShiftDescParam Is Not Null And Len(@ShiftDescParam) > 0) 
  Begin
   Declare ShiftCursor INSENSITIVE CURSOR
     For (Select Start_Id, Start_Time, PU_Id From #ProdChangeTemp)
     For Read Only
   Open ShiftCursor
 ShiftLoop:
   Fetch Next From ShiftCursor Into  @StartId, @StartTime, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ShiftDesc = NULL
    Select @ShiftDesc = Shift_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @StartTime >=Start_Time 
        And (@StartTime < End_Time Or End_Time Is Null)
     If (@ShiftDesc Is Not Null) 
      Update #ProdChangeTemp Set Shift_Desc = @ShiftDesc Where Start_Id = @StartId
     Goto ShiftLoop
   End
   Close ShiftCursor
   Deallocate ShiftCursor
   Delete From #ProdChangeTemp 
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
 	 Insert into @CHT(HeaderTag,Idx) Values (16320,4) -- Product Code
 	 Insert into @CHT(HeaderTag,Idx) Values (16164,5) -- Product
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Unit] = T.PU_Desc,
 	  	  	 [Start Time] = T.Start_Time, 
 	  	  	 [End Time] = T.End_Time, 
 	  	  	 [Product Code] = T.Prod_Code, 
 	  	  	 [Product] = T.Prod_Desc, 
 	  	  	 [Start Id] = T.Start_Id, 
 	  	  	 [Unit Id] = T.PU_Id, 
 	  	  	 [Duration] = DateDiff(minute,Start_Time, End_Time), 
 	  	  	 [Comment Id] = T.Comment_Id, 
 	  	  	 [Event Subtype Id] = T.Event_SubType_Id, 
 	  	  	 [Product Id] = T.Prod_Id, 
 	  	  	 [Group Id] = T.Group_Id, 
 	  	  	 [Crew Desc] = T.Crew_Desc, 
 	  	  	 [Shift Desc] = T.Shift_Desc, 
 	  	  	 [SOE Desc] = 'Product Change to ' + T.Prod_Code
 	 From  #ProdChangeTemp T 
 	 Order By T.Start_Time desc
END
ELSE
BEGIN
 	 Select T.PU_Desc as 'Unit Desc', T.Start_Time as 'Start Time', T.End_Time as 'End Time', T.Prod_Code as 'Product Code', 
 	  	 T.Prod_Desc as 'Product Desc', T.Start_Id as 'Start Id', T.PU_Id as 'Unit Id', DateDiff(mi,Start_Time, End_Time) as Duration, 
 	  	 T.Comment_Id as 'Comment Id', T.Event_SubType_Id as 'Event Subtype Id', T.Prod_Id as 'Product Id', T.Group_Id as 'Group Id', 
 	  	 T.Crew_Desc as 'Crew Desc', T.Shift_Desc as 'Shift Desc', 'Product Change to ' + T.Prod_Code as 'SOE Desc'
 	 From  #ProdChangeTemp T 
 	 Order By T.Start_Time desc
END
Drop Table #ProdChangeTemp

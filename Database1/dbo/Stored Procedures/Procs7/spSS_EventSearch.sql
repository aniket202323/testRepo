Create Procedure dbo.spSS_EventSearch
 @ProductionUnits nVarChar(1024) = NULL,
 @Statuses nVarChar(1024) = NULL,
 @EventSubTypeId Int = NULL,
 @StartDate1 DateTime = NULL,
 @StartDate2 DateTime = NULL,
 @EventNum nVarChar(50) = NULL,
 @Products nVarChar(1024) = NULL, 
 @SearchProductType Int = NULL,
 @Comment nVarChar(50) = NULL, 
 @Statistics nVarChar(1024) = NULL,
 @CrewDescParam nVarChar(10) = NULL,
 @ShiftDescParam nVarChar(10) = NULL,
 @Orders nVarChar(1024) = NULL,
 @Shipments nVarChar(1024) = NULL,
 @ParentsSteps int = NULL,
 @ChildrenSteps Int = NULL,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @EventId int, 
         @TimeStamp DateTime, 
         @PUId int,
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int,
         @CrewDesc nVarChar(10),
         @ShiftDesc nVarChar(10),
         @ParentId int,
         @Level int,
         @SourceEvent int,
         @CurrentKey int,
         @NewLevel int,
         @Prev_Timestamp DateTime
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
 Select @SQLCommand = 'Select E.Event_Id, E.Event_Num, E.PU_Id, E.Start_Time, E.TimeStamp, E.Applied_Product, ' +
                      'E.Source_Event, E.Event_Status, PS.ProdStatus_Desc, NULL, NULL, ' +
                      'Null as Prod_Id, Null as Crew_Desc, Null as Shift_Desc, ED.Order_id, ' +
                      'SI.Shipment_Id, ' +
                      'PU.PU_Desc, PU.Group_Id, E.Comment_Id, E.Event_Status, 0 as GenealogyLevel ' +
                      'From Events E ' +
                      'Inner Join Prod_Units PU On E.PU_Id = PU.PU_Id ' +  
                      'Left Outer Join Comments CO On E.Comment_Id = CO.Comment_Id ' +
                      'Left Outer Join Event_Details ED ON E.Event_Id = ED.Event_Id ' +
                      'Left Outer Join Shipment_Line_Items SI on ED.Shipment_Item_id = SI.Shipment_Item_Id ' +
                      'Left Outer Join Production_Status PS on E.Event_Status = PS.ProdStatus_Id '
--------------------------------------------------------------------
-- between completed Dates
--------------------------------------------------------------------
 If (@StartDate1 Is Not Null And @StartDate1>'01-Jan-1970')
  Begin
   Select @SQLCond0 = " E.TimeStamp Between '" + Convert(nVarChar(30), @StartDate1) + "' And '" +
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
-------------------------------------------------------------------
-- EventNum
-----------------------------------------------------------------------
 If (@EventNum Is Not Null And Len(@EventNum)>0)
  Begin
   Select @SQLCond0 = "E.Event_Num Like '%" + @EventNum + "%'"
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
 Create Table #EventTemp (
  Event_Id int NULL,
  Event_Num nVarChar(50) NULL,
  PU_Id Int NULL,
  Start_Time DateTime NULL,
  TimeStamp DateTime NULL,
  Applied_Product Int NULL,
  Source_Event int NULL,
  Event_Status Int NULL,
  Event_Status_Desc nVarChar(50) NULL,
  Event_SubType_Id Int NULL,
  Event_SubType_Desc nVarChar(50) NULL,
  Prod_Id int NULL,
  Crew_Desc nVarChar(10) Null,
  Shift_Desc nVarChar(10) Null,
  Order_id int NULL,
  Shipment_Id Int NULL,
  PU_Desc nVarChar(50) Null,
  Group_Id Int Null,
  Comment_Id Int Null,
  Status_Id Int Null,
  GenealogyLevel Int Null
 )
 Select @SQLCommand = 'Insert Into #EventTemp ' + @SQLCommand 
  If (@Statuses is NULL or LTrim(RTrim(@Statuses)) = '') and
     (@EventSubTypeId is NULL or @EventSubTypeId = 0) and
     (@StartDate1 is NULL or @StartDate1 = 'Dec 30 1899 12:00:00:000AM') and
     (@StartDate2 is NULL or @StartDate2 = 'Dec 30 1899 12:00:00:000AM') and
     (@EventNum is NULL or LTrim(RTrim(@EventNum)) = '') and
     (@Products is NULL or LTrim(RTrim(@Products)) = '') and
     (@SearchProductType is NULL or @SearchProductType > 0) and
     (@Comment is NULL or LTrim(RTrim(@Comment)) = '') and
     (@Statistics is NULL or LTrim(RTrim(@Statistics)) = '') and
     (@CrewDescParam is NULL or LTrim(RTrim(@CrewDescParam)) = '') and
     (@ShiftDescParam is NULL or LTrim(RTrim(@ShiftDescParam)) = '') and
     (@Orders is NULL or LTrim(RTrim(@Orders)) = '') and
     (@Shipments is NULL or LTrim(RTrim(@Shipments)) = '') and
     (@ParentsSteps is NULL or @Statuses = 0) and
     (@ChildrenSteps is NULL or @ChildrenSteps = 0)
       Select @SQLCommand = 'Set RowCount 100 ' + @SQLCommand --Maximum of 100 rows in result set
  Select @SQLCommand = @SQLCommand + ' Set RowCount 0'
  Exec (@SQLCommand)
  Set RowCount 0 --Turn off
----------------------------------------------------------------
-- If passed ProductionUnits, filter them: parse @ProductionUnits dumping it
-- on PU table and inner join it with UDETemp
-----------------------------------------------------------------
 If (@ProductionUnits Is Not Null And Len(@ProductionUnits) > 0) 
  Begin
   Create Table #PU (
    PU_id Int Null
   )
   Create Table #EventPU (
    Event_Id int NULL,
    Event_Num nVarChar(50) NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    TimeStamp DateTime NULL,
    Applied_Product Int NULL,
    Source_Event int NULL,
    Event_Status Int NULL,
    Event_Status_Desc nVarChar(50) NULL,
    Event_SubType_Id Int NULL,
    Event_SubType_Desc nVarChar(50) NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Order_id int NULL,
    Shipment_Id Int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    Status_Id Int Null,
    GenealogyLevel Int Null
   )
   Select @EndPosition=CharIndex("\",@ProductionUnits)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
     Insert Into #PU Values (@PUId)
     Select @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
     Select @EndPosition=CharIndex("\",@ProductionUnits)
    End -- while loop
    -------------------------------------------------------------------
    -- Event SubType
    -----------------------------------------------------------------------
     If (@EventSubTypeId Is Not Null And @EventSubTypeId<>0)
      Begin
       Insert Into #EventPU 
         Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
          T.Event_Status, T.Event_Status_Desc, EC.Event_SubType_Id, ES.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_id, T.Shipment_Id,
          T.PU_Desc, T.Group_Id, T.Comment_Id, T.Status_Id, T.GenealogyLevel  
           From #EventTemp T 
             Inner Join #PU P On T.PU_id = P.PU_Id
             Left Outer Join Event_Configuration EC on EC.ET_Id = 1 and EC.PU_Id = P.PU_Id
             Left Outer Join Event_Subtypes ES on ES.Event_SubType_Id = EC.Event_SubType_Id
             Where EC.Event_SubType_Id = @EventSubTypeId
      End  
     Else
      Begin
       Insert Into #EventPU 
         Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
          T.Event_Status, T.Event_Status_Desc, EC.Event_SubType_Id, ES.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_id, T.Shipment_Id,
          T.PU_Desc, T.Group_Id, T.Comment_Id, T.Status_Id, T.GenealogyLevel  
           From #EventTemp T 
             Inner Join #PU P On T.PU_id = P.PU_Id
             Left Outer Join Event_Configuration EC on EC.ET_Id = 1 and EC.PU_Id = P.PU_Id
             Left Outer Join Event_Subtypes ES on ES.Event_SubType_Id = EC.Event_SubType_Id
      End
   Delete From #EventTemp
   Insert Into #EventTemp
    Select * From #EventPU 
   Drop Table #EventPU
   Drop Table #PU
  End
----------------------------------------------------------------
-- If passed Statuses, filter them: parse @Statuses dumping it
-- on ST table and inner join it with EventTemp
-----------------------------------------------------------------
 If (@Statuses Is Not Null And Len(@Statuses) > 0) 
  Begin
   Create Table #ST (
    Event_Status Int Null
   )
   Create Table #EventST (
    Event_Id int NULL,
    Event_Num nVarChar(50) NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    TimeStamp DateTime NULL,
    Applied_Product Int NULL,
    Source_Event int NULL,
    Event_Status Int NULL,
    Event_Status_Desc nVarChar(50) NULL,
    Event_SubType_Id Int NULL,
    Event_SubType_Desc nVarChar(50) NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Order_id int NULL,
    Shipment_Id Int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    Status_Id Int Null,
    GenealogyLevel Int Null
   )
   Select @EndPosition=CharIndex("\",@Statuses)
   While (@EndPosition<>0)
    Begin
     Select @PUId = Convert(Int,Substring(@Statuses,1,(@EndPosition-1)))
     Insert Into #ST Values (@PUId)
     Select @Statuses =  Right(@Statuses, Len(@Statuses)- @EndPosition)
     Select @EndPosition=CharIndex("\",@Statuses)
    End -- while loop
   Insert Into #EventST 
   Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
    T.Event_Status, T.Event_Status_Desc, T.Event_SubType_Id, T.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_Id, T.Shipment_Id,
    T.PU_Desc, T.Group_Id, T.Comment_Id  , T.Status_Id, T.GenealogyLevel 
     From #EventTemp T Inner Join #ST P On  T.Event_Status = P.Event_Status   Delete From #EventTemp
   Insert Into #EventTemp
    Select * From #EventST 
   Drop Table #EventST
   Drop Table #ST
  End
----------------------------------------------------------------------
-- If passed products filter them
---------------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0 And
     @SearchProductType Is Not Null ANd @SearchProductType<>0) 
  Begin
-- for search for original product or both, I need to get the prodId
   If (@SearchProductType=1 Or @SearchProductType=3)
    Begin   
     Declare ProdCursor INSENSITIVE CURSOR
      For (Select Event_Id, TImeStamp, PU_Id From #EventTemp)
       For Read Only
     Open ProdCursor
 ProdLoop:
     Fetch Next From ProdCursor Into  @EventId, @TimeStamp, @PUId
     If (@@Fetch_Status = 0)
     Begin
      Select @ProdId = NULL
      Select @ProdId = Prod_Id 
       From Production_Starts 
        Where PU_Id = @PUId 
         And @TimeStamp >=Start_Time 
          And (@TimeStamp < End_Time Or End_Time Is Null)
       If (@ProdId Is Not Null) 
        Update #EventTemp Set Prod_Id = @ProdId Where Event_Id = @EventId
      Goto ProdLoop
     End
    Close ProdCursor
    Deallocate ProdCursor
  End   -- end of begin for searchproducttyp=1 or 3
  Create Table #Prod (
   Prod_id Int Null
  )
   Create Table #EventProd1 (
    Event_Id int NULL,
    Event_Num nVarChar(50) NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    TimeStamp DateTime NULL,
    Applied_Product Int NULL,
    Source_Event int NULL,
    Event_Status Int NULL,
    Event_Status_Desc nVarChar(50) NULL,
    Event_SubType_Id Int NULL,
    Event_SubType_Desc nVarChar(50) NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Order_id int NULL,
    Shipment_Id Int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    Status_Id Int Null,
    GenealogyLevel Int Null
   )
   Create Table #EventProd2 (
    Event_Id int NULL,
    Event_Num nVarChar(50) NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    TimeStamp DateTime NULL,
    Applied_Product Int NULL,
    Source_Event int NULL,
    Event_Status Int NULL,
    Event_Status_Desc nVarChar(50) NULL,
    Event_SubType_Id Int NULL,
    Event_SubType_Desc nVarChar(50) NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Order_id int NULL,
    Shipment_Id Int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    Status_Id Int Null,
    GenealogyLevel Int Null
   )
  Select @EndPosition=CharIndex("\",@Products)
  While (@EndPosition<>0)
   Begin
    Select @ProdId = Convert(Int,Substring(@Products,1,(@EndPosition-1)))
    Insert Into #Prod Values (@ProdId)
    Select @Products =  Right(@Products, Len(@Products)- @EndPosition)
    Select @EndPosition=CharIndex("\",@Products)
   End -- while loop
-- for search for original product or both, I get the events that match the passed products with their original product
  If (@SearchProductType=1 Or @SearchProductType=3)
   Insert Into #EventProd1
    Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
     T.Event_Status, T.Event_Status_Desc, T.Event_SubType_Id, T.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_Id, T.Shipment_Id,
     T.PU_Desc, T.Group_Id, T.Comment_Id, T.Status_Id, T.GenealogyLevel   
      From #EventTemp T Inner Join #Prod P On  T.Prod_Id = P.Prod_Id
-- for search for applied product or both, I get the events that match the passed products with their applied product
  If (@SearchProductType=2 Or @SearchProductType=3)
  Insert Into #EventProd2
   Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
    T.Event_Status, T.Event_Status_Desc, T.Event_SubType_Id, T.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_Id, T.Shipment_Id,
    T.PU_Desc, T.Group_Id, T.Comment_Id, T.Status_Id, T.GenealogyLevel   
     From #EventTemp T Inner Join #Prod P On  T.Applied_Product = P.Prod_Id
  Delete From #EventTemp
  Insert Into #EventTemp
   Select * From #EventProd1 
    Union
   Select * From #EventProd2
  Drop Table #EventProd1
  Drop Table #EventProd2
  Drop Table #Prod
 End
----------------------------------------------------------------------
-- If passed CrewDescParam filter it
---------------------------------------------------------------------
 If (@CrewDescParam Is Not Null And Len(@CrewDescParam) > 0) 
  Begin
   Declare CrewCursor INSENSITIVE CURSOR
    For (Select Event_Id, TimeStamp, PU_Id From #EventTemp)
     For Read Only
   Open CrewCursor
 CrewLoop:
   Fetch Next From CrewCursor Into  @EventId, @TimeStamp, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @CrewDesc = NULL
    Select @CrewDesc = Crew_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @TimeStamp >=Start_Time 
        And (@TimeStamp < End_Time Or End_Time Is Null)
     If (@CrewDesc Is Not Null) 
      Update #EventTemp Set Crew_Desc = @CrewDesc Where Event_Id = @EventId
     Goto CrewLoop
   End
   Close CrewCursor
   Deallocate CrewCursor
   Delete From #EventTemp 
    Where Crew_Desc <> @CrewDescParam Or Crew_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed ShiftDescParam filter it
---------------------------------------------------------------------
 If (@ShiftDescParam Is Not Null And Len(@ShiftDescParam) > 0) 
  Begin
   Declare ShiftCursor INSENSITIVE CURSOR
    For (Select Event_Id, TimeStamp, PU_Id From #EventTemp)
     For Read Only
   Open ShiftCursor
 ShiftLoop:
   Fetch Next From ShiftCursor Into  @EventId, @TimeStamp, @PUId
   If (@@Fetch_Status = 0)
   Begin
    Select @ShiftDesc = NULL
    Select @ShiftDesc = Shift_Desc 
     From Crew_Schedule 
      Where PU_Id = @PUId 
       And @TimeStamp >=Start_Time 
        And (@TimeStamp < End_Time Or End_Time Is Null)
     If (@ShiftDesc Is Not Null) 
      Update #EventTemp Set Shift_Desc = @ShiftDesc Where Event_Id = @EventId
     Goto ShiftLoop
   End
   Close ShiftCursor
   Deallocate ShiftCursor
   Delete From #EventTemp 
    Where Shift_Desc <> @ShiftDescParam Or Shift_Desc Is Null
  End
----------------------------------------------------------------------
-- If passed Orders filter them
---------------------------------------------------------------------
 If (@Orders Is Not Null And Len(@Orders) > 0) 
  Begin
   Create Table #Order (
   Order_id Int Null
  )
   Create Table #EventOrder (
    Event_Id int NULL,
    Event_Num nVarChar(50) NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    TimeStamp DateTime NULL,
    Applied_Product Int NULL,
    Source_Event int NULL,
    Event_Status Int NULL,
    Event_Status_Desc nVarChar(50) NULL,
    Event_SubType_Id Int NULL,
    Event_SubType_Desc nVarChar(50) NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Order_id int NULL,
    Shipment_Id Int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    Status_Id Int Null,
    GenealogyLevel Int Null
   )
  Select @EndPosition=CharIndex("\",@Orders)
  While (@EndPosition<>0)
   Begin
    Select @ProdId = Convert(Int,Substring(@Orders,1,(@EndPosition-1)))
    Insert Into #Order Values (@ProdId)
    Select @Orders =  Right(@Orders, Len(@Orders)- @EndPosition)
    Select @EndPosition=CharIndex("\",@Orders)
   End -- while loop
  Insert Into #EventOrder
    Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
     T.Event_Status, T.Event_Status_Desc, T.Event_SubType_Id, T.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_Id, T.Shipment_Id,
     T.PU_Desc, T.Group_Id, T.Comment_Id, T.Status_Id, T.GenealogyLevel   
      From #EventTemp T Inner Join #Order P On  T.Order_Id = P.Order_Id
  Delete From #EventTemp
  Insert Into #EventTemp
   Select * From #EventOrder
  Drop Table #EventOrder
  Drop Table #Order
 End
----------------------------------------------------------------------
-- If passed Shipments filter them
---------------------------------------------------------------------
 If (@Shipments Is Not Null And Len(@Shipments) > 0) 
  Begin
   Create Table #Shipment (
   Shipment_id Int Null
  )
   Create Table #EventShipment (
    Event_Id int NULL,
    Event_Num nVarChar(50) NULL,
    PU_Id Int NULL,
    Start_Time DateTime NULL,
    TimeStamp DateTime NULL,
    Applied_Product Int NULL,
    Source_Event int NULL,
    Event_Status Int NULL,
    Event_Status_Desc nVarChar(50) NULL,
    Event_SubType_Id Int NULL,
    Event_SubType_Desc nVarChar(50) NULL,
    Prod_Id int NULL,
    Crew_Desc nVarChar(10) Null,
    Shift_Desc nVarChar(10) Null,
    Order_id int NULL,
    Shipment_Id Int NULL,
    PU_Desc nVarChar(50) Null,
    Group_Id Int Null,
    Comment_Id Int Null,
    Status_Id Int Null,
    GenealogyLevel Int Null
   )
  Select @EndPosition=CharIndex("\",@Shipments)
  While (@EndPosition<>0)
   Begin
    Select @ProdId = Convert(Int,Substring(@Shipments,1,(@EndPosition-1)))
    Insert Into #Shipment Values (@ProdId)
    Select @Shipments =  Right(@Shipments, Len(@Shipments)- @EndPosition)
    Select @EndPosition=CharIndex("\",@Shipments)
   End -- while loop
  Insert Into #EventShipment
    Select T.Event_Id, T.Event_Num, T.PU_Id, T.Start_Time, T.TimeStamp, T.Applied_Product, T.Source_Event, 
     T.Event_Status, T.Event_Status_Desc, T.Event_SubType_Id, T.Event_SubType_Desc, T.Prod_Id, T.Crew_Desc, T.Shift_Desc, T.Order_Id, T.Shipment_Id,
     T.PU_Desc, T.Group_Id, T.Comment_Id, T.Status_Id, T.GenealogyLevel   
      From #EventTemp T Inner Join #Shipment P On  T.Shipment_Id = P.Shipment_Id
  Delete From #EventTemp
  Insert Into #EventTemp
   Select * From #EventShipment
  Drop Table #EventShipment
  Drop Table #Shipment
 End
--------------------------------------------------------------------
-- Parents
--------------------------------------------------------------------
If (@ParentsSteps Is Not Null And @ParentsSteps>0)
  Begin
   Select @Level=-1
   Select @NewLevel = 0 
   While (@Level < @ParentsSteps-1)
    Begin
     Select @Level= @Level + 1
     Select @NewLevel = @NewLevel +1
     Insert Into #EventTemp 
      Select EC.Source_Event_Id, EV.Event_Num, EV.PU_Id, EV.Start_Time, EV.TimeStamp, EV.Applied_Product, 
         EV.Source_Event, EV.Event_Status, PS.ProdStatus_Desc, EV.Event_SubType_Id, ES.Event_SubType_Desc, Null as Prod_Id, 
         Null as Crew_Desc, Null as Shift_Desc, ED.Order_Id, SI.Shipment_Id,
         PU.PU_Desc, PU.Group_Id, EV.Comment_Id, EV.Event_Status, @NewLevel as GenealogyLevel 
       From #EventTemp ET
        Inner Join Event_Components EC On EC.Event_Id = ET.Event_Id
        Inner Join Events EV On EC.Source_Event_Id = EV.Event_Id 
        Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
        Left Outer Join Comments CO On EV.Comment_Id = CO.Comment_Id 
        Left Outer Join Event_Details ED ON EV.Event_Id = ED.Event_Id 
        Left Outer Join Shipment_Line_Items SI on ED.Shipment_Item_id = SI.Shipment_Item_Id
        Left Outer Join Production_Status PS on EV.Event_Status = PS.ProdStatus_Id
        Left Outer Join Event_SubTypes ES on EV.Event_SubType_Id = ES.Event_SubType_Id
         Where ET.GenealogyLevel = @Level
     End
   End
--------------------------------------------------------------------
-- Children
--------------------------------------------------------------------
If (@ChildrenSteps Is Not Null And @ChildrenSteps>0)
  Begin
   Select @Level= -1
   Select @NewLevel = 0
   While (@Level < @ChildrenSteps-1)
    Begin
     Select @Level= @Level + 1
     Select @NewLevel = @NewLevel +1
     Insert Into #EventTemp 
      Select EC.Event_Id, EV.Event_Num, EV.PU_Id, EV.Start_Time, EV.TimeStamp, EV.Applied_Product, 
         EV.Source_Event, EV.Event_Status, PS.ProdStatus_Desc, EV.Event_SubType_Id, ES.Event_SubType_Desc, Null as Prod_Id, 
         Null as Crew_Desc, Null as Shift_Desc, ED.Order_Id, SI.Shipment_Id,
         PU.PU_Desc, PU.Group_Id, EV.Comment_Id, EV.Event_Status, @NewLevel*-1 as GenealogyLevel 
       From #EventTemp ET 
        Inner Join Event_Components EC On EC.Source_Event_Id = ET.Event_Id
        Inner Join Events EV On EC.Event_Id = EV.Event_Id
        Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
        Left Outer Join Comments CO On EV.Comment_Id = CO.Comment_Id 
        Left Outer Join Event_Details ED ON EV.Event_Id = ED.Event_Id 
        Left Outer Join Shipment_Line_Items SI on ED.Shipment_Item_id = SI.Shipment_Item_Id
        Left Outer Join Production_Status PS on EV.Event_Status = PS.ProdStatus_Id
        Left Outer Join Event_SubTypes ES on EV.Event_SubType_Id = ES.Event_SubType_Id
         Where ET.GenealogyLevel = @Level*-1
     End
   End
--------------------------------------------------------------------
-- Update Start_Time if NULL on Events table (Use TimeStamp of Previous event for the same unit)
-------------------------------------------------------------------
   Declare STCursor INSENSITIVE CURSOR
     For (Select T.Event_Id, T.TimeStamp, T.PU_Id From #EventTemp T Where T.Start_Time is NULL)
      For Read Only
      Open STCursor
      STLoop:
        Fetch Next From STCursor Into @EventId, @TimeStamp, @PUId
        If (@@Fetch_Status = 0)
          Begin
          Select @Prev_Timestamp = Max(TimeStamp) From Events E Where E.TimeStamp < @TimeStamp and E.PU_Id = @PUId
          Update #EventTemp
           Set Start_Time = @Prev_Timestamp
            Where Event_Id = @EventId
           Goto STLoop
         End
   Close STCursor
   Deallocate STCursor
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 -- only 1st 5 visible
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('TimeStamp')
 	 Insert into @CHT(HeaderTag,Idx) Values (16304,1) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16334,2) -- Event Number
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,3) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16335,4) -- TimeStamp
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Unit] = T.PU_Desc, 
 	  	  	 [Event Number] = T.Event_Num, 
 	  	  	 [Start Time] = T.Start_Time, 
 	  	  	 [TimeStamp] = T.TimeStamp, 
 	  	  	 [Event Id] = T.Event_Id, 
 	  	  	 [Unit Id] = T.PU_Id, 
 	  	  	 [Applied Product] = T.Applied_Product, 
 	  	  	 [Source Event] = T.Source_Event, 
 	  	  	 [Event Status] = T.Event_Status, 
 	  	  	 [Event Subtype Id] = T.Event_SubType_Id, 
 	  	  	 [Product Id] = T.Prod_Id, 
 	  	  	 [Crew Desc] = T.Crew_Desc, 
 	  	  	 [Shift Desc] = T.Shift_Desc, 
 	  	  	 [Group Id] = T.Group_Id, 
 	  	  	 [Comment Id] = T.Comment_Id, 
 	  	  	 [Status Id] = T.Status_Id, 
 	  	  	 [Genealogy Level] = T.GenealogyLevel, 
 	  	  	 [Event Subtype Desc] = T.Event_SubType_Desc, 
 	  	  	 [Event Status Desc] = T.Event_Status_Desc
   From  #EventTemp T 
   Order By T.TimeStamp desc
END
ELSE
BEGIN
 Select T.PU_Desc as 'Unit Desc', T.Event_Num as 'Event Num', T.Start_Time as 'Start Time', T.TimeStamp as 'Time Stamp', 
        T.Event_Id as 'Event Id', T.PU_Id as 'Unit Id', T.Applied_Product as 'Applied Product', 
        T.Source_Event as 'Source Event', T.Event_Status as 'Event Status', 
        T.Event_SubType_Id as 'Event Subtype Id', T.Prod_Id as 'Product Id', T.Crew_Desc as 'Crew Desc', 
        T.Shift_Desc as 'Shift Desc', T.Group_Id as 'Group Id', T.Comment_Id as 'Comment Id', 
        T.Status_Id as 'Status Id', T.GenealogyLevel as 'Genealogy Level', 
        T.Event_SubType_Desc as 'Event Subtype Desc', T.Event_Status_Desc as 'Event Status Desc'
   From  #EventTemp T 
   Order By T.TimeStamp desc
END
Drop Table #EventTemp

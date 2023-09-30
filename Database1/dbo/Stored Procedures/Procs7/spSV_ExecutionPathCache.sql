-- 
CREATE Procedure dbo.spSV_ExecutionPathCache
@Sheet_Id int,
@Path_Id int = NULL,
@PP_Id int = NULL,
@DisplayUnboundOrders bit = NULL
AS
If @Sheet_Id = 0
  Select @Sheet_Id = NULL
If @Path_Id = 0
  Select @Path_Id = NULL
If @PP_Id = 0
  Select @PP_Id = NULL
If @DisplayUnboundOrders = 0
  Select @DisplayUnboundOrders = NULL
If @Path_Id is NULL
  Select @Path_Id = Path_Id From Production_Plan Where PP_Id = @PP_Id
Declare @PendingId int, @NextId int, @ActiveId int, @CompleteId int,@ErrorId Int
Declare @Max_PPStatusId int
Declare @Local_Path_Id int
Select @Local_Path_Id = @Path_Id
DECLARE @PathsViewableOnSheet TABLE  (Path_Id int)
DECLARE @PathsDefined TABLE  (Path_Id int)
INSERT INTO @PathsViewableOnSheet (Path_Id)
  Select Path_Id
    From Sheet_Paths Where Sheet_Id = @Sheet_Id
    Order By Path_Id
Insert Into @PathsDefined(Path_Id)
 	 Select Distinct Path_Id From Production_Plan_Status
Select @ErrorId = -1
Select @PendingId = 1
Select @NextId = 2
Select @ActiveId = 3
Select @CompleteId = 4
Select Status_Name = PP_Status_Desc, Status_Id = PP_Status_Id, 
    Color = Case When c.Color Is Null and PP_Status_Id = @PendingId Then 10092543 --65535 
                 When c.Color Is Null and PP_Status_Id = @NextId Then 52377 --8585090 	 
                 When c.Color Is Null and PP_Status_Id = @ActiveId Then 65280 --56320 	 
                 When c.Color Is Null and PP_Status_Id = @CompleteId Then 12632256 
                 When c.Color Is Null Then 16777215 
                 Else c.Color End,
    Movable,Editable = isnull(Allow_Edit,0)
  From Production_Plan_Statuses ppss
  Left Join Colors c on c.Color_Id = ppss.Color_Id 
  order by PP_Status_Desc
CREATE TABLE #Transitions (Path_Id int, From_PPStatus_Id int, To_PPStatus_Id int, How_Many int, CurrentCount int)
if @Sheet_Id is NOT NULL
  INSERT INTO #Transitions
    SELECT pps.Path_Id, pps.From_PPStatus_Id, pps.To_PPStatus_Id, Coalesce(ppsd.How_Many, -1), NULL
     	 From Production_Plan_Status pps
     	 Left Outer Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = pps.To_PPStatus_Id
      Left Outer Join PrdExec_Path_Status_Detail ppsd on ppsd.Path_Id = pps.Path_Id and ppsd.PP_Status_Id = pps.To_PPStatus_Id
      Where pps.Path_Id in (Select Path_Id From @PathsViewableOnSheet)
else
  INSERT INTO #Transitions
    SELECT pps.Path_Id, pps.From_PPStatus_Id, pps.To_PPStatus_Id, Coalesce(ppsd.How_Many, -1), NULL
     	 From Production_Plan_Status pps
     	 Left Outer Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = pps.To_PPStatus_Id
      Left Outer Join PrdExec_Path_Status_Detail ppsd on ppsd.Path_Id = pps.Path_Id and ppsd.PP_Status_Id = pps.To_PPStatus_Id
      Where pps.Path_Id = @Path_Id
  INSERT INTO #Transitions
 	 SELECT 0, @ErrorId, @ErrorId, -1, NULL
/* HANDLE FROM Status ONLY  */
IF @Sheet_Id IS NULL
BEGIN
 	 INSERT INTO #Transitions
 	  	 SELECT pps.Path_Id, pps.From_PPStatus_Id, pps.From_PPStatus_Id, Coalesce(ppsd.How_Many, -1), NULL
 	  	 FROM Production_Plan_Status pps
 	  	 Left Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = pps.To_PPStatus_Id
 	  	 Left Join PrdExec_Path_Status_Detail ppsd on ppsd.Path_Id = pps.Path_Id and ppsd.PP_Status_Id = pps.From_PPStatus_Id
 	  	 Where pps.Path_Id = @Path_Id AND From_PPStatus_Id NOT IN (SELECT To_PPStatus_Id FROM #Transitions WHERE Path_Id = @Path_Id)
END
ELSE
BEGIN
 	 INSERT INTO #Transitions
 	  	 SELECT pps.Path_Id, pps.From_PPStatus_Id, pps.From_PPStatus_Id, Coalesce(ppsd.How_Many, -1), NULL
 	  	 From Production_Plan_Status pps
 	  	 Left Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = pps.To_PPStatus_Id
 	  	 Left Join PrdExec_Path_Status_Detail ppsd on ppsd.Path_Id = pps.Path_Id and ppsd.PP_Status_Id = pps.From_PPStatus_Id
 	  	 Where pps.Path_Id in (Select Path_Id From @PathsViewableOnSheet) AND From_PPStatus_Id NOT IN (SELECT To_PPStatus_Id FROM #Transitions WHERE Path_Id in (Select Path_Id From @PathsViewableOnSheet))
END
  If @PendingId > 0 and @NextId > 0
    Begin
      INSERT INTO #Transitions
        SELECT 0, @PendingId, @NextId, 1, NULL
      INSERT INTO #Transitions
        SELECT 0, @NextId, @PendingId, -1, NULL
      if @Sheet_Id is NOT NULL
        Begin
          INSERT INTO #Transitions
            SELECT Path_Id, @PendingId, @NextId, 1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id in (Select Path_Id From @PathsViewableOnSheet)
          INSERT INTO #Transitions
            SELECT Path_Id, @NextId, @PendingId, -1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id in (Select Path_Id From @PathsViewableOnSheet)
        End
      else
        Begin
          INSERT INTO #Transitions
            SELECT Path_Id, @PendingId, @NextId, 1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id = @Path_Id  
          INSERT INTO #Transitions
            SELECT Path_Id, @NextId, @PendingId, -1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id = @Path_Id
        End
    End
  If @NextId > 0 and @ActiveId > 0
    Begin
      INSERT INTO #Transitions
        SELECT 0, @NextId, @ActiveId, 1, NULL
      if @Sheet_Id is NOT NULL
 	  	  	  	 Begin
 	         INSERT INTO #Transitions
 	           SELECT Path_Id, @NextId, @ActiveId, 1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id in (Select Path_Id From @PathsViewableOnSheet)
 	  	  	  	 End
      else
 	  	  	  	 Begin
 	         INSERT INTO #Transitions
 	           SELECT Path_Id, @NextId, @ActiveId, 1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id = @Path_Id
 	  	  	  	 End
    End
  If @ActiveId > 0 and @PendingId > 0
    Begin
      INSERT INTO #Transitions
        SELECT 0, @ActiveId, @PendingId, -1, NULL
      if @Sheet_Id is NOT NULL
 	  	  	  	 Begin
 	         INSERT INTO #Transitions
 	           SELECT Path_Id, @ActiveId, @PendingId, -1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id in (Select Path_Id From @PathsViewableOnSheet)
 	  	  	  	 End
      else
 	  	  	  	 Begin
 	         INSERT INTO #Transitions
 	           SELECT Path_Id, @ActiveId, @PendingId, -1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id = @Path_Id
 	  	  	  	 End
    End
  If @ActiveId > 0 and @CompleteId > 0
    Begin
      INSERT INTO #Transitions
        SELECT 0, @ActiveId, @CompleteId, -1, NULL
      INSERT INTO #Transitions
        SELECT 0, @CompleteId, @ActiveId, 1, NULL
      if @Sheet_Id is NOT NULL
        Begin
          INSERT INTO #Transitions
            SELECT Path_Id, @ActiveId, @CompleteId, -1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id in (Select Path_Id From @PathsViewableOnSheet)
          INSERT INTO #Transitions
            SELECT Path_Id, @CompleteId, @ActiveId, 1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id in (Select Path_Id From @PathsViewableOnSheet)
        End
      else
        Begin
          INSERT INTO #Transitions
            SELECT Path_Id, @ActiveId, @CompleteId, -1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id = @Path_Id
          INSERT INTO #Transitions
            SELECT Path_Id, @CompleteId, @ActiveId, 1, NULL From PrdExec_Paths Where Path_Id not in (Select Path_Id From @PathsDefined) and Path_Id = @Path_Id
        End
    End
UPDATE #Transitions Set How_Many = Case When (SELECT Coalesce(ppsd.How_Many, -1) From PrdExec_Path_Status_Detail ppsd Where ppsd.Path_Id = #Transitions.Path_Id and ppsd.PP_Status_Id = #Transitions.To_PPStatus_Id) <> -1 Then (SELECT ppsd.How_Many From PrdExec_Path_Status_Detail ppsd Where ppsd.Path_Id = #Transitions.Path_Id and ppsd.PP_Status_Id = #Transitions.To_PPStatus_Id) Else How_Many End
  Where Path_Id = #Transitions.Path_Id
  And To_PPStatus_Id = #Transitions.To_PPStatus_Id
If @PP_Id is NULL
  Begin
    UPDATE #Transitions Set CurrentCount = (Select Count(*) From Production_Plan Where Path_Id is NULL and PP_Status_Id = #Transitions.To_PPStatus_Id)
      Where Path_Id = 0
      And To_PPStatus_Id = #Transitions.To_PPStatus_Id
    UPDATE #Transitions Set CurrentCount = (Select Count(*) From Production_Plan Where Path_Id = #Transitions.Path_Id and PP_Status_Id = #Transitions.To_PPStatus_Id)
      Where Path_Id = #Transitions.Path_Id
      And To_PPStatus_Id = #Transitions.To_PPStatus_Id
 	  	  	 And Path_Id <> 0
  End
Else
  Begin
    If (Select PP_Status_Id From Production_Plan Where PP_Id = @PP_Id) = 3
      UPDATE #Transitions Set CurrentCount = (Select Count(*) From Production_Setup Where PP_Id = @PP_Id and PP_Status_Id = #Transitions.To_PPStatus_Id)
        Where Path_Id = #Transitions.Path_Id
        And To_PPStatus_Id = #Transitions.To_PPStatus_Id
    Else
      Delete From #Transitions
  End
SELECT  DISTINCT Path_Id, To_PPStatus_Id , How_Many, CurrentCount
  FROM #Transitions
  Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = To_PPStatus_Id
  ORDER BY Path_Id, To_PPStatus_Id, How_Many, CurrentCount
Delete From #Transitions
  Where CurrentCount >= How_Many
  And How_Many <> -1
Delete From #Transitions
  Where From_PPStatus_Id = To_PPStatus_Id
SELECT Path_Id, From_PPStatus_Id, To_PPStatus_Id
  FROM #Transitions
  Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = To_PPStatus_Id
  ORDER BY Path_Id, From_PPStatus_Id, PP_Status_Desc
DROP TABLE #Transitions
if @Sheet_Id is NOT NULL
  Begin
    Select Path_Id, Path_Code, Create_Children, Is_Schedule_Controlled, Schedule_Control_Type, Configured_For_Sheet = Case When (Select Count(*) From Sheet_Paths Where Sheet_Id = @Sheet_Id and Path_Id = pep.Path_Id) > 0 Then 1 Else 0 End
      From PrdExec_Paths pep
      Where pep.Path_Id in (Select Path_Id From @PathsViewableOnSheet)
      Order By pep.Path_Code
    Select pep.Path_Id, Prod_Id
      From PrdExec_Paths pep
      Join PrdExec_Path_Products pepp on pepp.Path_Id = pep.Path_Id
      Where pep.Path_Id in (Select Path_Id From @PathsViewableOnSheet)
      Order By Prod_Id, pep.Path_Code
  End
else
  Begin
    Select Path_Id, Path_Code, Create_Children, Is_Schedule_Controlled, Schedule_Control_Type, Configured_For_Sheet = 1
      From PrdExec_Paths pep
      Where pep.Path_Id = @Path_Id
      Order By pep.Path_Code
    Select pep.Path_Id, Prod_Id
      From PrdExec_Paths pep
      Join PrdExec_Path_Products pepp on pepp.Path_Id = pep.Path_Id
      Where pep.Path_Id = @Path_Id
      Order By Prod_Id, pep.Path_Code
  End
Select Control_Type_Id, Control_Type_Desc
  From Control_Type 
if @Sheet_Id is NOT NULL
    Exec spSV_GetSchedFilters @Sheet_Id, NULL, NULL, NULL, @DisplayUnboundOrders
else
    Exec spSV_GetSchedFilters 0, '', @Path_Id, 0, @DisplayUnboundOrders
--CREATE TABLE @SortOrder (PPSD_Id int, Path_Id int, PP_Status_Id int, Sort_Order tinyint)
Declare @SortOrder Table (PPSD_Id int, Path_Id int, PP_Status_Id int, Sort_Order tinyint)
if @Sheet_Id is NOT NULL
  INSERT INTO @SortOrder
    SELECT ppsd.PPSD_Id, ppsd.Path_Id, ppsd.PP_Status_Id, Case When ppsd.SortWith_PPStatusId is NULL or ppsd.SortWith_PPStatusId = 0 Then ppsd.Sort_Order Else (Select Sort_Order From PrdExec_Path_Status_Detail Where PP_Status_Id = ppsd.SortWith_PPStatusId and Path_Id = ppsd.Path_Id) End as 'Sort_Order'
     	 From PrdExec_Path_Status_Detail ppsd
     	 Left Outer Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = ppsd.PP_Status_Id
      Where ppsd.Path_Id in (Select Path_Id From @PathsViewableOnSheet)
else
  INSERT INTO @SortOrder
    SELECT ppsd.PPSD_Id, ppsd.Path_Id, ppsd.PP_Status_Id, Case When ppsd.SortWith_PPStatusId is NULL or ppsd.SortWith_PPStatusId = 0 Then ppsd.Sort_Order Else (Select Sort_Order From PrdExec_Path_Status_Detail Where PP_Status_Id = ppsd.SortWith_PPStatusId and Path_Id = ppsd.Path_Id) End as 'Sort_Order'
     	 From PrdExec_Path_Status_Detail ppsd
     	 Left Outer Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = ppsd.PP_Status_Id
      Where ppsd.Path_Id = @Path_Id
Declare @Counter int
Select @Counter = max(PPSD_Id) + 1 From @SortOrder
if @Sheet_Id is NOT NULL
  Begin
    Declare SortCursor INSENSITIVE CURSOR For   
      Select Path_Id
      From PrdExec_Paths
      Where Path_Id in (Select Path_Id From @PathsViewableOnSheet) and Path_Id not in (Select Distinct Path_Id From @SortOrder)
      For Read Only
      Open SortCursor  
    MySortLoop1:
      Fetch Next From SortCursor Into @Path_Id
      If (@@Fetch_Status = 0)
        Begin
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @PendingId, 1
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @NextId, 2
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @ActiveId, 3
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @CompleteId, 4
          Goto MySortLoop1
        End
    Close SortCursor
    Deallocate SortCursor
  End
else
  Begin
    Declare SortCursor INSENSITIVE CURSOR For 
      Select Path_Id
      From PrdExec_Paths
      Where Path_Id = @Path_Id
      For Read Only
      Open SortCursor  
    MySortLoop2:
      Fetch Next From SortCursor Into @Path_Id
      If (@@Fetch_Status = 0)
        Begin
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @PendingId, 1
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @NextId, 2
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @ActiveId, 3
          Select @Counter = @Counter + 1
          INSERT INTO @SortOrder
            SELECT @Counter, @Path_Id, @CompleteId, 4
          Goto MySortLoop2
        End
    Close SortCursor
    Deallocate SortCursor
  End
Select @Local_Path_Id = 0
Select @Counter = @Counter + 1
Select @Max_PPStatusId = (Select Max(PP_Status_Id) From Production_Plan_Statuses)
INSERT INTO @SortOrder
  SELECT @Counter, @Local_Path_Id, @PendingId, @Max_PPStatusId
Select @Counter = @Counter + 1
Select @Max_PPStatusId = @Max_PPStatusId + 1
INSERT INTO @SortOrder
  SELECT @Counter, @Local_Path_Id, @NextId, @Max_PPStatusId
Select @Counter = @Counter + 1
Select @Max_PPStatusId = @Max_PPStatusId + 1
INSERT INTO @SortOrder
  SELECT @Counter, @Local_Path_Id, @ActiveId, @Max_PPStatusId
Select @Counter = @Counter + 1
Select @Max_PPStatusId = @Max_PPStatusId + 1
INSERT INTO @SortOrder
  SELECT @Counter, @Local_Path_Id, @CompleteId, @Max_PPStatusId
Select PPSD_Id, Path_Id, PP_Status_Id, Sort_Order
  From @SortOrder 
  Order By Path_Id, PP_Status_Id
Select PP_Type_Id, PP_Type_Name
  From Production_Plan_Types
  Order By PP_Type_Name
Declare
  @PU_Id int,
  @AEnabled TinyInt,
  @YEnabled TinyInt,
  @ZEnabled TinyInt,
  @ATitle nvarchar(50),
  @XTitle 	 nvarchar(50),
  @YTitle 	 nvarchar(50),
  @ZTitle 	 nvarchar(50),
  @AUnits nvarchar(15),
  @XUnits 	 nvarchar(15),
  @YUnits 	 nvarchar(15),
  @ZUnits 	 nvarchar(15),
  @ESDesc nvarchar(50)
--create table @EventSubtype (PU_Id int, Dimension_A_Name nvarchar(50), Dimension_X_Name nvarchar(50), Dimension_Y_Name nvarchar(50), Dimension_Z_Name nvarchar(50), 
-- 	  	  	 Dimension_A_Eng_Units nvarchar(15), Dimension_X_Eng_Units nvarchar(15), Dimension_Y_Eng_Units nvarchar(15), Dimension_Z_Eng_Units nvarchar(15),
--      Event_SubType_Desc nvarchar(50))
DECLARE  @EventSubtype TABLE(PU_Id int, Dimension_A_Name nvarchar(50), Dimension_X_Name nvarchar(50), Dimension_Y_Name nvarchar(50), Dimension_Z_Name nvarchar(50), 
 	  	  	  	  	  	 Dimension_A_Eng_Units nvarchar(15), Dimension_X_Eng_Units nvarchar(15), Dimension_Y_Eng_Units nvarchar(15), Dimension_Z_Eng_Units nvarchar(15),
       	  	  	  	  	 Event_SubType_Desc nvarchar(50))
if @Sheet_Id is NOT NULL
  Begin
    Declare PPCursor INSENSITIVE CURSOR For 
      Select Distinct pepu.PU_Id
      From PrdExec_Path_Units pepu
      Where pepu.Path_Id in (Select Path_Id From @PathsViewableOnSheet)
      And pepu.Is_Schedule_Point = 1
      For Read Only
      Open PPCursor  
    MyPPLoop1:
      Fetch Next From PPCursor Into @PU_Id
      If (@@Fetch_Status = 0)
        Begin
            Select @AEnabled = 0, @YEnabled = 0, @ZEnabled = 0, @ATitle = '', @XTitle = '', @YTitle = '',
            @ZTitle = '', @AUnits = '', @XUnits = '', @YUnits = '', @ZUnits = '', @ESDesc = ''
            Select @XTitle = Coalesce(Dimension_X_Name,'Dimension X'),
             	 @ATitle 	 = Coalesce(Dimension_A_Name,'Dimension A'),
             	 @YTitle = Coalesce(Dimension_Y_Name,'Dimension Y'),
             	 @ZTitle = Coalesce(Dimension_Z_Name,'Dimension Z'),
             	 @AEnabled = Coalesce(Dimension_A_Enabled,0),
             	 @YEnabled = Coalesce(Dimension_Y_Enabled,0),
             	 @ZEnabled = Coalesce(Dimension_Z_Enabled,0),
              @AUnits = Dimension_A_Eng_Units,
              @XUnits 	 = Dimension_X_Eng_Units,
              @YUnits = 	 Dimension_Y_Eng_Units,
              @ZUnits 	 = Dimension_Z_Eng_Units,
              @ESDesc = Event_SubType_Desc
              From event_configuration ec  
              Left Join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
             Where ec.Pu_Id = @PU_Id and ec.et_id = 1
          If ltrim(rtrim(@ATitle)) = '' or ltrim(rtrim(@ATitle)) is null or @AEnabled = 0
             Select @ATitle = 'Dimension A'
          If ltrim(rtrim(@YTitle)) = '' or ltrim(rtrim(@YTitle)) is null or @YEnabled = 0 
             Select @YTitle = 'Dimension Y'
          If ltrim(rtrim(@ZTitle)) = '' or ltrim(rtrim(@ZTitle)) is null or @ZEnabled = 0
             Select @ZTitle = 'Dimension Z'
          If ltrim(rtrim(@XTitle)) = '' or ltrim(rtrim(@XTitle)) is null 
             Select @XTitle = 'Dimension X'
    --       If @AEnabled = 0
    --          Select @ATitle = '<none>'
    --       If @YEnabled = 0 
    --          Select @YTitle = '<none>'
    --       If @ZEnabled = 0
    --          Select @ZTitle = '<none>'
          Insert Into @EventSubtype (PU_Id, Dimension_A_Name, Dimension_X_Name, Dimension_Y_Name, Dimension_Z_Name, 
       	  	  	 Dimension_A_Eng_Units, Dimension_X_Eng_Units, Dimension_Y_Eng_Units, Dimension_Z_Eng_Units, Event_SubType_Desc)
            Select @PU_Id, @ATitle, @XTitle, @YTitle, @ZTitle, 
              @AUnits, @XUnits, @YUnits, @ZUnits, @ESDesc
          Goto MyPPLoop1
        End
    Close PPCursor
    Deallocate PPCursor
  End
else
  Begin
    Declare PPCursor INSENSITIVE CURSOR For 
      Select pepu.PU_Id
      From PrdExec_Path_Units pepu
      Where pepu.Path_Id = @Path_Id
      And pepu.Is_Schedule_Point = 1
      For Read Only
      Open PPCursor  
    MyPPLoop2:
      Fetch Next From PPCursor Into @PU_Id
      If (@@Fetch_Status = 0)
        Begin
            Select @AEnabled = 0, @YEnabled = 0, @ZEnabled = 0, @ATitle = '', @XTitle = '', @YTitle = '',
            @ZTitle = '', @AUnits = '', @XUnits = '', @YUnits = '', @ZUnits = '', @ESDesc = ''
            Select @XTitle = Coalesce(Dimension_X_Name,'Dimension X'),
             	 @ATitle 	 = Coalesce(Dimension_A_Name,'Dimension A'),
             	 @YTitle = Coalesce(Dimension_Y_Name,'Dimension Y'),
             	 @ZTitle = Coalesce(Dimension_Z_Name,'Dimension Z'),
             	 @AEnabled = Coalesce(Dimension_A_Enabled,0),
             	 @YEnabled = Coalesce(Dimension_Y_Enabled,0),
             	 @ZEnabled = Coalesce(Dimension_Z_Enabled,0),
              @AUnits = Dimension_A_Eng_Units,
              @XUnits 	 = Dimension_X_Eng_Units,
              @YUnits = 	 Dimension_Y_Eng_Units,
              @ZUnits 	 = Dimension_Z_Eng_Units,
              @ESDesc = Event_SubType_Desc
              From event_configuration ec  
              Left Join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
             Where ec.Pu_Id = @PU_Id and ec.et_id = 1
          If ltrim(rtrim(@ATitle)) = '' or ltrim(rtrim(@ATitle)) is null or @AEnabled = 0
             Select @ATitle = 'Dimension A'
          If ltrim(rtrim(@YTitle)) = '' or ltrim(rtrim(@YTitle)) is null or @YEnabled = 0 
             Select @YTitle = 'Dimension Y'
          If ltrim(rtrim(@ZTitle)) = '' or ltrim(rtrim(@ZTitle)) is null or @ZEnabled = 0
             Select @ZTitle = 'Dimension Z'
          If ltrim(rtrim(@XTitle)) = '' or ltrim(rtrim(@XTitle)) is null 
             Select @XTitle = 'Dimension X'
    --       If @AEnabled = 0
    --          Select @ATitle = '<none>'
    --       If @YEnabled = 0 
    --          Select @YTitle = '<none>'
    --       If @ZEnabled = 0
    --          Select @ZTitle = '<none>'
          Insert Into @EventSubtype (PU_Id, Dimension_A_Name, Dimension_X_Name, Dimension_Y_Name, Dimension_Z_Name, 
       	  	  	 Dimension_A_Eng_Units, Dimension_X_Eng_Units, Dimension_Y_Eng_Units, Dimension_Z_Eng_Units, Event_SubType_Desc)
            Select @PU_Id, @ATitle, @XTitle, @YTitle, @ZTitle, 
              @AUnits, @XUnits, @YUnits, @ZUnits, @ESDesc
          Goto MyPPLoop2
        End
    Close PPCursor
    Deallocate PPCursor
  End
Declare @EUOverides Table (PUId Int,EngUnits nvarchar(15))
Insert Into @EUOverides(PUId,EngUnits)
select pu.PU_Id,v.Eng_Units
From prod_Units pu
Join Variables v on v.var_Id = pu.Production_Variable and v.eng_Units is not null
Where pu.Production_Variable is not null
Select PU_Id, Dimension_A_Name, Dimension_X_Name, Dimension_Y_Name, Dimension_Z_Name, 
 	 Dimension_A_Eng_Units = Isnull(Dimension_A_Eng_Units,''), Dimension_X_Eng_Units = Coalesce(EngUnits,Dimension_X_Eng_Units,''), Dimension_Y_Eng_Units = Isnull(Dimension_Y_Eng_Units,''), Dimension_Z_Eng_Units = Isnull(Dimension_Z_Eng_Units,''), Event_SubType_Desc
From @EventSubtype es
Left Join @EUOverides eu On eu.PUId = es.PU_Id
Order By PU_Id Asc
--CREATE TABLE @PathsUnits (Path_Id int, AllUnitsOnPath nvarchar(3500), IsProductionPointUnits nvarchar(3500), IsSchedulePointUnit nvarchar(50))
DECLARE  @PathsUnits TABLE(Path_Id int, AllUnitsOnPath nvarchar(3500), IsProductionPointUnits nvarchar(3500), IsSchedulePointUnit nvarchar(50))
Declare
  @@Path_Id int,
  @@PU_Id int,
 	 @@IsSchedulePoint bit,
 	 @@IsProductionPoint bit,
 	 @@AllUnitsOnPath varchar(7000), 
 	 @@IsProductionPointUnits varchar(7000), 
 	 @@IsSchedulePointUnit varchar(7000)
Declare PathCursor INSENSITIVE CURSOR For 
  Select Path_Id
  From @PathsViewableOnSheet
  For Read Only
  Open PathCursor  
MyPathLoop:
  Fetch Next From PathCursor Into @@Path_Id
  If (@@Fetch_Status = 0)
    Begin
 	  	  	 Select @@AllUnitsOnPath = NULL, @@IsProductionPointUnits = NULL, @@IsSchedulePointUnit = NULL
      Declare PathUnitCursor INSENSITIVE CURSOR For 
        Select pu.PU_Id, pepu.Is_Schedule_Point, pepu.Is_Production_Point
        From Prod_Units pu
 	  	  	  	 Join PrdExec_Path_Units pepu on pepu.PU_Id = pu.PU_Id
        Where pepu.Path_Id = @@Path_Id
        For Read Only
        Open PathUnitCursor  
      MyPathUnitLoop:
        Fetch Next From PathUnitCursor Into @@PU_Id, @@IsSchedulePoint, @@IsProductionPoint
        If (@@Fetch_Status = 0)
          Begin
 	  	  	  	  	  	 Select @@AllUnitsOnPath = Case When @@AllUnitsOnPath is NULL Then '' Else @@AllUnitsOnPath + ', ' End + LTrim(RTrim(Convert(nvarchar(25), @@PU_Id)))
 	  	  	  	  	  	 If @@IsProductionPoint = 1
 	  	  	  	  	  	  	 Select @@IsProductionPointUnits = Case When @@IsProductionPointUnits is NULL Then '' Else @@IsProductionPointUnits + ', ' End + LTrim(RTrim(Convert(nvarchar(25), @@PU_Id)))
 	  	  	  	  	  	 If @@IsSchedulePoint = 1
 	  	  	  	  	  	  	 Select @@IsSchedulePointUnit = Case When @@IsSchedulePointUnit is NULL Then '' Else @@IsSchedulePointUnit + ', ' End + LTrim(RTrim(Convert(nvarchar(25), @@PU_Id)))
            Goto MyPathUnitLoop
          End
      Close PathUnitCursor
      Deallocate PathUnitCursor
 	  	  	 INSERT INTO @PathsUnits
 	  	  	  	 Select @@Path_Id, @@AllUnitsOnPath, @@IsProductionPointUnits, @@IsSchedulePointUnit
      Goto MyPathLoop
    End
Close PathCursor
Deallocate PathCursor
Select Path_Id, Coalesce(AllUnitsOnPath, '') as 'AllUnitsOnPath', Coalesce(IsProductionPointUnits, '') as 'IsProductionPointUnits', Coalesce(IsSchedulePointUnit, '') as 'IsSchedulePointUnit'
 	 From @PathsUnits
 	 Order By Path_Id ASC

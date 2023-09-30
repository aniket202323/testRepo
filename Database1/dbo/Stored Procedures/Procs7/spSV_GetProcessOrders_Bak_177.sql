CREATE  Procedure dbo.[spSV_GetProcessOrders_Bak_177]
@Sheet_Id int,
@StartTime datetime,
@EndTime datetime,
@Path_Id int = NULL,
@PP_Id int = NULL,
@DisplayUnboundOrders bit = NULL,
@SF_Desc nvarchar(100) = NULL
AS
Declare @TimeShift Int
Declare @sOrders VarChar(7000), 
 	  	  	  	 @sSeq VarChar(7000)
Select @TimeShift = 10
If @Sheet_Id = 0
  Select @Sheet_Id = NULL
If @Path_Id = 0
  Select @Path_Id = NULL
If @PP_Id = 0
  Select @PP_Id = NULL
If @DisplayUnboundOrders = 0
  Select @DisplayUnboundOrders = NULL
Create Table #ProdPlan (PP_Id int, Implied_Sequence int, Comment_Id int, Path_Id int, PL_Id int, PU_Id int, Process_Order nvarchar(50), 
      Prod_Id int, PP_Status_Id int, Control_Type tinyint, Predicted_Remaining_Quantity float, Actual_Good_Quantity float, Forecast_Quantity float, 
      Predicted_Remaining_Duration float, Estimated_Remaining_Date datetime, Actual_Start_Time datetime, Forecast_Start_Date datetime, 
      Estimated_End_Duration float, Estimated_End_Date datetime, Actual_End_Time datetime, Forecast_End_Date datetime,
      Alarm_Count int, Late_Items nvarchar(10), 
      Actual_Running_Time float, Actual_Down_Time float, Predicted_Total_Duration float, 
      Actual_Good_Items int, Actual_Bad_Items int, Actual_Bad_Quantity float, 
      Parent_PP_Id int, Children nvarchar(255), Source_PP_Id int, Sequences nvarchar(255), 
      User_General_1 nvarchar(255), User_General_2 nvarchar(255), User_General_3 nvarchar(255), Extended_Info nvarchar(255), 
      Block_Number nvarchar(50), Production_Rate float, PP_Type_Id int, Adjusted_Quantity float,
      Parent_Process_Order nvarchar(50), Source_Process_Order nvarchar(50), ChildrenCount int, BOM_Formulation_Desc nvarchar(50), Implied_Sequence_Offset int)
if @Sheet_Id is NOT NULL
  Begin
    Insert Into #ProdPlan 	 (PP_Id, Implied_Sequence, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, 
      Prod_Id, PP_Status_Id, Control_Type, Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, 
      Predicted_Remaining_Duration, Estimated_Remaining_Date, Actual_Start_Time, Forecast_Start_Date, 
      Estimated_End_Duration, Estimated_End_Date, Actual_End_Time, Forecast_End_Date,
      Alarm_Count, Late_Items, 
      Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration, 
      Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, 
      Parent_PP_Id, Children, Source_PP_Id, Sequences, 
      User_General_1, User_General_2, User_General_3, Extended_Info,
      Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity,
      Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc,Implied_Sequence_Offset)
       	 Select pp.PP_Id, pp.Implied_Sequence, pp.Comment_Id, pp.Path_Id, pep.PL_Id, pepu.PU_Id, pp.Process_Order, 
        pp.Prod_Id, pp.PP_Status_Id, pp.Control_Type, pp.Predicted_Remaining_Quantity, pp.Actual_Good_Quantity, pp.Forecast_Quantity, 
        pp.Predicted_Remaining_Duration, NULL as 'Estimated_Remaining_Date', pp.Actual_Start_Time, pp.Forecast_Start_Date, 
        NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date', pp.Actual_End_Time, pp.Forecast_End_Date,
       	 pp.Alarm_Count, pp.Late_Items, 
        pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Predicted_Total_Duration, 
        pp.Actual_Good_Items, pp.Actual_Bad_Items, pp.Actual_Bad_Quantity, 
        pp.Parent_PP_Id, NULL as 'Children', pp.Source_PP_Id, Null as 'Sequences', 
        pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info, 
        pp.Block_Number, pp.Production_Rate, pp.PP_Type_Id, pp.Adjusted_Quantity,
        ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount',
 	  	  	  	 bomf.BOM_Formulation_Desc,pp.Implied_Sequence_Offset
         	 From Production_Plan pp 
          Left Outer Join Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
          Left Outer Join Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
          Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id And pep.Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
          Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
 	  	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
         	 Where pp.Forecast_Start_Date Between @StartTime and @EndTime
    If @DisplayUnboundOrders = 1
      Insert Into #ProdPlan 	 (PP_Id, Implied_Sequence, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, 
        Prod_Id, PP_Status_Id, Control_Type, Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, 
        Predicted_Remaining_Duration, Estimated_Remaining_Date, Actual_Start_Time, Forecast_Start_Date, 
        Estimated_End_Duration, Estimated_End_Date, Actual_End_Time, Forecast_End_Date,
        Alarm_Count, Late_Items, 
        Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration, 
        Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, 
        Parent_PP_Id, Children, Source_PP_Id, Sequences, 
        User_General_1, User_General_2, User_General_3, Extended_Info,
        Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity,
        Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc,Implied_Sequence_Offset)
         	 Select pp.PP_Id, pp.Implied_Sequence, pp.Comment_Id, pp.Path_Id, NULL as 'PL_Id', NULL as 'PU_Id', pp.Process_Order, 
          pp.Prod_Id, pp.PP_Status_Id, pp.Control_Type, pp.Predicted_Remaining_Quantity, pp.Actual_Good_Quantity, pp.Forecast_Quantity, 
          pp.Predicted_Remaining_Duration, NULL as 'Estimated_Remaining_Date', pp.Actual_Start_Time, pp.Forecast_Start_Date, 
          NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date', pp.Actual_End_Time, pp.Forecast_End_Date,
         	 pp.Alarm_Count, pp.Late_Items, 
          pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Predicted_Total_Duration, 
          pp.Actual_Good_Items, pp.Actual_Bad_Items, pp.Actual_Bad_Quantity, 
          pp.Parent_PP_Id, NULL as 'Children', pp.Source_PP_Id, Null as 'Sequences', 
          pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info, 
          pp.Block_Number, pp.Production_Rate, pp.PP_Type_Id, pp.Adjusted_Quantity,
          ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount',
 	  	  	  	  	 bomf.BOM_Formulation_Desc,pp.Implied_Sequence_Offset
           	 From Production_Plan pp 
            Left Outer Join Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
            Left Outer Join Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
 	  	  	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
           	 Where pp.Forecast_Start_Date Between @StartTime and @EndTime
            And pp.Path_Id is NULL
            And pp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Prod_Id = pp.Prod_Id and Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
  End
Else If @Path_Id is NOT NULL
  Insert Into #ProdPlan 	 (PP_Id, Implied_Sequence, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, 
    Prod_Id, PP_Status_Id, Control_Type, Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, 
    Predicted_Remaining_Duration, Estimated_Remaining_Date, Actual_Start_Time, Forecast_Start_Date, 
    Estimated_End_Duration, Estimated_End_Date, Actual_End_Time, Forecast_End_Date,
    Alarm_Count, Late_Items, 
    Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration, 
    Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, 
    Parent_PP_Id, Children, Source_PP_Id, Sequences, 
    User_General_1, User_General_2, User_General_3, Extended_Info,
    Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity,
    Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc,Implied_Sequence_Offset)
     	 Select pp.PP_Id, pp.Implied_Sequence, pp.Comment_Id, pp.Path_Id, pep.PL_Id, pepu.PU_Id, pp.Process_Order, 
      pp.Prod_Id, pp.PP_Status_Id, pp.Control_Type, pp.Predicted_Remaining_Quantity, pp.Actual_Good_Quantity, pp.Forecast_Quantity, 
      pp.Predicted_Remaining_Duration, NULL as 'Estimated_Remaining_Date', pp.Actual_Start_Time, pp.Forecast_Start_Date, 
      NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date', pp.Actual_End_Time, pp.Forecast_End_Date,
     	 pp.Alarm_Count, pp.Late_Items, 
      pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Predicted_Total_Duration, 
      pp.Actual_Good_Items, pp.Actual_Bad_Items, pp.Actual_Bad_Quantity, 
      pp.Parent_PP_Id, NULL as 'Children', pp.Source_PP_Id, Null as 'Sequences', 
      pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info, 
      pp.Block_Number, pp.Production_Rate, pp.PP_Type_Id, pp.Adjusted_Quantity,
      ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount',
 	  	  	 bomf.BOM_Formulation_Desc,pp.Implied_Sequence_Offset
       	 From Production_Plan pp 
        Left Outer Join Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
        Left Outer Join Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
        Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
        Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
 	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
        Where pp.Forecast_Start_Date Between @StartTime and @EndTime
       	 And pp.Path_Id = @Path_Id
Else If @PP_Id is NOT NULL
  Begin
    If PATINDEX('%<CHILDREN>%', @SF_Desc) > 0
      Insert Into #ProdPlan 	 (PP_Id, Implied_Sequence, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, 
        Prod_Id, PP_Status_Id, Control_Type, Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, 
        Predicted_Remaining_Duration, Estimated_Remaining_Date, Actual_Start_Time, Forecast_Start_Date, 
        Estimated_End_Duration, Estimated_End_Date, Actual_End_Time, Forecast_End_Date,
        Alarm_Count, Late_Items, 
        Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration, 
        Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, 
        Parent_PP_Id, Children, Source_PP_Id, Sequences, 
        User_General_1, User_General_2, User_General_3, Extended_Info,
        Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity,
        Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc,Implied_Sequence_Offset)
         	 Select pp.PP_Id, pp.Implied_Sequence, pp.Comment_Id, pp.Path_Id, pep.PL_Id, pepu.PU_Id, pp.Process_Order, 
          pp.Prod_Id, pp.PP_Status_Id, pp.Control_Type, pp.Predicted_Remaining_Quantity, pp.Actual_Good_Quantity, pp.Forecast_Quantity, 
          pp.Predicted_Remaining_Duration, NULL as 'Estimated_Remaining_Date', pp.Actual_Start_Time, pp.Forecast_Start_Date, 
          NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date', pp.Actual_End_Time, pp.Forecast_End_Date,
         	 pp.Alarm_Count, pp.Late_Items, 
          pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Predicted_Total_Duration, 
          pp.Actual_Good_Items, pp.Actual_Bad_Items, pp.Actual_Bad_Quantity, 
          pp.Parent_PP_Id, NULL as 'Children', pp.Source_PP_Id, Null as 'Sequences', 
          pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info, 
          pp.Block_Number, pp.Production_Rate, pp.PP_Type_Id, pp.Adjusted_Quantity,
          ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount',
 	  	  	  	  	 bomf.BOM_Formulation_Desc,pp.Implied_Sequence_Offset
           	 From Production_Plan pp 
            Left Outer Join Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
            Left Outer Join Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
            Left Outer Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
            Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
 	  	  	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
           	 Where pp.Parent_PP_Id = @PP_Id
    Else
      Insert Into #ProdPlan 	 (PP_Id, Implied_Sequence, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, 
        Prod_Id, PP_Status_Id, Control_Type, Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, 
        Predicted_Remaining_Duration, Estimated_Remaining_Date, Actual_Start_Time, Forecast_Start_Date, 
        Estimated_End_Duration, Estimated_End_Date, Actual_End_Time, Forecast_End_Date,
        Alarm_Count, Late_Items, 
        Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration, 
        Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, 
        Parent_PP_Id, Children, Source_PP_Id, Sequences, 
        User_General_1, User_General_2, User_General_3, Extended_Info,
        Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity,
        Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc,Implied_Sequence_Offset)
         	 Select pp.PP_Id, pp.Implied_Sequence, pp.Comment_Id, pp.Path_Id, pep.PL_Id, pepu.PU_Id, pp.Process_Order, 
          pp.Prod_Id, pp.PP_Status_Id, pp.Control_Type, pp.Predicted_Remaining_Quantity, pp.Actual_Good_Quantity, pp.Forecast_Quantity, 
          pp.Predicted_Remaining_Duration, NULL as 'Estimated_Remaining_Date', pp.Actual_Start_Time, pp.Forecast_Start_Date, 
          NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date', pp.Actual_End_Time, pp.Forecast_End_Date,
         	 pp.Alarm_Count, pp.Late_Items, 
          pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Predicted_Total_Duration, 
          pp.Actual_Good_Items, pp.Actual_Bad_Items, pp.Actual_Bad_Quantity, 
          pp.Parent_PP_Id, NULL as 'Children', pp.Source_PP_Id, Null as 'Sequences', 
          pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info, 
          pp.Block_Number, pp.Production_Rate, pp.PP_Type_Id, pp.Adjusted_Quantity,
          ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount',
 	  	  	  	  	 bomf.BOM_Formulation_Desc,pp.Implied_Sequence_Offset
           	 From Production_Plan pp 
            Left Outer Join Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
            Left Outer Join Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
            Left Outer Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
            Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
 	  	  	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
           	 Where pp.PP_Id = @PP_Id
  End
-- { MODIFICATION STARTS: 2-24-2005: msi/mt
--   Accommodate Portal Connector; handling unbound process order details
ELSE
  BEGIN
    INSERT INTO #ProdPlan (PP_Id, Implied_Sequence, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, Prod_Id, PP_Status_Id, Control_Type
                         , Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, Predicted_Remaining_Duration
                         , Estimated_Remaining_Date, Actual_Start_Time, Forecast_Start_Date, Estimated_End_Duration, Estimated_End_Date
                         , Actual_End_Time, Forecast_End_Date, Alarm_Count, Late_Items, Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration
                         , Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, Parent_PP_Id, Children, Source_PP_Id, Sequences
                         , User_General_1, User_General_2, User_General_3, Extended_Info, Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity
                         , Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc,Implied_Sequence_Offset
                          )
        SELECT pp.PP_Id, pp.Implied_Sequence, pp.Comment_Id, pp.Path_Id, NULL as 'PL_Id', NULL as 'PU_Id', pp.Process_Order, pp.Prod_Id, pp.PP_Status_Id
             , pp.Control_Type, pp.Predicted_Remaining_Quantity, pp.Actual_Good_Quantity, pp.Forecast_Quantity, pp.Predicted_Remaining_Duration
             , NULL as 'Estimated_Remaining_Date', pp.Actual_Start_Time, pp.Forecast_Start_Date, NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date'
             , pp.Actual_End_Time, pp.Forecast_End_Date, pp.Alarm_Count, pp.Late_Items, pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Predicted_Total_Duration
             , pp.Actual_Good_Items, pp.Actual_Bad_Items, pp.Actual_Bad_Quantity, pp.Parent_PP_Id, NULL as 'Children', pp.Source_PP_Id, Null as 'Sequences'
             , pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info, pp.Block_Number, pp.Production_Rate, pp.PP_Type_Id, pp.Adjusted_Quantity
             , ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount', bomf.BOM_Formulation_Desc
 	  	  	  ,pp.Implied_Sequence_Offset
          FROM Production_Plan pp 
          LEFT OUTER JOIN Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
          LEFT OUTER JOIN Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
 	  	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
         WHERE pp.Forecast_Start_Date BETWEEN @StartTime AND @EndTime
           AND pp.Path_Id IS NULL
        -- AND pp.Prod_Id IN (SELECT Prod_Id FROM PrdExec_Path_Products WHERE Prod_Id = pp.Prod_Id AND Path_Id IN (SELECT Path_Id FROM Sheet_Paths WHERE Sheet_Id = @Sheet_Id))
  END
--ENDIF
-- } MODIFICATION END
Update #ProdPlan 	 Set Estimated_End_Duration = DATEDIFF(minute, Actual_End_Time, Forecast_End_Date)
Declare @Estimated_End_Duration float
Declare 	 @@PP_Id int, 
 	  	 @@Children_ProcessOrder nvarchar(50),
 	  	 @@Path_Id int,
 	  	 @@Pattern_Code nvarchar(25),
 	  	 @@ChildrenCount int,
 	  	 @@Next_ImpliedSequence int,
 	  	 @@Implied_Seq int
DECLARE @LastSD DateTime
DECLARE @ThisSD DateTime
DECLARE @ActualET DateTime
DECLARE @ActualST DateTime
DECLARE @PercentComplete Float
DECLARE @MinutesRun Int
DECLARE @MinutesLeft Int
DECLARE @ForcastET DateTime
DECLARE @ForcastST DateTime
Declare PPCursor INSENSITIVE CURSOR For 
  Select PP_Id, Path_Id, Implied_Sequence,Actual_Start_Time,Actual_End_Time,Forecast_Start_Date,Forecast_End_Date
  From #ProdPlan pp 
  Order By Implied_Sequence asc, Coalesce(Forecast_Start_Date, Actual_Start_Time) desc
  For Read Only
  Open PPCursor  
MyPPLoop:
  Fetch Next From PPCursor Into @@PP_Id, @@Path_Id, @@Implied_Seq,@ActualST,@ActualET,@ForcastST,@ForcastET
If (@@Fetch_Status = 0)
BEGIN
 	 /* Child Orders */
 	 Select @@ChildrenCount = 0
 	 Select @sOrders = ''
 	 Select @@ChildrenCount = Count(*)
        FROM   production_Plan 
        where Parent_PP_Id = @@PP_Id
 	 Select @sOrders = @sOrders + ', ' + Process_Order
 	  	 FROM   production_Plan 
 	  	 where Parent_PP_Id = @@PP_Id
 	 If @sOrders <> ''
 	   Begin
 	  	 Select @sOrders=substring(@sOrders,3,len(@sOrders))
 	  	 If Len(@sOrders) > 255 Select @sOrders = substring(@sOrders,1,255)
 	 End
 	 Update #ProdPlan Set Children = @sOrders,ChildrenCount = @@ChildrenCount Where PP_Id = @@PP_Id
 	 Select @sSeq = ''
 	 Select @sSeq = @sSeq + ', ' + Pattern_Code
 	  	 FROM  Production_Setup 
 	  	 where PP_Id = @PP_Id
 	 If @sSeq <> ''
 	 Begin
 	  	 Select @sSeq=substring(@sSeq,3,len(@sSeq))
 	  	 If Len(@sSeq) > 255 Select @sSeq = substring(@sSeq,1,255)
 	 End
 	 Update #ProdPlan Set Sequences = @sSeq Where PP_Id = @@PP_Id
 	 /* Child Orders DONE */
 	 IF @ActualET Is Not Null
 	  	   Update #ProdPlan 
 	  	  	 Set Estimated_End_Date = @ActualEt WHERE  PP_Id = @@PP_Id
 	 IF @ActualST Is Not Null
 	  	   Update #ProdPlan 
 	  	  	 Set Estimated_Remaining_Date = @ActualST WHERE  PP_Id = @@PP_Id
 	 IF  	 @ActualST Is Not Null and @ActualET Is Null -- current record
 	 BEGIN
 	  	 IF (SELECT Actual_Good_Quantity FROM #ProdPlan WHERE  PP_Id = @@PP_Id) > 0
 	  	 Begin
 	  	  	 SELECT @PercentComplete = Actual_Good_Quantity/Forecast_Quantity * 1.0 FROM #ProdPlan WHERE  PP_Id = @@PP_Id
 	  	  	 SELECT @MinutesRun = DateDiff(Minute,@ActualST,dbo.fnServer_CmnGetDate(getUTCdate()))
 	  	  	 SELECT @MinutesLeft = @MinutesRun / @PercentComplete  - @MinutesRun
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @MinutesLeft = DateDiff(Minute,@ForcastST,@ForcastET) 
 	  	 END
 	  	 SELECT @ActualET =  DateAdd(Minute,@MinutesLeft,dbo.fnServer_CmnGetDate(getUTCdate()))
 	  	 Update #ProdPlan 
 	  	  	 Set Estimated_End_Date = @ActualET WHERE  PP_Id = @@PP_Id
 	 END
 	 ELSE
 	 IF @LastSD Is Not Null
 	 BEGIN
 	  	 IF @LastSD > @ForcastST
 	  	 BEGIN
 	  	  	 SELECT @LastSD = @ForcastST
 	  	 END
 	  	 Update #ProdPlan 
 	  	  	 Set Estimated_Remaining_Date = @LastSD WHERE  Implied_Sequence = @@Implied_Seq and Path_Id = @@Path_Id
 	  	 SELECT @MinutesLeft = DateDiff(Minute,@ForcastST,@ForcastET) 
 	  	 SELECT @ActualET =  DateAdd(Minute,@MinutesLeft,@LastSD)
 	  	 Update #ProdPlan 
 	  	  	 Set Estimated_End_Date = @ActualET WHERE  Implied_Sequence = @@Implied_Seq and Path_Id = @@Path_Id
 	 END
 	 SELECT @LastSD = @ActualET
      Goto MyPPLoop
END
Close PPCursor
Deallocate PPCursor
-- Start ECR#29497
--Warning: this is a kludge - we really need to fix it so that the dates are calculated correctly. 
-- The following logic simply figures out an offset then updates the records. 
-- Try to find the active order first, then the oldest one if there is no active order
Declare @CurrentEndtime DateTime,@NextEndtime DateTime, @minForecastStartDate datetime
Declare @ImpliedSeq int, 
 	  	  	  	 @NextParentPPid int
Select @CurrentEndtime = coalesce(Estimated_End_Date,dbo.fnServer_CmnGetDate(getUTCdate()))
 From #ProdPlan
  Where PP_Status_Id = 3 and Path_Id is not null
if @CurrentEndtime IS NULL
 	 Begin
 	  	 select @minForecastStartDate = min(Forecast_Start_Date)
 	  	  	  	  From #ProdPlan
 	  	  	  	   Where PP_Status_Id < 3 and Path_Id is not null 
 	  	 Select @CurrentEndtime = coalesce(Estimated_End_Date,dbo.fnServer_CmnGetDate(getUTCdate()))
 	  	  From #ProdPlan
 	  	   Where PP_Status_Id < 3 and Path_Id is not null AND Forecast_Start_Date = @minForecastStartDate
 	 End
Select @NextEndtime = coalesce(Min(Estimated_Remaining_Date),dbo.fnServer_CmnGetDate(getUTCdate()))
 	  From #ProdPlan
 	   Where PP_Status_Id < 3 and Path_Id is not null
--Select @NextEndtime,@CurrentEndtime,@Path_Id
Select @TimeShift = Datediff(minute,@NextEndtime,@CurrentEndtime)
Update #ProdPlan set Estimated_End_Date = Dateadd(minute,@TimeShift, Estimated_End_Date),Estimated_Remaining_Date = Dateadd(minute,@TimeShift,Estimated_Remaining_Date)
 	 Where  PP_Status_Id < 3 and (Path_Id is not null) 
--Do the parents next
--Find the estimated end time of the parent of the active child
-- or if there is no active child order then get the oldest order that is pending or next
Select @ImpliedSeq = NULL, @NextParentPPid = NULL 
--check active order first
Select @NextParentPPid = Parent_PP_Id 
 From #ProdPlan 
 Where Parent_PP_Id is NOT NULL and Actual_Start_Time = 
   (Select MIN(Actual_Start_Time) from #ProdPlan Where Actual_Start_Time is NOT NULL and PP_Status_Id <=3 and Path_Id is not null and Parent_PP_Id is NOT NULL)
-- then check next 
Select @NextParentPPid = COALESCE( @NextParentPPid, Parent_PP_Id) 
 From #ProdPlan 
 Where Parent_PP_Id is NOT NULL and Actual_Start_Time = 
   (Select MIN(Actual_Start_Time) from #ProdPlan Where Actual_Start_Time IS NULL and PP_Status_Id <=2 and Path_Id is not null and Parent_PP_Id is NOT NULL)
-- then check pending
Select @NextParentPPid = COALESCE( @NextParentPPid, Parent_PP_Id) 
 From #ProdPlan 
 Where Parent_PP_Id is NOT NULL and Actual_Start_Time = 
   (Select MIN(Actual_Start_Time) from #ProdPlan Where Actual_Start_Time IS NULL and PP_Status_Id <=1 and Path_Id is not null and Parent_PP_Id is NOT NULL)
--If we found one, do the parent math otherwise skip it
if @NextParentPPid is NOT NULL 
  BEGIN 
 	  	 Select @CurrentEndtime = coalesce(pp1.Estimated_End_Date, dbo.fnServer_CmnGetDate(getUTCdate())), @ImpliedSeq = pp1.Implied_Sequence 
 	  	  From #ProdPlan pp1
 	  	  Where PP_Id = @NextParentPPid
 	  	 --Get the offset from the current minimum estimated remaining date (which is really the Predicted Start Date) 
 	  	 Select @TimeShift = Datediff(minute, coalesce(Min(Estimated_Remaining_Date),dbo.fnServer_CmnGetDate(getUTCdate())) ,@CurrentEndtime)
 	  	  	  From #ProdPlan
 	  	  	   Where Implied_Sequence > @ImpliedSeq and Path_Id is null and Actual_Start_Time is null and ChildrenCount > 0 
 	  	 
 	  	 --Update the records that are scheduled after the active parent. 
 	  	 Update #ProdPlan set Estimated_End_Date = Dateadd(minute,@TimeShift,Estimated_End_Date), Estimated_Remaining_Date = Dateadd(minute,@TimeShift,Estimated_Remaining_Date)
 	  	  	 Where Implied_Sequence > @ImpliedSeq and Path_Id is null and Actual_Start_Time is null and ChildrenCount > 0 
  END
 	 
-- End ECR#29497
Select PP_Status_Id, Process_Order, Estimated_Remaining_Date, Estimated_End_Date, PP_Id, Implied_Sequence,ISNULL(Implied_Sequence_Offset,0) Implied_Sequence_Offset, -1 * Predicted_Remaining_Duration as Predicted_Remaining_Duration, Comment_Id, Path_Id, PL_Id, PU_Id, Process_Order, 
  Prod_Id, Control_Type, -1 * Predicted_Remaining_Quantity as Predicted_Remaining_Quantity, Actual_Good_Quantity, Forecast_Quantity, 
  Actual_Start_Time, Forecast_Start_Date, 
  Estimated_End_Duration, Actual_End_Time, Forecast_End_Date, 
  Alarm_Count, Late_Items, 
  Actual_Running_Time, Actual_Down_Time, Predicted_Total_Duration,
  Actual_Good_Items, Actual_Bad_Items, Actual_Bad_Quantity, 
  Parent_PP_Id, Children, Source_PP_Id, Sequences, 
  User_General_1, User_General_2, User_General_3, Extended_Info, 
  Block_Number, Production_Rate, PP_Type_Id, Adjusted_Quantity, 
  Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc
From #ProdPlan Order By 
PP_Status_Id
,
Implied_Sequence Desc, ISNULL(Implied_Sequence_Offset,0) Desc
Drop Table #ProdPlan

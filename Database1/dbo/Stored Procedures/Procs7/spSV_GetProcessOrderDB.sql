CREATE Procedure dbo.spSV_GetProcessOrderDB
@PP_Id int,
@Path_Id int,
@Process_Order nvarchar(50)
AS
If @Path_Id = 0
  Select @Path_Id = NULL
If @PP_Id = 0
  Select @PP_Id = PP_Id From Production_Plan Where (Path_Id = @Path_Id or (Path_Id is NULL and @Path_Id is NULL)) and Process_Order = @Process_Order
  Create Table #ProdPlan (PP_Id int, PL_Id int, PU_Id int, Children nvarchar(255), Sequences nvarchar(255), 
    Estimated_Remaining_Date datetime, Estimated_End_Duration float, Estimated_End_Date datetime, 
    User_General_1 nvarchar(255), User_General_2 nvarchar(255), User_General_3 nvarchar(255), Extended_Info nvarchar(255),
    Parent_Process_Order nvarchar(50), Source_Process_Order nvarchar(50), ChildrenCount int, BOM_Formulation_Desc nvarchar(50))
  Insert Into #ProdPlan 	 (PP_Id, PL_Id, PU_Id, Children, Sequences, 
    Estimated_Remaining_Date, Estimated_End_Duration, Estimated_End_Date, 
    User_General_1, User_General_2, User_General_3, Extended_Info,
    Parent_Process_Order, Source_Process_Order, ChildrenCount, BOM_Formulation_Desc)
     	 Select pp.PP_Id, pep.PL_Id, pepu.PU_Id, NULL as 'Children', Null as 'Sequences', 
      NULL as 'Estimated_Remaining_Date', NULL as 'Estimated_End_Duration', NULL as 'Estimated_End_Date', 
      pp.User_General_1, pp.User_General_2, pp.User_General_3, pp.Extended_Info,
      ppParent.Process_Order as 'Parent_Process_Order', ppSource.Process_Order as 'Source_Process_Order', NULL as 'ChildrenCount',
 	  	  	 bomf.BOM_Formulation_Desc
       	 From Production_Plan pp 
        Left Outer Join Production_Plan ppParent on ppParent.PP_Id = pp.Parent_PP_Id
        Left Outer Join Production_Plan ppSource on ppSource.PP_Id = pp.Source_PP_Id
        Left Outer Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
        Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
 	  	  	  	 Left Outer Join Bill_Of_Material_Formulation bomf on bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id
       	 Where pp.PP_Id = @PP_Id
Declare
  @@Children_ProcessOrder nvarchar(50),
  @@Pattern_Code nvarchar(25),
  @@ChildrenCount int,
  @@Next_ImpliedSequence int,
  @sOrders VarChar(7000),
  @sSeq VarChar(7000)
Select @@ChildrenCount = 0
Select @sOrders = ''
Select @@ChildrenCount = Count(*)
  FROM   production_Plan 
  where Parent_PP_Id = @PP_Id
Select @sOrders = @sOrders + ', ' + Process_Order
  FROM   production_Plan 
  where Parent_PP_Id = @PP_Id
If @sOrders <> ''
  Begin
    Select @sOrders=substring(@sOrders,3,len(@sOrders))
    If Len(@sOrders) > 255 Select @sOrders = substring(@sOrders,1,255)
End
Update #ProdPlan Set Children = @sOrders,ChildrenCount = @@ChildrenCount Where PP_Id = @PP_Id
/*
Select @@ChildrenCount = 0
Declare PPChildrenCursor INSENSITIVE CURSOR For 
  Select Process_Order
  From Production_Plan
  Where Parent_PP_Id = @PP_Id
  For Read Only
  Open PPChildrenCursor  
MyPPChildrenLoop:
  Fetch Next From PPChildrenCursor Into @@Children_ProcessOrder
  If (@@Fetch_Status = 0)
    Begin        
     	 Update #ProdPlan
     	   Set Children = Case When Children is NULL Then '' Else Children End + 
 	  	  	  	  	 Case When Len(Children + ', ' + @@Children_ProcessOrder) <= 255 Then ', ' + @@Children_ProcessOrder Else '' End
     	   Where PP_Id = @PP_Id
      Select @@ChildrenCount = @@ChildrenCount + 1
      Goto MyPPChildrenLoop
    End
Close PPChildrenCursor
Deallocate PPChildrenCursor
Update #ProdPlan
  Set ChildrenCount = @@ChildrenCount
  Where PP_Id = @PP_Id
*/
Select @sSeq = ''
Select @sSeq = @sSeq + ', ' + Pattern_Code
  FROM  Production_Setup 
  where PP_Id = @PP_Id
If @sSeq <> ''
  Begin
    Select @sSeq=substring(@sSeq,3,len(@sSeq))
    If Len(@sSeq) > 255 Select @sSeq = substring(@sSeq,1,255)
End
/*
Declare PPSequencesCursor INSENSITIVE CURSOR For 
  Select Distinct Pattern_Code
  From Production_Setup
  Where PP_Id = @PP_Id
  For Read Only
  Open PPSequencesCursor  
MyPPSequencesLoop:
  Fetch Next From PPSequencesCursor Into @@Pattern_Code
  If (@@Fetch_Status = 0)
    Begin        
     	 Update #ProdPlan
     	   Set Sequences = Case When Sequences is NULL Then '' Else Sequences End  + 
 	  	  	  	  	 Case When Len(Sequences + ', ' + @@Pattern_Code) <= 255 Then ', ' + @@Pattern_Code Else '' End
     	   Where PP_Id = @PP_Id
      Goto MyPPSequencesLoop
    End
Close PPSequencesCursor
Deallocate PPSequencesCursor
*/
Declare @Estimated_End_Duration float
Update #ProdPlan
  Set Estimated_End_Duration = (Select DATEDIFF(minute, Actual_End_Time, Forecast_End_Date) From Production_Plan Where PP_Id = @PP_Id) 
 	   Where PP_Id = @PP_Id
Select @@Next_ImpliedSequence = min(pp.Implied_Sequence)
  From Production_Plan pp
  Join PrdExec_Path_Status_Detail pepsd on pepsd.Path_Id = pp.Path_Id and pepsd.PP_Status_Id = pp.PP_Status_Id
  Where pp.Path_Id = @Path_Id
  And pepsd.Sort_Order <= (Select Sort_Order From PrdExec_Path_Status_Detail Where Path_Id = @Path_Id and PP_Status_Id = 3)
Select @Estimated_End_Duration = DATEDIFF(minute, Forecast_Start_Date,dbo.fnServer_CmnGetDate(getUTCdate()))
  From Production_Plan
  Where Path_Id = @Path_Id
  And Implied_Sequence = @@Next_ImpliedSequence
Update #ProdPlan
  Set Estimated_Remaining_Date = (Select DATEADD(minute, @Estimated_End_Duration, Forecast_Start_Date) From Production_Plan Where PP_Id = @PP_Id) 
 	   Where PP_Id = @PP_Id
If (Select Actual_Start_Time From Production_Plan Where PP_Id = @PP_Id) is NULL
  Update #ProdPlan
    Set Estimated_End_Date = (Select DateAdd(minute, DateDiff(minute, Forecast_Start_Date, Forecast_End_Date), Estimated_Remaining_Date) From Production_Plan Where PP_Id = @PP_Id) 
   	   Where PP_Id = @PP_Id
Else
BEGIN 
--  Update #ProdPlan
--    Set Estimated_End_Date = (Select DateAdd(minute, Predicted_Total_Duration, Actual_Start_Time) From Production_Plan Where PP_Id = @PP_Id)
--  	   Where PP_Id = @PP_Id
  -- because there is an actual start date, determine the estimated end date by just adding the 
  --   predicted remaining duration (calculated by the schedule mgr) to now()
-- ECR 28970 - Overflow error in spSV_GetProcessOrderDB
-- Parameter overflow if Predicted_Remaining_Duration exceeds 2147483647
-- Returned value overflow if datetime exceeds '9999-12-31 23:59:59.997'
  declare
    @lastDateFloat float,
    @minute float,
    @predictedRemainingDuration float,
    @dateFloat float
  set @lastDateFloat = 2958463.9999999614  -- Float value of the last date '9999-12-31 23:59:59.997'   
  set @minute = 6.9444444444444444E-4  -- Float value of 1 minute 
  select @predictedRemainingDuration = IsNull(Predicted_Remaining_Duration, 0) from Production_Plan Where PP_Id = @PP_Id 
  if @predictedRemainingDuration > 2147483647
    begin
      set @dateFloat = @predictedRemainingDuration*@minute + convert(float, dbo.fnServer_CmnGetDate(getUTCdate()))
      if @dateFloat > @lastDateFloat
        set @dateFloat = @lastDateFloat
      update #ProdPlan set Estimated_End_Date = convert(datetime, @dateFloat) Where PP_Id = @PP_Id
    end
  else -- Keep the original code for the case without overflows
-- End ECR 28970
  Update #ProdPlan
--    Set Estimated_End_Date = (Select DateAdd(minute, Predicted_Total_Duration, Actual_Start_Time) From Production_Plan Where PP_Id = @PP_Id)
    Set Estimated_End_Date = (Select DateAdd(minute, Predicted_Remaining_Duration, dbo.fnServer_CmnGetDate(getUTCdate())) From Production_Plan Where PP_Id = @PP_Id)
  	   Where PP_Id = @PP_Id
END
Select Estimated_End_Date=ISNULL(Estimated_End_Date,0), PP_Id=ISNULL(PP_Id,0), PL_Id=ISNULL(PL_Id,0), PU_Id=ISNULL(PU_Id,0), 
  Children=ISNULL(Children,''), Sequences=ISNULL(Sequences,''), 
  Estimated_Remaining_Date=ISNULL(Estimated_Remaining_Date,0), Estimated_End_Duration=ISNULL(Estimated_End_Duration,0), 
  User_General_1=ISNULL(User_General_1,''), User_General_2=ISNULL(User_General_2,''), User_General_3=ISNULL(User_General_3,''), 
  Extended_Info=ISNULL(Extended_Info,''), Parent_Process_Order=ISNULL(Parent_Process_Order,''), 
  Source_Process_Order=ISNULL(Source_Process_Order,''), ChildrenCount=ISNULL(ChildrenCount,0), BOM_Formulation_Desc=ISNULL(BOM_Formulation_Desc,'')
From #ProdPlan
Drop Table #ProdPlan

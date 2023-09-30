CREATE Procedure dbo.spMSITopic_UnitDetails
@value int OUTPUT,
@Key int,
@Topic int
 AS
Declare @HAC 	  	  	 Integer,
 	 @MAC 	  	  	 Integer,
 	 @LAC 	  	  	 Integer,
 	 @DownStatus 	  	 Bit,
 	 @DownTimeCount 	  	 Int,
 	 @ProductCode 	  	 VarChar(25),
 	 @ProcessOrder 	  	 VarChar(25),
 	 @ProdRate 	  	 VarChar(25),
 	 @ProductionAmount 	 VarChar(25),
 	 @ProductionUnits 	 VarChar(25),
 	 @ProdQuality 	  	 VarChar(25),
 	 @Downtime 	  	 VarChar(25),
 	 @DowntimeMinutes 	 Int,
 	 @ProdWaste 	  	 VarChar(25),
 	 @UnitEfficency 	  	 VarChar(25),
 	 @PU_Id 	  	  	 Int,
 	 @StartTime 	  	 DateTime,
 	 @EndTime 	  	 DateTime,
 	 @TotalEventCount 	 Int,
 	 @Event_Id 	  	 Int,
 	 @Status 	  	  	 Int,
 	 @BadCount 	  	 Int,
 	 @DetailSTime 	  	 DateTime,
 	 @DetailETime 	  	 DateTime,
 	 @Waste 	  	  	 Float,
 	 @TotalWaste 	  	 Float,
 	 @AtId 	  	  	 Int,
 	 @DimX 	  	  	 Float,
 	 @StartId  	  	 Int,
 	 @EngUnit 	  	 VarChar(100),
 	 @SubTypeDesc 	  	 VarChar(100),
 	 @Hour 	  	  	 Int,
 	 @Minute 	  	  	 Int,
 	 @Now 	  	  	 DateTime,
 	 @TotalMinutes 	 Int,
 	 @WasteEff 	  	 VarChar(25),
 	 @DownEff 	  	 VarChar(25)
--100 	 =  Day to Date
--101     =  Shift to Date
--102     =  Rolling Time
Select @EndTime =    dbo.fnServer_CmnGetDate(getUTCdate())
Select @Now = @EndTime
Select 	 @StartTime =  Case @Topic
 	  	  	   When 100 Then  Convert(DateTime,Convert(VarChar(2),month(@Now)) + '/' + Convert(VarChar(2),Day(@Now)) + '/' + Convert(VarChar(4),Year(@Now)),101)
 	  	  	   When 102 Then  DateAdd(hh,-12,@EndTime)
 	  	  	   When 104 Then  DateAdd(hh,-24,@EndTime)
 	  	  	 End
If @Topic = 100 
 Begin
  Select @Hour = Coalesce(Convert(Int,Value),0)
   From Site_Parameters
   Where Parm_Id = 14
  Select @Minute = Coalesce(Convert(Int,Value),0)
 	 From Site_Parameters
 	 Where Parm_Id = 15
  Select @StartTime = Dateadd(hour,@Hour,@StartTime)
  Select @StartTime = Dateadd(minute,@Minute,@StartTime)
  If @StartTime > @Now 
 	 Select @StartTime = Dateadd(Day,-1,@StartTime) 
End
 	 
Select @TotalMinutes = DateDiff(minute,@StartTime,@EndTime)
IF  @TotalMinutes < 1 Select  @TotalMinutes = 1
-- Set Pu_Id (passed in)
 	 Select @PU_Id = @Key
 	 Select @HAC = 0
 	 Select @MAC = 0
 	 Select @LAC = 0
        Select @DimX = 0 
 	 
 Declare Alarm_Cursor Cursor For
  Select Ap_Id 
      from Alarms a
     Join Alarm_Template_Var_Data atd  on atd.ATD_Id = a.ATD_Id
     Join Variables v on v.Var_Id = atd.Var_Id
     Join Alarm_Templates atp On atp.AT_Id =  atd.AT_Id
      Where Start_Time > @StartTime and (End_Time <=  @EndTime or End_Time Is Null)       And v.PU_Id = @PU_Id
   For Read Only
Open Alarm_Cursor
FetchLoop3:
    Fetch Next From Alarm_Cursor into @AtId
    If @@Fetch_status = 0
 	 Begin
 	    If  @AtId  = 1  	  	 Select @LAC = @LAC + 1
 	       Else If @AtId  = 2 	 Select @MAC = @MAC + 1
 	       Else If  @AtId  = 3  	 Select @HAC = @HAC + 1
 	   Goto FetchLoop3
 	 End
Close Alarm_Cursor
Deallocate Alarm_Cursor
Select @TotalEventCount = 0,@BadCount = 0
Select  @TotalEventCount = Count(*) 
  From Events
  Where (TimeStamp Between  @StartTime and  @EndTime) And Pu_Id = @PU_Id
Select @BadCount = Count(*)
   from Events e
   Join Production_status p on e.event_Status = p.ProdStatus_Id and p.Status_Valid_For_Input = 0
   Where (TimeStamp Between  @StartTime and  @EndTime) And Pu_Id = @PU_Id
Select @DimX = Sum(ed.Final_Dimension_X)
   from Events e
   Join Event_Details ed on e.event_Id = ed.Event_Id
   Join Production_status p on e.event_Status = p.ProdStatus_Id and p.Status_Valid_For_Input = 1
   Where (e.TimeStamp Between  @StartTime and  @EndTime) And e.Pu_Id = @PU_Id and @DimX is not null
  Select @EngUnit  = Null,@SubTypeDesc = Null
  Select @EngUnit = Dimension_X_Eng_Units,@SubTypeDesc = Event_Subtype_Desc
    From event_Configuration e
    Join event_subtypes es on es.Event_Subtype_Id = e.Event_Subtype_Id
    Where e.PU_ID = @PU_Id and e.ET_Id =  1                         -- et_Id of 1 = production_Event
If @EngUnit is null or ltrim(rtrim(@EngUnit)) = ''
  Select @EngUnit = 'Units'
If @SubTypeDesc is null or ltrim(rtrim(@SubTypeDesc)) = ''
  Select @SubTypeDesc = 'Events'
  Select @ProductionUnits = Convert(VarChar(25),@TotalEventCount) + ' ' + @SubTypeDesc
    If @TotalEventCount = 0
      Select @ProdQuality = '100 %'
    Else
      Select @ProdQuality =Convert(VarChar(10), ((@TotalEventCount - @BadCount) / @TotalEventCount) * 100) + '%'
Select @ProdRate = 'n/a'
If  @DimX > 1000000
  Begin
   Select @ProductionAmount = Convert(VarChar(10),cast(@DimX/1000000 as decimal(8,2))) + ' M ' + @EngUnit
   Select @ProdRate = Convert(VarChar(10),Cast(@DimX/1000000 / (@TotalMinutes /60.0)  as decimal(8,2))) + ' M' + '/hr'
  End
Else If  @DimX > 1000
  Begin
   Select @ProductionAmount = Convert(VarChar(10),cast(@DimX/1000 as decimal(6,1))) + ' K ' + @EngUnit
   Select @ProdRate = Convert(VarChar(10),Cast(@DimX/1000 / (@TotalMinutes /60.0)  as decimal(8,2))) + ' K' + '/hr'
  End
Else
 Begin
  Select @ProductionAmount = Convert(VarChar(10),@DimX) + ' ' + @EngUnit
  Select @ProdRate = Convert(VarChar(10),Cast(@DimX /  (@TotalMinutes /60.0)  as decimal(8,2))) +  '/hr'
 End
Select @TotalWaste = 0
Declare Waste_Detail_Cursor Cursor For
  Select Amount from Waste_Event_Details
--       Where  TimeStamp >= @StartTime and  Pu_Id = @PU_Id
       Where  (TimeStamp between @StartTime And @Endtime) and Pu_Id = @PU_Id
      For Read Only
Open Waste_Detail_Cursor
FetchLoop2:
    Fetch Next From Waste_Detail_Cursor into @Waste
    If @@Fetch_status = 0
 	 Begin
 	    Select @TotalWaste =  @TotalWaste + Coalesce(@Waste,0)
 	    Goto FetchLoop2
 	 End
Close Waste_Detail_Cursor
Deallocate Waste_Detail_Cursor
-- Total Waste
If  @TotalWaste > 1000000
   Select @ProdWaste = Convert(VarChar(10),cast(@TotalWaste/1000000 as decimal(8,2))) + ' M ' + @EngUnit
Else If  @TotalWaste > 1000
   Select @ProdWaste = Convert(VarChar(10),cast(@TotalWaste/1000 as decimal(6,1))) + ' K ' + @EngUnit
Else
  Select @ProdWaste = Convert(VarChar(10),Convert(Int,@TotalWaste)) + ' ' + @EngUnit
Select @DowntimeMinutes = 0,@DownStatus = 0,@DownTimeCount = 0
Declare Event_Detail_Cursor Cursor For
  Select Start_Time,End_Time from Timed_Event_Details
      Where (Start_Time >= @StartTime and End_Time <=  @EndTime) And Pu_Id = @PU_Id
  Union
  Select Start_Time,End_Time from Timed_Event_Details   Where ( End_Time is null and Pu_Id = @PU_Id)
      For Read Only
Open Event_Detail_Cursor
FetchLoop1:
    Fetch Next From Event_Detail_Cursor into @DetailSTime,@DetailETime
    If @@Fetch_status = 0
 	 Begin
 	    If @DetailETime Is null      Select @DownStatus = 1
 	    If @DetailSTime < @StartTime 
 	  	    Select @DetailSTime = @StartTime
 	    Select @DowntimeMinutes =  @DowntimeMinutes + DateDiff(mi,@DetailSTime,Coalesce(@DetailETime,@EndTime))
 	    Select @DownTimeCount = @DownTimeCount + 1
 	   Goto FetchLoop1
 	 End
Close Event_Detail_Cursor
Deallocate Event_Detail_Cursor
--Total Downtime
 	 Select @DownTime = Convert(VarChar(25),@DowntimeMinutes) + ' Min'
--select @TotalWaste,@DimX,@DowntimeMinutes,DateDiff(minute,@StartTime,@EndTime)
--select (1.00 -(convert(Float,@TotalWaste))/convert(Float,@DimX))
--Select (1 -(convert(Float,@DowntimeMinutes) / convert(Float,DateDiff(minute,@StartTime,@EndTime))))
If @DowntimeMinutes = @TotalMinutes
  Select @UnitEfficency = '0.00 %Eff'
Else IF convert(Float,@DimX) < convert(Float,@TotalWaste)
   Select @UnitEfficency = '0.00 %Eff'
Else IF convert(Float,@DimX) = 0 or Convert(Float,DateDiff(minute,@StartTime,@EndTime)) = 0
   Select @UnitEfficency = 'n/a'
Else
   Select @UnitEfficency = Convert (Varchar(25),Convert(Int,(1.00 -(convert(Float,@TotalWaste))/convert(Float,@DimX)) /
 	  	 (1 -(convert(Float,@DowntimeMinutes) / convert(Float,DateDiff(minute,@StartTime,@EndTime))))* 100.00)) + '% Eff'
-- Product Code
 	 Select @ProductCode = coalesce(p.Prod_Code, '<None>'),@StartId = Start_Id
 	   From Production_Starts ps
 	   Join Products  p on p.Prod_Id = ps.Prod_Id
 	    Where End_Time Is Null and ps.PU_Id = @PU_Id
Select  @ProcessOrder = '<none>'
-- Coalesce(pp.Process_Order,'<None>')
-- 	    From   Production_Plan pp
-- 	    Where PP_Status_Id = 3  and PU_Id = @PU_Id
/*
-- Process Order
Select @ProcessOrder = Coalesce(pp.Process_Order,'<None>')
 	    From production_plan_Starts  pps
 	    Join Production_Plan pp on pp.PP_Id = pps.PP_Id
 	    Where pps.End_Time is Null and pps.PU_Id = @PU_Id 
*/
if @ProcessOrder is Null or @ProcessOrder = '' select @ProcessOrder = '<None>' 
If  @TotalWaste >= @DimX
 Select @WasteEff = '100% Waste'
Else
  Select @WasteEff = Convert(varchar(10),Cast((@TotalWaste / @DimX)* 100.0 as Decimal(6,2))) + '% Waste'
Select @DownEff = Convert(varchar(10),Cast((((@DowntimeMinutes * 1.0) / (@TotalMinutes * 1.0) ) * 100.0) as Decimal(6,2))) + '% Down'
Select 	 Type  	  	  	 = 4,
 	 Topic 	  	  	 = @Topic,
 	 KeyValue 	  	 = @Key,
 	 High_Alarm 	  	 = @HAC,
 	 Medium_Alarm 	  	 = @MAC,
 	 Low_Alarm 	  	 = @LAC,
 	 DownTime_Status 	 = @DownStatus,
 	 Product_Code 	  	 = @ProductCode,
 	 Process_Order 	  	 = @ProcessOrder,
 	 Production_Rate 	 = @ProdRate,
 	 Production_Amount  	 = @ProductionAmount,
 	 Production_Units 	 = @ProductionUnits,
 	 Production_Quality 	 = @ProdQuality,
 	 DownTime 	  	 = @Downtime,
 	 Waste 	  	  	 = @ProdWaste,
 	 Overall_Eff 	  	 = @UnitEfficency,
 	 Pu_Id 	  	  	 = @PU_Id,
 	 DownTimeCount 	  	 = @DownTimeCount,
 	 StartTime  	  	 = convert(VarChar(25),@StartTime,120),
 	 EndTime  	  	 = convert(VarChar(25),@EndTime,120),
 	 Waste_Eff 	  	 = @WasteEff,
 	 Down_Eff 	  	 = @DownEff

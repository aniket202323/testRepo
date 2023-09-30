CREATE Procedure dbo.spSV_ProductionRunTime
@Unit int,
@ScrollCommand int,
@StartTime datetime,
@EndTime datetime
AS
/********************************************************************
-- For Testing
--*******************************************************************
Select @Unit = 43
Select @ScrollCommand = 1
Select @StartTime = '1-jan-01'
Select @EndTime = '1-jan-04'
--*******************************************************************/ 
Declare @Difference int
Select @Difference = DateDiff(second, @StartTime, @EndTime)
-- Figure Out Actual Start And End Time Based On Scroll Command
If @ScrollCommand = 1
  Begin
    -- Goto Specified Time Frame
    Select @StartTime = @StartTime
    Select @EndTime = @EndTime
  End
Else If @ScrollCommand = 2
  Begin
    -- Scroll To Previous Transition Based On START Time
    Select @StartTime = max(Start_Time)
      From Production_Plan_Starts
      Where PU_id = @Unit and
            Start_Time < @StartTime
    Select @EndTime = End_Time 
      From Production_Plan_Starts
      Where PU_id = @Unit and
            Start_Time = @StartTime
    Select @StartTime = dateadd(second, -1 * (@Difference / 2), @StartTime)
    Select @EndTime = dateadd(second, @Difference, @StartTime)
  End
Else If @ScrollCommand = 3 
  Begin
    -- Scroll To Next Transition Based On START Time
    Select @StartTime = min(Start_Time)
      From Production_Plan_Starts
      Where PU_id = @Unit and
            Start_Time > @StartTime
    Select @EndTime = End_Time 
      From Production_Plan_Starts
      Where PU_id = @Unit and
            Start_Time = @StartTime
    Select @StartTime = dateadd(second, -1 * (@Difference / 2), @StartTime)
    Select @EndTime = dateadd(second, @Difference, @StartTime)
  End
Declare @ProductionVariable int
Select @ProductionVariable = NULL
Select @ProductionVariable = production_variable from prod_units where pu_id = @Unit
If @ProductionVariable Is Null
  Begin
    -- This is "event dimension" based production
    --TODO: ? Do we subtract waste from event based production amount here?
    --TODO: ? Do We Show Applied PP, Setup, etc here ? 
    Select Timestamp = e.Timestamp, Event = e.Event_Num, Status = s.ProdStatus_Desc, 
           Value = ed.initial_dimension_x, 
           Product = Case When e.Applied_Product Is Null Then p1.prod_Code Else '*' + p2.prod_code + '*' End,
           ProcessOrder = pp.process_order, 
           SequenceCode = q.pattern_code, 
           Color = Case When pp.Process_Order is NULL Then 2 When s.status_valid_for_input = 1 Then 0 else 1 End,
           pps.PP_Start_Id, pps.Start_Time, pps.End_Time, pps.PP_Id, pps.PU_Id, pps.PP_Setup_Id
      From Events e
      Join production_starts ps on ps.pu_id = @Unit and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
      join products p1 on p1.prod_id = ps.prod_id
      join production_status s on s.prodstatus_id = e.event_status
      left outer join products p2 on p2.prod_id = e.applied_product
      left outer join event_details ed on ed.event_id = e.event_id
      left outer join production_plan_starts pps on pps.pu_id = @Unit and pps.start_time <= e.timestamp and ((pps.end_time > e.timestamp) or (pps.end_time is null))
      left outer join production_plan pp on pp.pp_id = pps.pp_id
      left outer join production_setup q on q.pp_setup_id = pps.pp_setup_id
      Where e.PU_Id = @Unit and
            e.Timestamp Between @StartTime and @EndTime
      order By e.Timestamp DESC
    Select Distinct ProcessOrder = pp.process_order, PPId = pp.pp_id
      From Events e
      Join production_starts ps on ps.pu_id = @Unit and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
      left outer join event_details ed on ed.event_id = e.event_id
      left outer join production_plan_starts pps on pps.pu_id = @Unit and pps.start_time <= e.timestamp and ((pps.end_time > e.timestamp) or (pps.end_time is null))
      left outer join production_plan pp on pp.pp_id = pps.pp_id
      Where e.PU_Id = @Unit and
            e.Timestamp Between @StartTime and @EndTime
      order By pp.process_order ASC
  End
Else
  Begin
    -- This is "variable" based production
    Select Timestamp = t.Result_On, Event = NULL, Status = NULL, 
           Value = convert(real, t.result), 
           Product =  p1.prod_Code,
           ProcessOrder = pp.process_order, 
           SequenceCode = q.pattern_code, 
           Color = Case When pp.Process_Order is NULL Then 2 else 0 End,
           pps.PP_Start_Id, pps.Start_Time, pps.End_Time, pps.PP_Id, pps.PU_Id, pps.PP_Setup_Id
      From Tests t
      Join production_starts ps on ps.pu_id = @Unit and ps.start_time <= t.result_on and ((ps.end_time > t.result_on) or (ps.end_time is null))
      join products p1 on p1.prod_id = ps.prod_id
      left outer join production_plan_starts pps on pps.pu_id = @Unit and pps.start_time <= t.result_on and ((pps.end_time > t.result_on) or (pps.end_time is null))
      left outer join production_plan pp on pp.pp_id = pps.pp_id
      left outer join production_setup q on q.pp_setup_id = pps.pp_setup_id
      Where t.Var_id = @ProductionVariable and
            t.result_on between @StartTime and @EndTime
      order by t.result_on DESC
    Select Distinct ProcessOrder = pp.process_order, PPId = pp.pp_id
      From Tests t
      Join production_starts ps on ps.pu_id = @Unit and ps.start_time <= t.result_on and ((ps.end_time > t.result_on) or (ps.end_time is null))
      left outer join production_plan_starts pps on pps.pu_id = @Unit and pps.start_time <= t.result_on and ((pps.end_time > t.result_on) or (pps.end_time is null))
      left outer join production_plan pp on pp.pp_id = pps.pp_id
      Where t.Var_id = @ProductionVariable and
            t.result_on between @StartTime and @EndTime
      order by pp.process_order ASC
  End 

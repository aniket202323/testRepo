CREATE PROCEDURE dbo.[spServer_CmnGetPOInfo_Bak_177]
@PPStartId int,
@TimeStamp DateTime,
@InPUId int,
@OutPUId int OUTPUT,
@PrevPOStart DateTime OUTPUT,
@PrevPOEnd DateTime OUTPUT,
@CurPOStart DateTime OUTPUT,
@CurPOEnd DateTime OUTPUT
AS
Declare
  @PPId int,
  @MasterPUId int,
  @EndTime datetime,
  @Status int
Select @OutPUId = NULL
Select @PPId = NULL
If (@PPStartId = 0)
  Begin
    select @MasterPUId = null
    select @MasterPUId = Master_Unit from prod_units_Base where PU_Id = @InPUId
    if (@MasterPUId is null)
      select @MasterPUId = @InPUId
    select @OutPUId = @MasterPUId
    set rowcount 1
    Select @PPId = a.PP_Id
      from production_plan_starts a
      join production_plan b on (b.pp_id = a.pp_id)
      join prdexec_path_units d on (d.path_id = b.path_id) and d.pu_id = @masterpuid
      where a.start_time < @timestamp
      order by a.Start_Time desc 
    set rowcount 0
    If (@PPId Is NULL)
      Return
    Select @EndTime = NULL
    Select @EndTime = Max(End_Time) From Production_Plan_Starts where PP_Id = @PPId And End_Time Is Not NULL
    If (@EndTime Is NULL)
      Select @EndTime = @Timestamp
    If (@EndTime < @Timestamp)
      Begin
        Select @Status = NULL
        Select @Status = PP_Status_Id From Production_Plan Where PP_Id = @PPId
        If (@Status is NULL) Or (@Status <> 3)
          return
      End
    select Start_Time, 
           EndTime = Case 
             When End_Time Is NULL Then dbo.fnServer_CmnGetDate(GetUTCDate())
             Else End_Time
           End
      from Production_Plan_Starts where PP_Id = @PPId order by Start_Time,end_time
  End
Else
  Begin
    Select @OutPUId = PU_Id, @PPId = PP_Id From Production_Plan_Starts Where (PP_Start_Id = @PPStartId)
    If (@OutPUId Is NULL) Or (@PPId Is NULL)
      Return
    Select Start_Time,End_Time,PP_Start_Id From Production_Plan_Starts
      Where (PP_Id = @PPId) and (End_Time is not null) and (PU_Id = @OutPUId)
      Order By Start_Time,end_time
  End
Select @PrevPOStart = null
Select @PrevPOEnd = null
Select @CurPOStart = null
Select @CurPOEnd = null
Select @PrevPOStart = min(Start_Time), @PrevPOEnd = max(End_Time) From Production_Plan_Starts
  Where (PP_Id = @PPId) And (Start_Time Is Not NULL) And (PU_Id = @OutPUId)
Select @CurPOStart = min(Start_Time) From Production_Plan_Starts
  Where (PP_Id = @PPId) And (Start_Time Is Not NULL) And (PU_Id = @OutPUId)
Select top 1 @CurPOEnd = End_Time from Production_Plan_Starts
  Where (PP_Id = @PPId) And (Start_Time Is Not NULL) And (PU_Id = @OutPUId)
  order by Start_Time desc
if (@CurPOEnd is null) and (@CurPOStart is not null)
  Select @CurPOEnd = dbo.fnServer_CmnGetDate(GetUTCDate())

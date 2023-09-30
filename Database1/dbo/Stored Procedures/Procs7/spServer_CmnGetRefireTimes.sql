CREATE PROCEDURE dbo.spServer_CmnGetRefireTimes
@TimeStamp datetime,
@NextReadTime datetime,
@SampInterval int,
@SampOffset int,
@SampWindow int,
@ProdDayOffset int,
@ShiftInterval int,
@ShiftOffset int,
@PUId int,
@VarId int
AS
declare
  @MasterPUId int,
  @PPId int,
  @StartTime datetime,
  @EndTime datetime,
  @RefireTime datetime,
  @Status int
if (@SampWindow != -4)
  return
if (@PUId is null)
  select @PUId = PU_Id from Variables_Base where Var_Id = @VarId
select @MasterPUId = null
select @MasterPUId = Master_Unit from prod_units_Base where PU_Id = @PUId
if (@MasterPUId is null)
  select @MasterPUId = @PUId
Select @PPId = NULL
set rowcount 1
Select @PPId = a.PP_Id
  from production_plan_starts a
  join production_plan b on (b.pp_id = a.pp_id)
  join prdexec_path_units d on (d.path_id = b.path_id) and d.pu_id = @masterpuid
  where a.start_time < @timestamp
  order by a.Start_Time desc 
set rowcount 0
If (@PPId Is NULL)
  return
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
Select @StartTime = NULL
Select @EndTime = NULL
set rowcount 1
Select @StartTime = Start_Time From Production_Plan_Starts where PP_Id = @PPId order by Start_Time asc
Select @EndTime = End_Time From Production_Plan_Starts where PP_Id = @PPId order by Start_Time desc
set rowcount 0
If (@EndTime Is NULL)
  Select @EndTime = dbo.fnServer_CmnGetDate(GetUTCDate())
Declare @RefireTimes Table(StartTime datetime, EndTime datetime)
Select @RefireTime = DateAdd(Minute, -@SampInterval,@NextReadTime)
while (@RefireTime >= @TimeStamp)
  Begin
    if (@RefireTime <= @EndTime)
      Begin
        insert into @RefireTimes(StartTime, EndTime) values (DateAdd(Minute, -@SampInterval,@RefireTime), @RefireTime)
      End
    Select @RefireTime = DateAdd(Minute, -@SampInterval,@RefireTime)
  End
Select StartTime, EndTime from @RefireTimes order by StartTime

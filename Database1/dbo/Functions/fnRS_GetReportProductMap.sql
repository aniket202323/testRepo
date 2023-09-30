CREATE FUNCTION dbo.fnRS_GetReportProductMap(@UnitId int, @StartTime datetime, @EndTime datetime, @EventType int = null) 
  	  returns  @RunTimes Table(ProdId Int, StartTime datetime, EndTime datetime)
AS 
BEGIN
  declare @UseAppliedParam nvarchar(100)
  declare @UseApplied bit
  Set @UseApplied = 0
  if (@EventType = 1)
    begin
      Select @UseAppliedParam = dbo.fnServer_CmnGetParameter(196,null,null,0,null)
      if (@UseAppliedParam = '1')
        Set @UseApplied = 1
    end
  set @StartTime = DATEADD(second, -10, @StartTime)
  set @EndTime   = DATEADD(second,  10, @EndTime)
  if (@UseApplied = 1)
    begin
      insert into @RunTimes (StartTime, EndTime, ProdId)
        select StartTime, EndTime, ProdId from dbo.fnCMN_GetPSFromEvents(@UnitId, @StartTime, @EndTime) 
    end
  else
    begin
      insert into @RunTimes (StartTime, EndTime, ProdId)
        Select Start_Time, End_Time, prod_id
          from Production_Starts
          where PU_Id = @UnitId and 
                ((End_Time between @StartTime and @EndTime) or
                 (Start_Time between @StartTime and @EndTime) or
                 (Start_Time <= @StartTime AND (End_Time > @EndTime OR End_Time is null)))
      UPDATE @RunTimes SET StartTime = @StartTime WHERE StartTime < @StartTime
      UPDATE @RunTimes SET EndTime   = @EndTime   WHERE EndTime > @EndTime OR EndTime IS NULL
    end
  RETURN
END

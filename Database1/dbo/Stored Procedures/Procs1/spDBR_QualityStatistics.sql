CREATE Procedure dbo.spDBR_QualityStatistics
@Variable int = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@FilterNonProductiveTime int = 0,
@ProductFilter text = NULL,
@Mode    int = 1,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
set arithignore on
set arithabort off
set ansi_warnings off
--*****************************************************/
--Find Productive Times
--*****************************************************/
create table #ProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)
create table #Products (
  [Product Name] varchar(100) null,
  Item1 int,
  Item2 int
)
Create Table #ProductChanges (
  ProductName varchar(100),
  ProductId int,
  StartTime datetime,
  EndTime datetime,
) 
Create Table #OrderedProductChanges (
  ProductName varchar(100),
  ProductId int,
  StartTime datetime,
  EndTime datetime,
) 
Create Table #Report (
  Average real NULL,
  StandardDeviation real NULL,
  InRejectLow real NULL,
  InWarningLow real NULL,
  InTarget real NULL,
  InWarningHigh real NULL,
  InRejectHigh real NULL,
  NumberSamples int NULL,
  NumberTested int NULL,
  StandardDeviationTarget real NULL,
  StandardDeviationMean real NULL,
  CoefficientVariationTarget real NULL,
  CoefficientVariationMean real NULL,
) 
Create Table #Data (
  Value real NULL, 
  IsTested int,
  LRL varchar(25) NULL,
  LWL varchar(25) NULL,
  Target varchar(25) NULL,
  UWL varchar(25) NULL,
  URL varchar(25) NULL,
  LimitIdentity varchar(150) NULL,
  InRejectLow int,
  InWarningLow int,
  InTarget int,
  InWarningHigh int,
  InRejectHigh int,
  TargetDeviation real NULL
)
create table #QualityStatistics
(
 	 ColumnName varchar(50),
 	 ColumnValue varchar(50)
)
Declare @MasterUnit int
Declare @DataType int
declare @Text nvarchar(4000)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @ProductFilter like '%<Root></Root>%' and not @ProductFilter is NULL)
  begin
   if (not @ProductFilter like '%<Root>%')
    begin
      select @Text = N'Item1,Item2;' + Convert(nvarchar(4000), @ProductFilter)
      Insert Into #Products (Item1,Item2) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Products EXECUTE spDBR_Prepare_Table @ProductFilter
    end
  end
declare @UnitId int
select @UnitId = pu_id from variables where var_id = @Variable
if (@FilterNonProductiveTime = 1)
begin
 	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @UnitId, @StartTime, @EndTime
end
else
begin
 	 insert into #ProductiveTimes (StartTime, EndTime) select @StartTime, @EndTime
end
--*****************************************************/
--Define Productive Time Cursor
--*****************************************************/
declare @curStartTime datetime, @curEndTime datetime
if (@Mode = 2)
begin
Declare TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select StartTime, EndTime From #ProductiveTimes
      )
  For Read Only
--*****************************************************/
--Fillin Product Run Times
--*****************************************************/
  Open TIME_CURSOR  
BEGIN_TIME_CURSOR:
Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
   Insert Into #ProductChanges (ProductName, ProductId, StartTime, EndTime)
      Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @curStartTime Then @curStartTime Else d.Start_Time End,
             Case When coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getUTCdate())) > @curEndTime Then @curEndTime Else coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getUTCdate())) End
        From Production_Starts d, Products b
    	  	   Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	   	  	       d.Start_Time = (Select Max(t.Start_Time) From Production_Starts t Where t.PU_Id = @UnitId and t.start_time < @curStartTime) and
 	  	   	       ((d.End_Time > @curStartTime) or (d.End_Time is Null))
       Union
        Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @curStartTime Then @curStartTime Else d.Start_Time End,
             Case When coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getUTCdate())) > @curEndTime Then @curEndTime Else coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getUTCdate())) End
        From Production_Starts d, Products b
 	  	     Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	           d.Start_Time >= @curStartTime and 
 	  	          	 d.Start_Time < @curEndTime 
     GOTO BEGIN_TIME_CURSOR
End
Close TIME_CURSOR
Deallocate TIME_CURSOR
insert into #ProductChanges (StartTime, ProductName, ProductId, EndTime) select  distinct(effective_date), productname, productid, endtime from #ProductChanges, var_specs where var_id = @Variable and effective_date between starttime and endtime
update #ProductChanges set endtime = dateadd(s, -1, effective_Date) from var_specs where var_id = @Variable and dateadd(s, -1, effective_Date) between starttime and endtime
if (not @ProductFilter is NULL)
delete from #ProductChanges where ProductId not in (select Item1 from #Products)
end
else
begin
insert into #ProductChanges(StartTime, EndTime) select starttime, endtime from #ProductiveTimes
update #ProductChanges set productname = 'Weighted Average', productid = -1
end
--*****************************************************/
--Return ResultSet 1, ProductRunInfo
--*****************************************************/
if (@Mode =1)
begin
 	 insert into #OrderedProductChanges (ProductName, ProductId, StartTime, EndTime) select 'Weighted Average', -1, min(StartTime), max(EndTime) from #ProductChanges
end
else
begin
 	 insert into #OrderedProductChanges select * from #ProductChanges order by StartTime desc
end
select var_desc as [ReportTitle] from variables where var_id = @Variable
---23/08/2010 - Update datetime formate in UTC into #OrderedProductChanges table
--Update #OrderedProductChanges Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
-- 	  	  	  	  	  	  	  	   EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone)
select ProductName,ProductId,'StartTime' = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone)  ,'EndTime'=   dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone)   from #OrderedProductChanges
--*****************************************************/
--Define Product Run Cursor
--*****************************************************/
declare @curProductId int
Declare PRODUCT_RUN_CURSOR INSENSITIVE CURSOR
  For (
     Select ProductId, StartTime, EndTime From #OrderedProductChanges
      )
  For Read Only
--*****************************************************/
--Variables to contain Return Values
--*****************************************************/
Declare @CpKTitle varchar(25)
Declare @CpKCount real
Declare @CpKColor varchar(10)
Declare @PpKTitle varchar(25)
Declare @PpKCount real
Declare @PpKColor varchar(10)
Declare @PpTitle varchar(25)
Declare @PpCount real
Declare @PpColor varchar(10)
Declare @CpTitle varchar(25)
Declare @CpCount real
Declare @CpColor varchar(10)
Declare @HighAlarmTitle varchar(25)
Declare @HighAlarmCount int
Declare @HighAlarmColor varchar(10)
Declare @MediumAlarmTitle varchar(25)
Declare @MediumAlarmCount int
Declare @MediumAlarmColor varchar(10)
Declare @LowAlarmTitle varchar(25)
Declare @LowAlarmCount int
Declare @LowAlarmColor varchar(10)
Declare @NumSamplesTitle varchar(25)
Declare @NumSamplesCount int
Declare @NumSamplesColor varchar(10)
Declare @PercentConformanceTitle varchar(25)
Declare @PercentConformanceCount real
Declare @PercentConformanceColor varchar(10)
Declare @PercentTargetDeviationTitle varchar(25)
Declare @PercentTargetDeviationCount real
Declare @PercentTargetDeviationColor varchar(10)
Declare @PercentSigmaTitle varchar(25)
Declare @PercentSigmaCount real
Declare @PercentSigmaColor varchar(10)
Declare @PercentTestedTitle varchar(25)
Declare @PercentTestedCount real
Declare @PercentTestedColor varchar(10)
--*****************************************************/
--Get Setup Information
--*****************************************************/
Declare @CPKWarningHigh real
Declare @CPKWarningLow real
Select @CPKWarningHigh = 1.33
Select @CPKWarningLow = 1.0
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
--*****************************************************/
--Prepare Titles
--*****************************************************/
Select @CpKTitle = dbo.fnDBTranslate(N'0', 38440, 'Cpk')
Select @PpKTitle = dbo.fnDBTranslate(N'0', 38497, 'Ppk')
Select @PpTitle = dbo.fnDBTranslate(N'0', 38498, 'Pp')
Select @CpTitle = dbo.fnDBTranslate(N'0', 38499, 'Cp')
Select @HighAlarmTitle = dbo.fnDBTranslate(N'0', 38436, 'High')
Select @MediumAlarmTitle = dbo.fnDBTranslate(N'0', 38437, 'Med')
Select @LowAlarmTitle = dbo.fnDBTranslate(N'0', 38438, 'Low')
Select @NumSamplesTitle = dbo.fnDBTranslate(N'0', 38496, '#Samples')
Select @PercentConformanceTitle = dbo.fnDBTranslate(N'0', 38439, '%Conf')
Select @PercentTargetDeviationTitle = dbo.fnDBTranslate(N'0', 38441, '%Dev')
Select @PercentSigmaTitle = dbo.fnDBTranslate(N'0', 38442, '%Sigma')
Select @PercentTestedTitle = dbo.fnDBTranslate(N'0', 38443, '%Test')
--*****************************************************/
--Define Colors
--*****************************************************/
Declare @TargetColor varchar(10)
Select @TargetColor = '#C0FFC0'
Declare @WarningColor varchar(10)
Select @WarningColor = '#C0C0FF'
Declare @LowColor varchar(10)
Select @LowColor = '#80FFFF'
Declare @RejectColor varchar(10)
Select @RejectColor =  '#FFC0C0'
Declare @InactiveColor varchar(10)
Select @InactiveColor = '#E0E0E0'
--*****************************************************/
--Collect Cpk, Ppk, Pp, and Cp  (Mode 1 only)
--*****************************************************/
if (@mode = 1)
begin
create table #Cpks (
Cp real,
Cpk real,
Pp real,
Ppk real
)
  select @CpkCount = null
  select @PpkCount = null
  select @PpCount = null
  select @CpCount = null
--select @StartTime, @EndTime, @Variable, @ProductFilter, @FilterNonProductiveTime
insert into #Cpks  exec spCMN_GetTimeWeightedCpks @StartTime, @EndTime, @Variable, @ProductFilter, @FilterNonProductiveTime
select @CpkCount = Cpk, @PpkCount = Ppk, @CpCount = Cp, @PpCount = Pp from #Cpks
drop table #Cpks
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  
end
select  @HighAlarmCount = 0
select  @MediumAlarmCount = 0
select  @LowAlarmCount = 0
--*****************************************************/
--Start Product Cursor
--*****************************************************/
Open PRODUCT_RUN_CURSOR
BEGIN_PRODUCT_RUN_CURSOR:
Fetch Next From PRODUCT_RUN_CURSOR Into @curProductId, @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
if (@curProductId = -1) select @curProductId = null
--*****************************************************/
--Collect Cpk, Ppk, Pp, and Cp  (Mode 2 only)
--*****************************************************/
if (@mode = 2)
begin
  select @CpkCount = null
  select @PpkCount = null
  select @PpCount = null
  select @CpCount = null
  select @CpkCount = Cpk, @PpkCount = Ppk, @CpCount = Cp, @PpCount = Pp from fnCMN_GetVariableStatistics(@curStartTime, @curEndTime, @Variable, @curProductId, null)
end
--*****************************************************/
--Collect Alarm Count Data
--*****************************************************/
declare @Varid varchar(25), @TempHighCount int, @TempMediumCount int, @TempLowCount int
select @VarId = convert(varchar(25),@Variable)
Select @TempHighCount = 0
Select @TempMediumCount = 0
Select @TempLowCount = 0
execute spCMN_GetVariableAlarmCounts
 	 @Varid,
 	 @curStartTime, 
 	 @curEndTime,
 	 @TempHighCount OUTPUT,
 	 @TempMediumCount OUTPUT,
 	 @TempLowCount OUTPUT,
  @curProductId
if (@Mode = 1)
begin
  select @HighAlarmCount =  @HighAlarmCount + @TempHighCount
  select @MediumAlarmCount =  @MediumAlarmCount + @TempMediumCount
  select @LowAlarmCount =  @LowAlarmCount + @TempLowCount
end
else
begin
  select @HighAlarmCount =  @TempHighCount
  select @MediumAlarmCount =  @TempMediumCount
  select @LowAlarmCount =  @TempLowCount
end
--*****************************************************/
--Collect Conformance Data And Statistics
--*****************************************************/
    Truncate Table #Data
    if (@Mode = 2) Truncate Table #Report
    Select @MasterUnit = Case When pu.Master_Unit Is Null Then pu.PU_Id Else pu.Master_Unit End,
           @DataType = v.Data_Type_Id
      From Variables v
      Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Where Var_Id = @Variable
    If @DataType not In (1,2,6,7) 
      begin
    Select @PercentConformanceCount = null, 
           @PercentTargetDeviationCount = null,
           @PercentSigmaCount = null, 
           @PercentTestedCount = null,
 	     	  	  	 @NumSamplesCount = null
      end
    else
      begin
        Insert Into #Data
          Select Value = convert(real,t.Result), 
             IsTested = Case When t.Result Is Null Then 0 Else 1 End, 
             LRL = vs.l_reject, LWL = vs.l_warning, Target = vs.Target, UWL = vs.u_warning, URL = vs.u_reject,
             LimitIdentity = coalesce(vs.l_reject, '*') + coalesce(vs.l_warning, '*') + coalesce(vs.target, '*')+ coalesce(vs.u_warning, '*')+ coalesce(vs.u_reject, '*'),
             InRejectLow = Case 
                             When @SpecificationSetting = 1 and convert(real,t.result) < convert(real,vs.l_reject) Then 1 
                             When @SpecificationSetting = 2 and convert(real,t.result) <= convert(real,vs.l_reject) Then 1 
                             Else 0 
                           End,
             InWarningLow = Case 
                              When @SpecificationSetting = 1 and convert(real,t.result) < convert(real,vs.l_warning) and not (convert(real,t.result) < convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 
                              When @SpecificationSetting = 2 and convert(real,t.result) <= convert(real,vs.l_warning) and not (convert(real,t.result) <= convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 
                              Else 0 
                            End,
             InTarget = 1, 
             InWarningHigh = Case 
                               When @SpecificationSetting = 1 and convert(real,t.result) >  convert(real,vs.u_warning) and not (convert(real,t.result) >  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 
                               When @SpecificationSetting = 2 and convert(real,t.result) >=  convert(real,vs.u_warning) and not (convert(real,t.result) >=  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 
                               Else 0 
                             End,
             InRejectHigh = Case 
                              When @SpecificationSetting = 1 and convert(real,t.result) >  convert(real,vs.u_reject) Then 1 
                              When @SpecificationSetting = 2 and convert(real,t.result) >=  convert(real,vs.u_reject) Then 1 
                              Else 0 
                            End,
             TargetDeviation = convert(real,t.Result) - convert(real,vs.Target)
          From Tests t 
          Join Production_Starts ps on ps.PU_Id = @MasterUnit and ps.Start_Time <= t.Result_On and (ps.End_Time > t.Result_On or ps.End_Time Is Null)
          join products p1 on p1.prod_id = ps.prod_id
 	  	  	  	  	 Left Outer Join Var_Specs vs on vs.Var_Id = @Variable and vs.Prod_Id = ps.Prod_Id and vs.effective_date <= t.result_on and (vs.Expiration_Date > t.Result_On or vs.Expiration_Date Is Null)
          Where t.Var_Id = @Variable and
            t.Result_On >= @curStartTime and 
            t.Result_On <= @curEndTime  and
 	  	  	  	  	  	 ((@CurProductId is null) or (p1.prod_id = @CurProductId))
        Insert Into #Report (Average, StandardDeviation, InRejectLow,InWarningLow,InTarget,InWarningHigh,InRejectHigh, NumberSamples,NumberTested,StandardDeviationTarget,StandardDeviationMean,CoefficientVariationTarget,CoefficientVariationMean)
          Select Average = avg(d.Value),
             StandardDeviation = stdev(d.Value),
             InRejectLow = sum(d.InRejectLow) / convert(real,Count(d.Value)) * 100.0,
             InWarningLow = sum(d.InWarningLow) / convert(real,Count(d.Value)) * 100.0,
             InTarget = (Count(d.Value) - sum(d.InRejectLow) - sum(d.InWarningLow) - sum(d.InWarningHigh) - sum(d.InRejectHigh)) / convert(real,Count(d.Value)) * 100.0,
             InWarningHigh = sum(d.InWarningHigh) / convert(real,Count(d.Value)) * 100.0,
             InRejectHigh= sum(d.InRejectHigh) / convert(real,Count(d.Value)) * 100.0,
             NumberSamples = count(d.IsTested),
             NumberTested = sum(d.IsTested),
             StandardDeviationTarget = stdev(d.TargetDeviation),
             StandardDeviationMean = stdev(d.Value),
             CoefficientVariationTarget = stdev(d.TargetDeviation) / min(convert(real,d.Target)) * 100.0,
             CoefficientVariationMean = stdev(d.Value) / avg(d.Value) * 100.0 
          From #Data d
          Group By d.LimitIdentity                              
    if (@Mode = 2)
    begin
      -- Summarize Statistics
      Select @PercentConformanceCount = sum(InTarget * NumberTested) / convert(real,sum(NumberTested)), 
             @PercentTargetDeviationCount = sum(CoefficientVariationTarget * NumberTested) / convert(real,sum(NumberTested)),
             @PercentSigmaCount = sum(StandardDeviation / Average * 100.0 * NumberTested) / convert(real,sum(NumberTested)), 
             @PercentTestedCount = sum(NumberTested) / convert(real,sum(NumberSamples)) * 100.0,
 	      @NumSamplesCount = sum(NumberSamples) 	 
        From #Report
 	  	  	 if (@NumSamplesCount is null)
 	  	  	 begin
 	  	  	  	 select @NumSamplesCount = 0
 	  	  	 end
    end
  end
--*****************************************************/
--Evaluate Colors  (Mode 2 Only)
--*****************************************************/
if (@Mode = 2)
begin
 	 If @HighAlarmCount > 0 
 	   Select @HighAlarmColor = @RejectColor 
 	 Else
 	   Select @HighAlarmColor = @TargetColor 
 	 
 	 If @MediumAlarmCount > 0 
 	   Select @MediumAlarmColor = @WarningColor 
 	 Else
 	   Select @MediumAlarmColor = @TargetColor 
 	 
 	 If @LowAlarmCount > 0 
 	   Select @LowAlarmColor = @LowColor 
 	 Else
 	   Select @LowAlarmColor = @TargetColor 
 	 If @NumSamplesCount > 0 
 	   Select @NumSamplesColor = @TargetColor 
 	 Else
 	   Select @NumSamplesColor = @LowColor 
 	 
 	 If @PercentConformanceCount < 70 
 	   Select @PercentConformanceColor = @RejectColor
 	 Else If @PercentConformanceCount < 90
 	   Select @PercentConformanceColor = @WarningColor
 	 Else
 	   Select @PercentConformanceColor = @TargetColor
 	 
 	 If @CPKCount < @CPKWarningLow
 	   Select @CpKColor = @RejectColor
 	 Else If ((@CPKCount > @CPKWarningLow) or (@CPKCount = @CPKWarningLow)) and ((@CPKCount < @CPKWarningHigh) or (@CPKCount = @CPKWarningHigh))
 	   Select @CpKColor = @WarningColor
 	 Else if @CpkCount > @CpkWarningHigh
 	   Select @CpKColor = @TargetColor
  else
 	   Select @CpKColor = @InactiveColor
 	 
 	 If @CpCount < @CPkWarningLow
 	   Select @CpColor = @RejectColor
 	 Else If ((@CPCount > @CPKWarningLow) or (@CPCount = @CPKWarningLow)) and ((@CPCount < @CPKWarningHigh) or (@CPCount = @CPKWarningHigh))
 	   Select @CpColor = @WarningColor
 	 Else if @CpCount > @CpkWarningHigh
 	   Select @CpColor = @TargetColor
  else
 	   Select @CpColor = @InactiveColor
 	 If @PPKCount < @CPKWarningLow
 	   Select @PpKColor = @RejectColor
 	 Else If ((@PPKCount > @CPKWarningLow) or (@PPKCount = @CPKWarningLow)) and ((@PPKCount < @CPKWarningHigh) or (@PPKCount = @CPKWarningHigh))
 	   Select @PpKColor = @WarningColor
 	 Else if @PpkCount > @CpkWarningHigh
 	   Select @PpKColor = @TargetColor
  else
 	   Select @PpKColor = @InactiveColor
 	 If @PPCount < @CPKWarningLow
 	   Select @PpColor = @RejectColor
 	 Else If ((@PPCount > @CPKWarningLow) or (@PPCount = @CPKWarningLow)) and ((@PPCount < @CPKWarningHigh) or (@PPCount = @CPKWarningHigh))
 	   Select @PpColor = @WarningColor
 	 Else if @PpCount > @CpkWarningHigh
 	   Select @PpColor = @TargetColor
  else
 	   Select @PpColor = @InactiveColor
 	 
 	 If @PercentTargetDeviationCount > 30 
 	   Select @PercentTargetDeviationColor = @RejectColor
 	 Else If @PercentTargetDeviationCount > 10
 	   Select @PercentTargetDeviationColor = @WarningColor
 	 Else
 	   Select @PercentTargetDeviationColor = @TargetColor
 	 
 	 
 	 If @PercentSigmaCount > 20 
 	   Select @PercentSigmaColor = @RejectColor
 	 Else If @PercentSigmaCount > 10
 	   Select @PercentSigmaColor = @WarningColor
 	 Else
 	   Select @PercentSigmaColor = @TargetColor
 	 
 	 
 	 
 	 If @PercentTestedCount < 80 
 	   Select @PercentTestedColor = @RejectColor
 	 Else If @PercentTestedCount < 95
 	   Select @PercentTestedColor = @WarningColor
 	 Else
 	   Select @PercentTestedColor = @TargetColor
end
--*****************************************************/
--Return Data  (Mode 2 only--one resultset for each product)
--*****************************************************/
if (@Mode = 2)
begin
 	 truncate table #QualityStatistics
 	 
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpKTitle',@CpKTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpKCount',coalesce(@CpkCount, convert(varchar(10), convert(decimal(10,2), @CpKCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpKColor',@CpKColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpTitle',@CpTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpCount',coalesce(@CpCount, convert(varchar(10), convert(decimal(10,2), @CpCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpColor',@CpColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpKTitle',@PpKTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpKCount',coalesce(@PpkCount, convert(varchar(10), convert(decimal(10,2), @PpKCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpKColor',@PpKColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpTitle',@PpTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpCount',coalesce(@PpCount, convert(varchar(10), convert(decimal(10,2), @PpCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpColor',@PpColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('HighAlarmTitle',@HighAlarmTitle) --'H Alarm')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('HighAlarmCount',convert(varchar(10), @HighAlarmCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('HighAlarmColor',@HighAlarmColor) --'#ff0000')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('MediumAlarmTitle',@MediumAlarmTitle) --'M Alarm')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('MediumAlarmCount',convert(varchar(10), @MediumAlarmCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('MediumAlarmColor',@MediumAlarmColor) --'#0000ff')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('LowAlarmTitle',@LowAlarmTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('LowAlarmCount',convert(varchar(10), @LowAlarmCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('LowAlarmColor',@LowAlarmColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('NumSamplesTitle',@NumSamplesTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('NumSamplesCount',convert(varchar(10), @NumSamplesCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('NumSamplesColor',@NumSamplesColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentConformanceTitle',@PercentConformanceTitle) --'% Conf')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentConformanceCount',coalesce(@PercentConformanceCount, convert(varchar(10), convert(decimal(10,1), @PercentConformanceCount)), 0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentConformanceColor',@PercentConformanceColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTargetDeviationTitle',@PercentTargetDeviationTitle) --'% Dev')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTargetDeviationCount',coalesce(@PercentTargetDeviationCount, convert(varchar(10), convert(decimal(10,1), @PercentTargetDeviationCount)), 0)) 
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTargetDeviationColor',@PercentTargetDeviationColor) --'#0000ff')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentSigmaTitle',@PercentSigmaTitle) --'% Sigma')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentSigmaCount',coalesce(@PercentSigmaCount, convert(varchar(10), convert(decimal(10,1), @PercentSigmaCount)), 0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentSigmaColor',@PercentSigmaColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTestedTitle',@PercentTestedTitle) --'% Test')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTestedCount',coalesce(@PercentTestedCount, convert(varchar(10), convert(decimal(10,1), @PercentTestedCount)), 0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTestedColor',@PercentTestedColor) --'#aaaaaa')
 	 
 	 select * from #QualityStatistics
end
     GOTO BEGIN_PRODUCT_RUN_CURSOR
End
Close PRODUCT_RUN_CURSOR
Deallocate PRODUCT_RUN_CURSOR
--*****************************************************/
--End Product Cursor (above)
--*****************************************************/
    if (@Mode = 1)
    begin
 	  	  	 --*****************************************************/
 	  	  	 --Summarize Statistics  (Mode 1 Only)
 	  	  	 --*****************************************************/
      Select @PercentConformanceCount = sum(InTarget * NumberTested) / convert(real,sum(NumberTested)), 
             @PercentTargetDeviationCount = sum(CoefficientVariationTarget * NumberTested) / convert(real,sum(NumberTested)),
             @PercentSigmaCount = sum(StandardDeviation / Average * 100.0 * NumberTested) / convert(real,sum(NumberTested)), 
             @PercentTestedCount = sum(NumberTested) / convert(real,sum(NumberSamples)) * 100.0,
  	       	  	  	  @NumSamplesCount = sum(NumberSamples) 	 
        From #Report
 	  	  	  	 --*****************************************************/
 	  	  	  	 --Evaluate Colors  (Mode 1 Only)
 	  	  	  	 --*****************************************************/
 	  	  	  	 If @HighAlarmCount > 0 
 	  	  	  	   Select @HighAlarmColor = @RejectColor 
 	  	  	  	 Else
 	  	  	  	   Select @HighAlarmColor = @TargetColor 
 	  	  	  	 
 	  	  	  	 If @MediumAlarmCount > 0 
 	  	  	  	   Select @MediumAlarmColor = @WarningColor 
 	  	  	  	 Else
 	  	  	  	   Select @MediumAlarmColor = @TargetColor 
 	  	  	  	 
 	  	  	  	 If @LowAlarmCount > 0 
 	  	  	  	   Select @LowAlarmColor = @LowColor 
 	  	  	  	 Else
 	  	  	  	   Select @LowAlarmColor = @TargetColor 
 	  	  	  	 
 	  	  	  	 If @NumSamplesCount > 0 
 	  	  	  	   Select @NumSamplesColor = @TargetColor 
 	  	  	  	 Else
 	  	  	  	   Select @NumSamplesColor = @LowColor 
 	 
 	  	  	  	 If @PercentConformanceCount < 70 
 	  	  	  	   Select @PercentConformanceColor = @RejectColor
 	  	  	  	 Else If @PercentConformanceCount < 90
 	  	  	  	   Select @PercentConformanceColor = @WarningColor
 	  	  	  	 Else
 	  	  	  	   Select @PercentConformanceColor = @TargetColor
 	  	  	  	 
 	 If @CPKCount < @CPKWarningLow
 	   Select @CpKColor = @RejectColor
 	 Else If (@CPKCount > @CPKWarningLow) or (@CPKCount = @CPKWarningLow) or (@CPKCount < @CPKWarningHigh) or (@CPKCount = @CPKWarningHigh)
 	   Select @CpKColor = @WarningColor
 	 Else if @CpkCount > @CpkWarningHigh
 	   Select @CpKColor = @TargetColor
  else
 	   Select @CpKColor = @InactiveColor
 	 
 	 If @CpCount < @CPkWarningLow
 	   Select @CpColor = @RejectColor
 	 Else If (@CPCount > @CPKWarningLow) or (@CPCount = @CPKWarningLow) or (@CPCount < @CPKWarningHigh) or (@CPCount = @CPKWarningHigh)
 	   Select @CpColor = @WarningColor
 	 Else if @CpCount > @CpkWarningHigh
 	   Select @CpColor = @TargetColor
  else
 	   Select @CpColor = @InactiveColor
 	 If @PPKCount < @CPKWarningLow
 	   Select @PpKColor = @RejectColor
 	 Else If (@PPKCount > @CPKWarningLow) or (@PPKCount = @CPKWarningLow) or (@PPKCount < @CPKWarningHigh) or (@PPKCount = @CPKWarningHigh)
 	   Select @PpKColor = @WarningColor
 	 Else if @PpkCount > @CpkWarningHigh
 	   Select @PpKColor = @TargetColor
  else
 	   Select @PpKColor = @InactiveColor
 	 If @PPCount < @CPKWarningLow
 	   Select @PpColor = @RejectColor
 	 Else If (@PPCount > @CPKWarningLow) or (@PPCount = @CPKWarningLow) or (@PPCount < @CPKWarningHigh) or (@PPCount = @CPKWarningHigh)
 	   Select @PpColor = @WarningColor
 	 Else if @PpCount > @CpkWarningHigh
 	   Select @PpColor = @TargetColor
  else
 	   Select @PpColor = @InactiveColor
 	  	  	  	  	 
 	  	  	  	 If @PercentTargetDeviationCount > 30 
 	  	  	  	   Select @PercentTargetDeviationColor = @RejectColor
 	  	  	  	 Else If @PercentTargetDeviationCount > 10
 	  	  	  	   Select @PercentTargetDeviationColor = @WarningColor
 	  	  	  	 Else
 	  	  	  	   Select @PercentTargetDeviationColor = @TargetColor
 	  	  	  	 
 	  	  	  	 
 	  	  	  	 If @PercentSigmaCount > 20 
 	  	  	  	   Select @PercentSigmaColor = @RejectColor
 	  	  	  	 Else If @PercentSigmaCount > 10
 	  	  	  	   Select @PercentSigmaColor = @WarningColor
 	  	  	  	 Else
 	  	  	  	   Select @PercentSigmaColor = @TargetColor
 	  	  	  	 
 	  	  	  	 
 	  	  	  	 
 	  	  	  	 If @PercentTestedCount < 80 
 	  	  	  	   Select @PercentTestedColor = @RejectColor
 	  	  	  	 Else If @PercentTestedCount < 95
 	  	  	  	   Select @PercentTestedColor = @WarningColor
 	  	  	  	 Else
 	  	  	  	   Select @PercentTestedColor = @TargetColor
 	  	  	  	 --*****************************************************/
 	  	  	  	 --Return Data  (Mode 1 return averages for all statistics
 	  	  	  	 --*****************************************************/
 	  	  	  	  	 truncate table #QualityStatistics
 	  	  	  	  	 
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpKTitle',@CpKTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpKCount',coalesce(@CpkCount, convert(varchar(10), convert(decimal(10,2), @CpKCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpKColor',@CpKColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpTitle',@CpTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpCount',coalesce(@CpCount, convert(varchar(10), convert(decimal(10,2), @CpCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('CpColor',@CpColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpKTitle',@PpKTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpKCount',coalesce(@PpkCount, convert(varchar(10), convert(decimal(10,2), @PpKCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpKColor',@PpKColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpTitle',@PpTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpCount',coalesce(@PpCount, convert(varchar(10), convert(decimal(10,2), @PpCount)),0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PpColor',@PpColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('HighAlarmTitle',@HighAlarmTitle) --'H Alarm')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('HighAlarmCount',convert(varchar(10), @HighAlarmCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('HighAlarmColor',@HighAlarmColor) --'#ff0000')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('MediumAlarmTitle',@MediumAlarmTitle) --'M Alarm')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('MediumAlarmCount',convert(varchar(10), @MediumAlarmCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('MediumAlarmColor',@MediumAlarmColor) --'#0000ff')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('LowAlarmTitle',@LowAlarmTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('LowAlarmCount',convert(varchar(10), @LowAlarmCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('LowAlarmColor',@LowAlarmColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('NumSamplesTitle',@NumSamplesTitle)
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('NumSamplesCount',convert(varchar(10), @NumSamplesCount))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('NumSamplesColor',@NumSamplesColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentConformanceTitle',@PercentConformanceTitle) --'% Conf')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentConformanceCount',coalesce(@PercentConformanceCount, convert(varchar(10), convert(decimal(10,1), @PercentConformanceCount)), 0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentConformanceColor',@PercentConformanceColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTargetDeviationTitle',@PercentTargetDeviationTitle) --'% Dev')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTargetDeviationCount',coalesce(@PercentTargetDeviationCount, convert(varchar(10), convert(decimal(10,1), @PercentTargetDeviationCount)), 0)) 
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTargetDeviationColor',@PercentTargetDeviationColor) --'#0000ff')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentSigmaTitle',@PercentSigmaTitle) --'% Sigma')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentSigmaCount',coalesce(@PercentSigmaCount, convert(varchar(10), convert(decimal(10,1), @PercentSigmaCount)), 0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentSigmaColor',@PercentSigmaColor) --'#aaaaaa')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTestedTitle',@PercentTestedTitle) --'% Test')
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTestedCount',coalesce(@PercentTestedCount, convert(varchar(10), convert(decimal(10,1), @PercentTestedCount)), 0))
 	  	  	  	  	 insert into #QualityStatistics (ColumnName, ColumnValue) values('PercentTestedColor',@PercentTestedColor) --'#aaaaaa')
 	  	  	  	  	 
 	  	  	  	  	 select * from #QualityStatistics
    end
Drop Table #Data
Drop Table #Report
drop table #QualityStatistics

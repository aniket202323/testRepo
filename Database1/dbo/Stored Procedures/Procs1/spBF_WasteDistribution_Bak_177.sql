CREATE Procedure [dbo].[spBF_WasteDistribution_Bak_177]
@UnitList text = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@FilterNonProductiveTime int = 0,
@ProductFilter int = null,
@CrewFilter nvarchar(10) = null,
@LocationFilter int = NULL,
@FaultFilter nVarChar(100) = NULL,
@ReasonFilter1 int = NULL,
@ReasonFilter2 int = NULL,
@ReasonFilter3 int = NULL,
@ReasonFilter4 int = NULL,
@ShowTopNBars int = 20,
@InTimeZone  	    	  nVarChar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time',
,@CalculateOthersQualityDistribution BIT = 1
AS
Begin
if @UnitList is not null 
begin 
DECLARE @Units Table (PUId 	 Int)
DECLARE @tempUnitName nVarChar(max)
Declare @TimeOption int  = NULL
DECLARE @xml XML
SET @xml = cast(('<X>'+replace(cast(@UnitList as nvarchar(max)),';','</X><X>')+'</X>') as xml)
INSERT INTO @Units(PUId)
--SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,';')
SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
IF Not EXists(Select 1 FROM @Units) -- Unit Not Found
BEGIN
 	  	 RETURN -999
END
SELECT @tempUnitName = COALESCE(@tempUnitName+';' ,'') + convert(nVarChar(10), PUId)
FROM @Units
where Puid in (select PU_Id  from Prod_Events where Event_Type=3)
end 
if @tempUnitName is Null and  @UnitList is not null
begin
Set @tempUnitName = '' 
end 
--EXECUTE dbo.spDBR_WasteDistribution @tempUnitName,@StartTime,@EndTime,@FilterNonProductiveTime,@ProductFilter,@CrewFilter,@LocationFilter , @FaultFilter,@ReasonFilter1,
--@ReasonFilter2,@ReasonFilter3,@ReasonFilter4,@ShowTopNBars,@InTimeZone 
Declare @ShiftFilter nvarchar(10), @IsProRated bit
Select @IsProRated = 0
Declare @Level1Name nvarchar(100), @Level2Name nvarchar(100), @Level3Name nvarchar(100), @Level4Name nvarchar(100), @DimXUnits nvarchar(25)
Declare @Text nVarChar(max), @TotalWaste FLOAT, @TotalProduction REAL
Declare @Unspecified nvarchar(20)
declare @UnitTotalsTable Table(PU_Id int, TotalProduction float, TotalWaste float)
declare @UnitWasteTable Table(PU_ID int, TotalWaste float)
Select  @Unspecified = '<' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '>'
If @FilterNonProductiveTime Is Null Select @FilterNonProductiveTime=0
Declare @TimeFilterTable TABLE(PU_Id int, StartTime datetime, EndTime datetime, Crew_Desc nvarchar(15), Shift_Desc nvarchar(15), Prod_Id int)
Declare @Crew_Schedule TABLE(PU_Id int, Start_Time datetime, End_Time datetime, Crew_Desc nvarchar(15), Shift_Desc nvarchar(15))
-------------------------------------------------------------
-- Get Translations
-------------------------------------------------------------
Declare @sFault nvarchar(20), @sTotal nvarchar(20), @sMAPE nvarchar(20), @sMABE nvarchar(20),@sNumEvents nvarchar(20), @sPerTotal nvarchar(20)
Select @sFault = dbo.fnDBTranslate(N'0', 38336, 'Fault')
Select @sTotal = dbo.fnDBTranslate(N'0', 38340, 'Total')
Select @sMAPE = dbo.fnDBTranslate(N'0', 38488, 'MAPE')
Select @sMABE = dbo.fnDBTranslate(N'0', 38489, 'MABE')
Select @sNumEvents = dbo.fnDBTranslate(N'0', 38344, '# Events')
Select @sPerTotal = dbo.fnDBTranslate(N'0', 38343, '% Total')
-------------------------------------------------------------
-- Build List of Units
-------------------------------------------------------------
create table #Units
(
 	 Item  	  	 int,
 	 UnitName  	 nvarchar(100),
 	 LineId  	  	 int,
 	 LineName 	 nvarchar(100),
 	 TreeId 	  	 int,
 	 Level1Name 	 nvarchar(100),
 	 Level2Name 	 nvarchar(100),
 	 Level3Name 	 nvarchar(100),
 	 Level4Name 	 nvarchar(100),
 	 FaultId 	  	 int,
 	 DimXUnits 	 nvarchar(25)
 	 ,OEEMode nvarchar(20)
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 /*Time Options are also need to consider */
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description nvarchar(50), Start_Time datetime, End_Time datetime)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 --SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 --SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 IF(@StartTime) IS NOT NULL AND (@EndTime) IS NOT NULL
BEGIN
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE IF (@TimeOption) IS NOT NULL
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions @TimeOption,@InTimeZone
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	  	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions 30,@InTimeZone -- Default to Today if no start time and end time is provided
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions 	 
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END 
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
 	  	 begin
  	    	    select @Text = N'Item;' + Convert(nVarChar(4000), @UnitList)
  	    	    Insert Into #Units (Item) --EXECUTE spDBR_Prepare_Table @Text
 	  	    Select col1 from dbo.fn_SplitString(@UnitList,';');
  	    	  end
    else
  	    	  begin
  	    	    insert into #Units (LineName, LineId, UnitName, Item) --EXECUTE spDBR_Prepare_Table @UnitList
 	  	    Select NULL,NULL,NULL,col1 from dbo.fn_SplitString(@UnitList,';');
  	    	  end
  end
Else
  Begin
    Insert Into #Units (Item) 
      Select distinct pu_id From prod_events where event_type = 3
  End
--Exclude Units
;WITH NotConfiguredUnits As
 	  	 (
 	  	  	 Select 
  	    	    	    	  Pu.Pu_Id from Prod_Units_Base Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
Delete U 
FROM 
 	 #Units U 
WHERE EXISTS (SELECT 1 FROM NotConfiguredUnits Where PU_Id = U.Item)
;WITH S As 
(
Select 
       TFV.KeyID UnitId, EDFTV.Field_desc
From 
       Table_Fields TF
       JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
       Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
       LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
Where 
       TF.Table_Field_Desc = 'OEE Calculation Type'
)
Update u
SET
 	 u.OEEMode = Isnull(S.Field_desc,'Classic')
From 
 	 #Units u
 	 Left Outer Join S on S.UnitId = u.Item
-----------------------------------------------------------
-- Get Unit & Line Name, Reason and Fault Info
-------------------------------------------------------------
Update U SET
 	 UnitName = PU_Desc,
 	 LineId = p.PL_ID,
 	 LineName = PL_Desc,
 	 TreeId = PE.Name_Id
  	  From Prod_Units_bAse p 
 	 Join #Units U on U.Item = P.PU_Id
  	  Join Prod_Lines_Base PL on PL.PL_ID = p.PL_ID
 	 Join Prod_Events PE on PE.PU_ID = U.Item 
 	 /*Modified to handle for Time based units with out waste event configured*/
  	  and ((PE.Event_Type = 3 AND U.OEEMode <> 'Time Based') OR  (U.OEEMode = 'Time Based' ))
 	 
-- Get Reason Level Stuff
Update U SET
 	 U.Level1Name = Level_Name
 	 From Event_Reason_Level_Headers EH
 	 Join #Units U on U.TreeId = EH.Tree_Name_Id and EH.Reason_Level=1
Update U SET
 	 U.Level2Name = Level_Name
 	 From Event_Reason_Level_Headers EH
 	 Join #Units U on U.TreeId = EH.Tree_Name_Id and EH.Reason_Level=2
Update U SET
 	 U.Level3Name = Level_Name
 	 From Event_Reason_Level_Headers EH
 	 Join #Units U on U.TreeId = EH.Tree_Name_Id and EH.Reason_Level=3
Update U SET
 	 U.Level4Name = Level_Name
 	 From Event_Reason_Level_Headers EH
 	 Join #Units U on U.TreeId = EH.Tree_Name_Id and EH.Reason_Level=4
 	 
-- Get Reason Levels
Select @Level1Name=Level1Name, @Level2Name=Level2Name, @Level3Name=Level3Name, @Level4Name=Level4Name, @DimXUnits=DimXUnits
From #Units
SELECT Top 1 @Level1Name=Level1Name From #Units Where Level1Name IS NOT NULL
SELECT Top 1 @Level2Name=Level2Name From #Units Where Level2Name IS NOT NULL
SELECT Top 1 @Level3Name=Level3Name From #Units Where Level3Name IS NOT NULL
SELECT Top 1 @Level4Name=Level4Name From #Units Where Level4Name IS NOT NULL
-- Get Engineering Units
Update U SET
 	 U.DimXUnits = s.Dimension_X_Eng_Units
 	 From event_configuration E
 	 Join #Units U on U.Item = E.pu_id
 	 Join Event_SubTypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
-- Update Fault Filter
if @FaultFilter Is Not Null
 	 Update U SET
 	  	 U.FaultId = WEF.WEFault_Id
 	  	 From Waste_Event_Fault WEF
 	  	 Join #Units U on U.Item = WEF.PU_ID
 	  	 Where WEFault_Name = @FaultFilter
--------------------------------------------------
-- Return Header Result Set
--------------------------------------------------
Declare @Resultsets TABLE(
  ResultSetName  	 nvarchar(50),
  ResultSetTabName  	 nvarchar(50),
  ParameterName  	 nvarchar(50),
  ParameterUnits  	 nvarchar(50),
  DataColumns     	 nvarchar(50),
  LabelColumns    	 nvarchar(50),
  IconDesc 	   	  	 nvarchar(1000),
  RS_ID  	  	  	 int  
)
If @IsProrated = 0
 	 insert into @ResultSets values (null, dbo.fnDBTranslate(N'0', 38449, 'Waste Distribution'), 'brown', NULL, NULL, NULL, NULL, NULL)
Else
 	 insert into @Resultsets values (null, dbo.fnDBTranslate(N'0', 38504, 'Quality Distribution'), 'brown', NULL, NULL, NULL, NULL, NULL)
If @LocationFilter Is Null
  insert into @Resultsets values ('LocationPareto', dbo.fnDBTranslate(N'0', 38335, 'Location'), '38246', coalesce(@DimXUnits, dbo.fnDBTranslate(N'0', 38129, 'Units')), '2','1',NULL, 1)
If @FaultFilter Is Null
  insert into @Resultsets values ('FaultPareto', dbo.fnDBTranslate(N'0', 38336, 'Fault'), '38247', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),'2','1',NULL,  2)
If @ReasonFilter1 Is Null and @Level1Name Is Not Null
  insert into @Resultsets values ('Reason1Pareto', @Level1Name, '38248', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),'2','1',NULL,  3)
If @ReasonFilter2 Is Null and @Level2Name Is Not Null
  insert into @Resultsets values ('Reason2Pareto', @Level2Name, '38249', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')), '2','1',NULL, 4)
If @ReasonFilter3 Is Null and @Level3Name Is Not Null
  insert into @Resultsets values ('Reason3Pareto', @Level3Name, '38250', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),'2','1',NULL,  5)
If @ReasonFilter4 Is Null and @Level4Name Is Not Null
  insert into @Resultsets values ('Reason4Pareto', @Level4Name, '38251', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),'2','1',NULL,  6)
If @ProductFilter Is Null
  insert into @Resultsets values ('ProductPareto', dbo.fnDBTranslate(N'0', 38337, 'Product'), '38244', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),'2','1',NULL,  7)
If @CrewFilter Is Null
  insert into @Resultsets values ('CrewPareto',dbo.fnDBTranslate(N'0', 38338, 'Crew'), '38245', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')), '2','1',NULL, 8)
If @ShiftFilter Is Null
  insert into @Resultsets values ('ShiftPareto',dbo.fnDBTranslate(N'0', 38479, 'Shift'), '38506', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')), '2','1',NULL, 9)
Select * From @Resultsets
----------------------------------------------------------------
-- New Local Production Starts Table Will Include Applied Product
----------------------------------------------------------------
DECLARE @Production_Starts TABLE (id int identity, Start_Time datetime, End_Time datetime, PU_ID int, Prod_Id int)
----------------------------------------------------------------
-- Get Productive Times
----------------------------------------------------------------
Create Table #ProductiveTimes(RowId int identity(1,1), PU_Id int, StartTime datetime, EndTime datetime, Crew_Desc nvarchar(15), Shift_Desc nvarchar(15), Prod_Id int, TotalProduction Float,Production_Type int,Uses_Start_Time int,Production_Variable int)
declare @curPU_Id int
Declare UNIT_CURSOR Insensitive Cursor
 	 For ( Select Item From #Units )
 	 For Read Only 	 
 	 Open UNIT_CURSOR
 	 Fetch Next from UNIT_CURSOR Into @curPU_ID
 	 While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 insert into @Production_Starts(Start_Time, End_Time, Prod_Id, PU_ID)
 	  	  	 select StartTime, EndTime, ProductKey, @curPU_Id from dbo.fnCMN_SplitGradeChanges(@StartTime, @EndTime, @curPU_Id)
 	  	  	 If (@FilterNonProductiveTime = 1)
 	  	  	  	 Begin
 	  	  	  	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime, @EndTime
 	  	  	  	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #ProductiveTimes(PU_ID, StartTime, EndTime)
 	  	  	  	  	  	 Select @curPU_Id, @StartTime, @EndTime
 	  	  	  	 End
 	  	  	 Fetch Next from UNIT_CURSOR Into @curPU_ID
 	  	 End
 	 
Close UNIT_CURSOR
Deallocate UNIT_CURSOR
-----------------------------------------------
-- Get Crew Schedule
-- Fill in any incomplete Crew Schedule Rows
-----------------------------------------------
declare @RowId int, @curStartTime datetime, @curEndTime datetime
Declare CREW_SCHEDULE_CURSOR Insensitive Cursor
 	 For ( Select PU_ID, StartTime, EndTime From #ProductiveTimes )
 	 For Read Only 	 
 	 Open CREW_SCHEDULE_CURSOR
 	 Fetch Next from CREW_SCHEDULE_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
 	 While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 Insert Into @Crew_Schedule(PU_ID, Start_Time, End_Time, Crew_Desc, Shift_Desc)
 	  	  	 select PU_ID, Start_Time, End_Time, Crew_Desc, Shift_Desc From fnCMN_GetUnitCrewSchedule(@curPU_Id, @curStartTime, @curEndTime)
 	  	  	 Fetch Next from CREW_SCHEDULE_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
 	  	 End
Close CREW_SCHEDULE_CURSOR
Deallocate CREW_SCHEDULE_CURSOR
-----------------------------------------------
-- Apply Crew Filter
-- Only keep production times where this
-- crew was on duty
-----------------------------------------------
Delete From @TimeFilterTable
Insert into @TimeFilterTable(PU_ID, StartTime, EndTime, Crew_Desc, Shift_Desc)
Select
 	 o.PU_ID, 
 	 [Start_Time] = case when i.start_time > o.starttime then i.start_time else o.starttime end,
 	 [End_Time] = case when i.end_time < o.endtime then i.end_time else o.endtime end,
 	 i.Crew_Desc,
 	 i.Shift_Desc
From #ProductiveTimes o
Join @Crew_Schedule i on
 	  	 i.pu_id = o.pu_Id 
 	 AND i.Start_time < o.EndTime 
 	 AND i.end_time > o.StartTime 
 	 --AND (@CrewFilter Is Null or i.Crew_Desc = @CrewFilter)
 	 --AND (@ShiftFilter Is Null or i.Shift_Desc = @ShiftFilter)
 	 Order By i.Start_Time
If (Select Count(*) From @TimeFilterTable) = 0
 	 Begin
 	  	 -- No rows returned from Crew_Schedule Table
 	  	 Update #ProductiveTimes Set Crew_Desc =  dbo.fnDBTranslate(N'0', 38333, 'Unspecified') , Shift_Desc =  dbo.fnDBTranslate(N'0', 38333, 'Unspecified') 
 	 End
Else
 	 Begin
 	  	 Delete From #ProductiveTimes
 	  	 Insert Into #ProductiveTimes(PU_ID, StartTime, EndTime, Crew_Desc, Shift_Desc)
 	  	 Select PU_ID, StartTime, EndTime, Crew_Desc, Shift_Desc From @TimeFilterTable
 	 End
If @CrewFilter Is Not Null
 	 Delete From #ProductiveTimes where Crew_Desc <> @CrewFilter
If @ShiftFilter Is Not Null
 	 Delete From #ProductiveTimes where Shift_Desc <> @ShiftFilter
-----------------------------------------------
-- Apply Product Filter
-- Only keep production times where this
-- product was running
-----------------------------------------------
Delete From @TimeFilterTable
Insert into @TimeFilterTable(PU_ID, StartTime, EndTime, Crew_Desc, Shift_Desc, Prod_Id)
Select
 	 pt.PU_ID, 
 	 [Start_Time] = case when ps.start_time > pt.starttime then ps.start_time else pt.starttime end,
 	 [End_Time] = case when ps.end_time < pt.endtime then ps.end_time else pt.endtime end,
 	 Crew_Desc,
 	 Shift_Desc,
 	 ps.Prod_Id
From #ProductiveTimes pt
Join @Production_Starts ps on 
 	 ps.pu_id = pt.pu_Id 
 	 AND (@ProductFilter Is Null or ps.Prod_Id = @ProductFilter)
 	 AND pt.EndTime > ps.Start_Time
 	 AND ((pt.StartTime < ps.End_Time) or (ps.End_Time Is Null))
Delete From #ProductiveTimes
Insert Into #ProductiveTimes(PU_ID, StartTime, EndTime, Crew_Desc, Shift_Desc, Prod_Id)
Select PU_ID, StartTime, EndTime, Crew_Desc, Shift_Desc, Prod_Id From @TimeFilterTable
------------------------------------------------------------
-- Get Total Production By Unit, Crew & Product For Productive Time
------------------------------------------------------------
Declare UNIT_CURSOR Insensitive Cursor
 	 For ( Select RowId, PU_ID, StartTime, EndTime From #ProductiveTimes )
 	 For Read Only 	 
 	 Open UNIT_CURSOR
 	 Fetch Next from UNIT_CURSOR Into @RowId, @curPU_Id, @curStartTime, @curEndTime
 	 While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 Select @TotalProduction = 0.0
                        IF @CalculateOthersQualityDistribution = 1
                        Begin
 	  	  	    Select @TotalProduction = TotalProduction From dbo.fnCMN_GetProductionItemTotalsByUnit(@curStartTime, @curEndTime, @curPU_ID, 0)
                        END
 	  	  	 Update #ProductiveTimes Set TotalProduction = @TotalProduction Where RowId = @RowId
 	  	  	 Fetch Next from UNIT_CURSOR Into @RowId, @curPU_Id, @curStartTime, @curEndTime
 	  	 End
Close UNIT_CURSOR
Deallocate UNIT_CURSOR
 	  
UPDATE u
SET  	  
   	 u.Production_Type = pu.Production_Type,   	      	  
   	 u.Uses_Start_Time = pu.Uses_Start_Time,
 	 u.Production_Variable  = pu.Production_Variable
From
  	  #ProductiveTimes u
  	  join Prod_Units_Base pu on pu.PU_Id = u.Pu_Id 
UPDATE u
SET u.TotalProduction = (Select sum(convert(Float, Result)) From Tests Where Var_Id = u.Production_Variable AND Result_On >= u.StartTime AND Result_On < u.EndTime)
FROM 
 	 #ProductiveTimes u 
WHERE u.Production_Type = 1
UPDATE u 
SET u.TotalProduction = T.TotalProduction
FROM #ProductiveTimes u  JOIN 
(SELECT   	   s.pu_Id ,s.Prod_Id,s.StartTime,s.EndTime,
sum( CASE   	   WHEN e.Start_Time IS NOT NULL and 1=0 THEN
   	      	     convert(Float, datediff(s, CASE   	   WHEN e.Start_Time < s.StartTime THEN s.StartTime
   	      	      	      	      	      	      	      	      	      	     ELSE e.Start_Time
   	      	      	      	      	      	      	      	      	      	     END,
   	      	      	      	      	      	      	      	     CASE   	   WHEN e.TimeStamp > s.EndTime THEN s.EndTime
   	      	      	      	      	      	      	      	      	      	     ELSE e.TimeStamp
   	      	      	      	      	      	      	      	      	      	     END))
   	      	     / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <=0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
   	      	     * isnull(ed.Initial_Dimension_X,0)
   	     ELSE isnull(ed.Initial_Dimension_X,0)
   	     END) AS TotalProduction
FROM #ProductiveTimes s  	    	    	    	    	    	   
JOIN dbo.Events e WITH (NOLOCK) ON   	   s.PU_Id = e.PU_Id
   	      	      	      	      	      	     AND e.TimeStamp > s.StartTime
   	      	      	      	      	      	     AND isnull(e.Start_Time, e.TimeStamp) <= s.EndTime 
JOIN dbo.Production_Status ps WITH (NOLOCK) ON   	   e.Event_Status = ps.ProdStatus_Id
   	      	      	      	      	      	      	      	      	      	     AND ps.Count_For_Production = 1
Join dbo.Production_Starts PPS on PPS.PU_Id = e.PU_Id and e.TimeStamp>=pps.Start_Time   and ( e.TimeStamp < pps.End_Time   or pps.End_Time IS NULL)
LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
where  s.Uses_Start_Time = 1
AND s.Prod_Id = ISNULL(e.Applied_Product,PPS.Prod_Id)
GROUP BY s.PU_Id,s.Prod_Id,s.StartTime,s.EndTime) T ON T.PU_Id = u.PU_Id AND T.Prod_Id = u.Prod_Id and T.StartTime =u.StartTime and T.EndTime = u.EndTime
WHERE u.Uses_Start_Time = 1 and u.Production_Type <> 1
UPDATE u
SET u.TotalProduction =
(
SELECT   	  
 	 sum(ed.Initial_Dimension_X)  
FROM  
 	 dbo.Events e WITH (NOLOCK) 
 	 Join dbo.Production_Starts PPS on PPS.PU_Id = e.PU_Id and e.TimeStamp>=pps.Start_Time   and ( e.TimeStamp < pps.End_Time   or pps.End_Time IS NULL)
 	 JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
Where     	   
 	 u.PU_Id = e.PU_Id
 	 AND e.TimeStamp >= u.staRtTime
 	 AND e.TimeStamp < u.EndTime
 	 and ISNULL(e.Applied_Product,PPS.Prod_Id) = u.Prod_Id
)
FROM  
#ProductiveTimes u  
where  u.Uses_Start_Time <> 1 and u.Production_Type <> 1
-- Summarize all production by unit
Insert into @UnitTotalsTable(PU_Id, TotalProduction)
 	 Select PU_ID, Sum(TotalProduction)
 	 From #ProductiveTimes 
 	 Group By PU_Id
-- Get Total Production
Select @TotalProduction=Sum(TotalProduction) From #ProductiveTimes
Create Table #Events_With_StartTime (Event_Id int, Actual_Start_Time datetime, Timestamp datetime)
--------------------------------------------------------------------------------
-- If needed, cache in the Events_With_Starttime records to make query faster
--------------------------------------------------------------------------------
If @IsProrated <> 0
 	 Begin
 	 -- Get the bulk of the events for the overall time period
 	 insert into #Events_With_Starttime (Event_Id, Actual_Start_Time, Timestamp)
 	 select Event_Id, Actual_Start_Time, Timestamp
 	 from Events_With_Starttime e
 	 Join #Units U on u.Item = e.pu_Id
 	 where Timestamp < @EndTime and Timestamp > @StartTime
 	 -- Get the one final event past the end. That makes sure we get the one that overlaps the end
 	 insert into #Events_With_Starttime (Event_Id, Actual_Start_Time, Timestamp)
 	 select TOP 1 Event_Id, Actual_Start_Time, Timestamp
 	 from Events_With_Starttime e
 	 Join #Units U on u.Item = e.pu_Id
 	 where Timestamp >= @EndTime
 	 order by Timestamp
 	 End
 	 
-----------------------------------------------------------------
-- Get All Waste Records For All Units For Productive Time
-----------------------------------------------------------------
Create Table #WasteTable(IsEvent bit, [Timestamp] datetime, UnitId int, Amount Real, Reason_Level1 int, Reason_Level2 int, Reason_Level3 int, Reason_Level4 int, WEFault_Id int, Crew_Desc nvarchar(15), Shift_Desc nvarchar(15), Prod_Id int, Prod_Desc nvarchar(50))
Declare @SQL1 nvarchar(max)
Select @SQL1=''
Declare @SQL2 nvarchar(max)
Select @SQL2=''
If @IsProrated = 0
 	 Begin
 	  	 -----------------------------------------------------
 	  	 -- Waste Distribution (non-prorated)
 	  	 -----------------------------------------------------
 	  	 --Print 'Waste Distribution (non-prorated)'
 	  	 Select @SQL1 = @SQL1 + ';WITH CTE_Waste As 
(
 	 Select 
 	  	 d.timestamp Timestamp,d.Source_PU_Id, d.PU_Id, d.Reason_Level1, d.Reason_Level2, d.Reason_Level3, d.Reason_Level4, 
 	  	 d.Amount, d.WEFault_Id ,
 	  	 0 [IsEvent]
 	 From 
 	  	 #ProductiveTimes pt
 	  	 Join Waste_Event_Details d on d.pu_id = pt.pu_id and d.timestamp > pt.StartTime and d.Timestamp <= pt.EndTime and d.event_id is null
 	  	 Join #Units U on U.Item = pt.pu_Id 
)'
Select @SQL1 = @SQL1 + 'Select TimeStamp, [IsEvent], IsNull(Source_PU_Id, PU_Id) [UnitId], Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Amount, WEFault_Id '
  	    	  Select @SQL1 = @SQL1 + 'From CTE_Waste  '
  	    	  Select @SQL1 = @SQL1 + ' where 1=1 '
  	    	  If @LocationFilter Is Not Null Select @SQL1 = @SQL1 + ' and d.Source_PU_Id =  ' + convert(nvarchar(10), @LocationFilter)
  	    	  If @ReasonFilter1  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level1 = ' + convert(nvarchar(10), @ReasonFilter1)
  	    	  If @ReasonFilter2  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level2 = ' + convert(nvarchar(10), @ReasonFilter2)
  	    	  If @ReasonFilter3  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level3 = ' + convert(nvarchar(10), @ReasonFilter3)
  	    	  If @ReasonFilter4  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level4 = ' + convert(nvarchar(10), @ReasonFilter4)
  	    	  If @FaultFilter    Is Not Null Select @SQL1 = @SQL1 + ' and (d.WEFault_Id = U.FaultId)'
  	    	  Select @SQL1 = @SQL1 + ' Order By Timestamp'
  	    	    	    	  Select @SQL2 = @SQL2 + ';WITH 
 	  	  	  	  
CTE_Waste As 
(
  	  Select 
  	    	  e.timestamp Timestamp,d.Source_PU_Id, d.PU_Id, d.Reason_Level1, d.Reason_Level2, d.Reason_Level3, d.Reason_Level4, 
  	    	  d.Amount, d.WEFault_Id ,
  	    	   1 [IsEvent]
  	  from 
  	    	  #ProductiveTimes pt
  	    	  join #Units U on U.Item = pt.pu_Id 
  	    	  join Waste_Event_Details d on d.PU_Id=pt.pu_id  and d.event_id is not null
  	    	  join Events e WITH(INDEX(IX_EVENTS_PUID_TIMESTAMP)) on d.event_Id  = e.event_Id and  e.PU_Id = d.PU_Id and  e.timestamp > pt.StartTime and e.Timestamp <= pt.EndTime
)Insert Into #WasteTable(Timestamp, IsEvent, UnitId, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Amount, WEFault_Id)'
Select @SQL2 = @SQL2 + 'Select TimeStamp, [IsEvent], IsNull(Source_PU_Id, PU_Id) [UnitId], Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Amount, WEFault_Id '
  	    	  Select @SQL2 = @SQL2 + 'From CTE_Waste  '
  	    	  Select @SQL2 = @SQL2 + ' where 1=1 '
  	    	  If @LocationFilter Is Not Null Select @SQL2 = @SQL2 + ' and d.Source_PU_Id =  ' + convert(nvarchar(10), @LocationFilter)
  	    	  If @ReasonFilter1  Is Not Null Select @SQL2 = @SQL2 + ' and d.Reason_Level1 = ' + convert(nvarchar(10), @ReasonFilter1)
  	    	  If @ReasonFilter2  Is Not Null Select @SQL2 = @SQL2 + ' and d.Reason_Level2 = ' + convert(nvarchar(10), @ReasonFilter2)
  	    	  If @ReasonFilter3  Is Not Null Select @SQL2 = @SQL2 + ' and d.Reason_Level3 = ' + convert(nvarchar(10), @ReasonFilter3)
  	    	  If @ReasonFilter4  Is Not Null Select @SQL2 = @SQL2 + ' and d.Reason_Level4 = ' + convert(nvarchar(10), @ReasonFilter4)
  	    	  If @FaultFilter    Is Not Null Select @SQL2 = @SQL2 + ' and (d.WEFault_Id = U.FaultId)'
  	    	  Select @SQL2 = @SQL2 + ' Order By Timestamp'
  	  
  	  End 
Else
  	  Begin
  	    	  -----------------------------------------------------
  	    	  -- Quality Distribution (Pro-Rated)
  	    	  -----------------------------------------------------
  	    	  --Print 'Quality Distribution (Pro-Rated)'
  	    	  Select @SQL1 = @SQL1 + 'Select Case When d.Event_Id Is Null Then d.Timestamp Else e.Timestamp End [Timestamp], '
  	    	  Select @SQL1 = @SQL1 + 'Case When d.Event_Id Is Null then 0 Else 1 End [IsEvent], '
  	    	  Select @SQL1 = @SQL1 + 'IsNull(d.Source_PU_Id, d.PU_Id) [UnitId], d.Reason_Level1, d.Reason_Level2, d.Reason_Level3, d.Reason_Level4, '
  	    	  Select @SQL1 = @SQL1 + 'Case'
  	    	  Select @SQL1 = @SQL1 + '  	  When Actual_Start_Time < ' + '''' + convert(nvarchar(20), @StartTime, 120) + '''' + ' Then (d.amount / DateDiff(s, e.Actual_Start_Time, e.Timestamp)) * DateDiff(s, ' + '''' + convert(nvarchar(20), @StartTime, 120) + '''' + ', e.Timestamp)'
  	    	  Select @SQL1 = @SQL1 + '  	  When e.Timestamp > ' + '''' + convert(nvarchar(20), @EndTime, 120) + '''' + ' Then (d.amount / DateDiff(s, e.Actual_Start_Time, e.Timestamp)) * DateDiff(s, e.Actual_Start_Time, ' + '''' + convert(nvarchar(20), @EndTime, 120) + '''' + ')'
  	    	  Select @SQL1 = @SQL1 + '  	  Else IsNull(d.Amount, 0)'
  	    	  Select @SQL1 = @SQL1 + 'End, d.WEFault_Id '
  	    	  Select @SQL1 = @SQL1 + 'From #ProductiveTimes pt '
  	    	  Select @SQL1 = @SQL1 + 'Left Join Waste_Event_Details d on d.pu_id = pt.pu_id '
  	    	  Select @SQL1 = @SQL1 + 'Left Join #Units U on U.Item = pt.pu_Id '
  	    	  Select @SQL1 = @SQL1 + 'Left Join #Events_With_Starttime e on e.Event_Id = d.Event_Id '
  	    	  Select @SQL1 = @SQL1 + 'Where ((d.timestamp > pt.StartTime and d.Timestamp <= pt.EndTime and d.event_id is null) or (e.Actual_Start_Time < pt.EndTime and e.Timestamp > pt.StartTime and d.TimeStamp > pt.StartTime)) '
  	    	  If @LocationFilter Is Not Null Select @SQL1 = @SQL1 + ' and d.Source_PU_Id =  ' + convert(nvarchar(10), @LocationFilter)
  	    	  If @ReasonFilter1  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level1 = ' + convert(nvarchar(10), @ReasonFilter1)
  	    	  If @ReasonFilter2  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level2 = ' + convert(nvarchar(10), @ReasonFilter2)
  	    	  If @ReasonFilter3  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level3 = ' + convert(nvarchar(10), @ReasonFilter3)
  	    	  If @ReasonFilter4  Is Not Null Select @SQL1 = @SQL1 + ' and d.Reason_Level4 = ' + convert(nvarchar(10), @ReasonFilter4)
  	    	  If @FaultFilter    Is Not Null Select @SQL1 = @SQL1 + ' and (d.WEFault_Id = U.FaultId)'
  	    	  Select @SQL1 = @SQL1 + ' Order By Timestamp'
  	  End
 	  SELECT @SQL1+=' OPTION(RECOMPILE);'
 	  SELECT @SQL2= @SQL2+' OPTION(RECOMPILE);'
 	  --SELECT @SQL1,@SQL2
 	   
Insert Into #WasteTable(Timestamp, IsEvent, UnitId, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Amount, WEFault_Id)
Exec (@SQL1) 
--Insert Into #WasteTable(Timestamp, IsEvent, UnitId, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Amount, WEFault_Id)
Exec (@SQL2) 
--<TIME BASED CALCULATION>
 	 Insert Into #WasteTable(Timestamp, IsEvent, UnitId, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Amount, WEFault_Id)
 	 Select 
 	  	 End_Time [TimeStamp],
 	  	 NULL [IsEvent],
 	  	 pu_Id,
 	  	 
 	  	 Reason_Level2,
 	  	 Reason_Level2,
 	  	 Reason_Level3,
 	  	 Reason_Level4,
 	  	 duration,
 	  	 NULL Fault_Id 	 
 	 from 
 	  	 Timed_Event_Details Ted 
 	  	 Join #Units u on u.Item = Ted.Pu_Id And u.OEEMode = 'Time Based'
 	 Where 
 	  	 1=1 and
 	  	 Start_Time >= @StartTime
 	  	 And End_Time <= @EndTime
 	  	 and Reason_Level1 in (Select Event_Reason_Id from Event_Reasons Where Event_Reason_Name_Local = 'Quality losses')
--</TIME BASED CALCULATION>
-- Get Total Waste
SELECT @TotalWaste = Sum(Amount) From #WasteTable
-- Summarize Waste by Unit
insert into @UnitWasteTable(PU_Id, TotalWaste)
 	 Select UnitId, Sum(Amount)
 	 From #WasteTable
 	 Group By UnitId
-- Update UnitTotals Table which contains all production and waste 
-- grouped by unit
Update UT SET
 	 UT.TotalWaste = UW.TotalWaste
 	 From @UnitWasteTable UW
 	 Join @UnitTotalsTable UT on UT.PU_ID = UW.PU_ID
-----------------------------------------------
-- Update Shift and Crew
-----------------------------------------------
Update W SET
 	 W.Crew_Desc = CS.Crew_Desc,
 	 W.Shift_Desc = CS.Shift_Desc
 	 From @Crew_Schedule CS
 	 Join #WasteTable W on W.UnitId = CS.PU_ID
  	  	 AND W.Timestamp > CS.Start_Time and W.Timestamp <= CS.End_Time
Update #WasteTable Set Crew_Desc =   dbo.fnDBTranslate(N'0', 38333, 'Unspecified')   where Crew_Desc Is Null
Update #WasteTable Set Shift_Desc =   dbo.fnDBTranslate(N'0', 38333, 'Unspecified')  where Shift_Desc Is Null
-----------------------------------------------
-- Update Products
-----------------------------------------------
Update W SET
 	 W.Prod_Desc = P.Prod_Desc,
 	 W.Prod_Id = PS.Prod_Id
 	 From @Production_Starts PS
 	 Join #WasteTable W on W.UnitId = PS.PU_ID
 	  	 AND PS.Start_Time < W.Timestamp and (PS.End_Time >= W.Timestamp or PS.End_Time Is Null)
 	 Join Products P on P.Prod_Id = PS.Prod_Id
Update #WasteTable Set Prod_Desc =   dbo.fnDBTranslate(N'0', 38333, 'Unspecified')   where Prod_Desc Is Null
Declare @SQLString nvarchar(max)
Create Table #UnitTotalsTable (PU_Id int, TotalProduction float, TotalWaste float)
insert into #UnitTotalsTable
 	 Select * from @UnitTotalsTable
 	 
--------------------------------------------------------
-- Group By Location or Production Unit
--------------------------------------------------------
If @LocationFilter Is Null
Begin
 	 Select @SQLString = 'Select W.UnitId [Id], U.UnitName [\@'+ dbo.fnDBTranslate(N'0', 38345, 'Location') + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), (UT.TotalProduction) / Count(UnitId)) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 1 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Join #Units U on U.Item = W.UnitId'
 	 Select @SQLString = @SQLString + ' Join #UnitTotalsTable UT on UT.PU_ID = W.UnitId'
 	 Select @SQLString = @SQLString + ' Group By W.UnitId, U.UnitName, UT.TotalProduction'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select W.UnitId [Id], U.UnitName [\@Location], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), (UT.TotalProduction) / Count(UnitId)) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 1 [rs_id]
 	 From @WasteTable W
 	 Join #Units U on U.Item = W.UnitId
 	 Join @UnitTotalsTable UT on UT.PU_ID = W.UnitId
 	 Group By W.UnitId, U.UnitName, UT.TotalProduction
*/
End
Drop Table #UnitTotalsTable
--------------------------------------------------------
-- Group By Fault
--------------------------------------------------------
If @FaultFilter Is Null
Begin
 	 Select @SQLString = 'Select WEF.WEFault_Name [Id], IsNull(WEF.WEFault_Name, ' + '''' +  dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') [\@' + @sFault + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), ' + convert(nvarchar(25), @TotalProduction) + ' / Count(IsNull(WEF.WEFault_Name, ' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') +'''' + '))) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 2 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Left Join Waste_Event_Fault WEF on WEF.WEFault_Id = W.WEFault_Id'
 	 Select @SQLString = @SQLString + ' Group By W.WEFault_Id, WEF.WEFault_Name'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select W.WEFault_Id [Id], IsNull(WEF.WEFault_Name, @Unspecified) [\@Fault], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), @TotalProduction / Count(IsNull(WEF.WEFault_Name, @Unspecified))) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 2 [rs_id]
 	 From @WasteTable W
 	 Left Join Waste_Event_Fault WEF on WEF.WEFault_Id = W.WEFault_Id
 	 Group By W.WEFault_Id, WEF.WEFault_Name
*/
End
--------------------------------------------------------
-- Group By Downtime Reason 1
--------------------------------------------------------
If @ReasonFilter1 Is Null and @Level1Name Is Not Null
Begin
--/*
 	 Select @SQLString = 'Select W.Reason_Level1 [Id], IsNull(ER.event_reason_name, ' + ''''  + dbo.fnDBTranslate(N'0', 38333, 'Unspecified')  + '''' + ') [\@' + @Level1Name + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), ' + convert(nvarchar(25), @TotalProduction) + ' / Count(IsNull(W.Reason_Level1, 0))) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 3 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level1'
 	 Select @SQLString = @SQLString + ' Group By W.Reason_Level1, ER.event_reason_name'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
--*/
/* 	 
 	 Select W.Reason_Level1 [Id], IsNull(ER.event_reason_name, @Unspecified) [\@Reason1], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), @TotalProduction / Count(IsNull(W.Reason_Level1, 0))) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 3 [rs_id]
 	 From @WasteTable W
 	 Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level1
 	 Group By W.Reason_Level1, ER.event_reason_name
*/
End
--------------------------------------------------------
-- Group By Downtime Reason 2
--------------------------------------------------------
If @ReasonFilter2 Is Null and @Level2Name Is Not Null
Begin
 	 Select @SQLString = 'Select W.Reason_Level2 [Id], IsNull(ER.event_reason_name, ' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') [\@' + @Level2Name + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), ' + convert(nvarchar(25), @TotalProduction) + ' / Count(IsNull(W.Reason_Level2, 0))) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 4 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level2'
 	 Select @SQLString = @SQLString + ' Group By W.Reason_Level2, ER.event_reason_name'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select W.Reason_Level2 [Id], IsNull(ER.event_reason_name, @Unspecified) [\@Reason2], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), @TotalProduction / Count(IsNull(W.Reason_Level2, 0))) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 4 [rs_id]
 	 From @WasteTable W
 	 Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level2
 	 Group By W.Reason_Level2, ER.event_reason_name
*/
End
--------------------------------------------------------
-- Group By Downtime Reason 3
--------------------------------------------------------
If @ReasonFilter3 Is Null and @Level3Name Is Not Null
Begin
 	 Select @SQLString = 'Select W.Reason_Level3 [Id], IsNull(ER.event_reason_name, ' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') [\@' + @Level3Name + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), ' + convert(nvarchar(25), @TotalProduction) + ' / Count(IsNull(W.Reason_Level3, 0))) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 5 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level3'
 	 Select @SQLString = @SQLString + ' Group By W.Reason_Level3, ER.event_reason_name'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select W.Reason_Level3 [Id], IsNull(ER.event_reason_name, @Unspecified) [\@Reason3], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), @TotalProduction / Count(IsNull(W.Reason_Level3, 0))) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 5 [rs_id]
 	 From @WasteTable W
 	 Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level3
 	 Group By W.Reason_Level3, ER.event_reason_name
*/
End
--------------------------------------------------------
-- Group By Downtime Reason 4
--------------------------------------------------------
If @ReasonFilter4 Is Null and @Level4Name Is Not Null
Begin
 	 Select @SQLString = 'Select W.Reason_Level4 [Id], IsNull(ER.event_reason_name, ' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') [\@Reason4], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), ' + convert(nvarchar(25), @TotalProduction) + ' / Count(IsNull(W.Reason_Level4, 0))) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 6 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level4'
 	 Select @SQLString = @SQLString + ' Group By W.Reason_Level4, ER.event_reason_name'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select W.Reason_Level4 [Id], IsNull(ER.event_reason_name, @Unspecified) [\@Reason4], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), @TotalProduction / Count(IsNull(W.Reason_Level4, 0))) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 6 [rs_id]
 	 From @WasteTable W
 	 Left Join Event_Reasons ER on ER.event_reason_id = W.Reason_Level4
 	 Group By W.Reason_Level4, ER.event_reason_name
*/
End
--------------------------------------------------------
-- Group By Product
--------------------------------------------------------
--declare @ProductionTotalsTable Table(Prod_Id int, TotalProduction float)
Create Table #ProductionTotalsTable (Prod_Id int, TotalProduction float)
If @ProductFilter Is Null
Begin
 	 insert into #ProductionTotalsTable(Prod_Id, TotalProduction)
 	 Select Prod_Id, Sum(TotalProduction)
 	 From #ProductiveTimes
 	 Group By Prod_Id
 	 Select @SQLString = 'Select W.Prod_Id [Id], CASE WHEN W.Prod_Desc =''no product'' THEN '''+ dbo.fnDBTranslate(N'0', 35288, 'No Product')+''' ELSE W.Prod_Desc END  [\@'+ dbo.fnDBTranslate(N'0', 38337, 'Product') + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), (PT.TotalProduction) / Count(W.Prod_Desc)) [\@' + @sMABE + '], '
 	 
 	 Select @SQLString = @SQLString + ' Case when PT.TotalProduction = 0 then 0 else Convert(Decimal(10,2), (sum(Amount) / (PT.TotalProduction)) * 100) end [% Production],'
 	 Select @SQLString = @SQLString + ' Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], PT.TotalProduction [TotalProduction], 7 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Join #ProductionTotalsTable PT on PT.Prod_Id = W.Prod_Id'
 	 Select @SQLString = @SQLString + ' Group By W.Prod_Id, W.Prod_Desc, PT.Prod_Id, PT.TotalProduction'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 
 	  
 	 exec (@SQLString)
/*
 	 Select Null [Id], W.Prod_Desc [\@Product], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), (PT.TotalProduction) / Count(W.Prod_Desc)) [\@MABE], 
 	 Convert(Decimal(10,2), (sum(Amount) / (PT.TotalProduction)) * 100) [% Production],
 	 Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 7 [rs_id]
 	 From @WasteTable W
 	 Join @ProductionTotalsTable PT on PT.Prod_Id = W.Prod_Id
 	 Group By W.Prod_Desc, PT.Prod_Id, PT.TotalProduction
*/
End
Drop Table #ProductionTotalsTable 
--------------------------------------------------------
-- Group By Crew
--------------------------------------------------------
--declare @CrewTotalsTable Table(Crew_Desc nvarchar(10), TotalProduction float)
Create Table #CrewTotalsTable (Crew_Desc nvarchar(15), Shift_Desc nvarchar(15), TotalProduction float)
If @CrewFilter Is Null
Begin
 	 insert into #CrewTotalsTable(Crew_Desc, TotalProduction)
 	 Select Crew_Desc, Sum(TotalProduction)
 	 From #ProductiveTimes
 	 Group By Crew_Desc
 	 
 	 Select @SQLString = 'Select W.Crew_Desc [Id], CASE WHEN W.Crew_Desc = ''<Unspecified>'' THEN ''<' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '>''  ELSE W.Crew_Desc  END [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), CT.TotalProduction / Count(W.Crew_Desc)) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 8 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Join #CrewTotalsTable CT on CT.Crew_Desc = W.Crew_Desc'
 	 Select @SQLString = @SQLString + ' Group By W.Crew_Desc, CT.Crew_Desc, CT.TotalProduction'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select Null [Id], W.Crew_Desc [\@Crew], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), CT.TotalProduction / Count(W.Crew_Desc)) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 8 [rs_id]
 	 From @WasteTable W
 	 Join @CrewTotalsTable CT on CT.Crew_Desc = W.Crew_Desc
 	 Group By W.Crew_Desc, CT.Crew_Desc, CT.TotalProduction
 	 Order By W.Crew_Desc
*/
End
If @ShiftFilter Is Null
Begin
 	 Delete From #CrewTotalsTable
 	 -- Recycle the CrewTotals Table From Above
 	 insert into #CrewTotalsTable(Shift_Desc, TotalProduction)
 	 Select Shift_Desc, Sum(TotalProduction)
 	 From #ProductiveTimes
 	 Group By Shift_Desc
 	 
 	 Select @SQLString = 'Select W.Shift_Desc [Id], CASE WHEN W.Shift_Desc = ''<Unspecified>'' THEN ''<' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '>''  ELSE W.Shift_Desc  END [\@' + dbo.fnDBTranslate(N'0', 38479, 'Shift') + '], Convert(Decimal(10,2), sum(Amount)) [' + @sTotal + '], Convert(Decimal(10,2), Avg(Amount)) [\@' + @sMAPE + '], Convert(Decimal(10,2), CT.TotalProduction / Count(W.Crew_Desc)) [\@' + @sMABE + '], Case When ' + convert(nvarchar(25), @TotalWaste) + ' = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / ' + convert(nvarchar(25), @TotalWaste) + ') * 100) End [\@' + @sPerTotal + '], count(UnitId) [' + @sNumEvents + '], 9 [rs_id]'
 	 Select @SQLString = @SQLString + ' From #WasteTable W'
 	 Select @SQLString = @SQLString + ' Join #CrewTotalsTable CT on CT.Shift_Desc = W.Shift_Desc'
 	 Select @SQLString = @SQLString + ' Group By W.Shift_Desc, CT.Shift_Desc, CT.TotalProduction'
 	 Select @SQLString = @SQLString + ' Order By [' + @sTotal + '] ASC'
 	 exec (@SQLString)
/*
 	 Select Null [Id], W.Crew_Desc [\@Crew], Convert(Decimal(10,2), sum(Amount)) [Total], Convert(Decimal(10,2), Avg(Amount)) [\@MAPE], Convert(Decimal(10,2), CT.TotalProduction / Count(W.Crew_Desc)) [\@MABE], Case When @TotalWaste = 0 Then 0.0 Else Convert(Decimal(10,2), (Sum(Amount) / @TotalWaste) * 100) End [\@% Total], count(UnitId) [# Events], 8 [rs_id]
 	 From @WasteTable W
 	 Join @CrewTotalsTable CT on CT.Crew_Desc = W.Crew_Desc
 	 Group By W.Crew_Desc, CT.Crew_Desc, CT.TotalProduction
 	 Order By W.Crew_Desc
*/
End
--select * into deeptiCrewTotalsTable from  #CrewTotalsTable
--select * into deeptiUnits from  #Units
--select * into deeptiProductiveTimes from  #ProductiveTimes
--select * into deeptiWasteTable from  #WasteTable
--select * into deeptiEvents_with_startTime from  #Events_With_StartTime
ENd 

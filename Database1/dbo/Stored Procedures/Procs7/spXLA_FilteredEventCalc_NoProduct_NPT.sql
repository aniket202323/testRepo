-- 
-- spXLA_FilteredEventCalc_NoProduct_NPT() is derived from spXLA_FilteredEventCalc_AP. Defect #24497:mt/9-17-2002:
-- Crew,Shift filters added but without join to production_starts table.
--
-- ECR #25385 (mt/4-15-2003): fixed error due to alias 
-- ECR #28662: mt/8-20-2004: replace unreliable Case statement when NULL with COALESCE 
--
CREATE PROCEDURE dbo.spXLA_FilteredEventCalc_NoProduct_NPT
 	   @PL_Id 	  	 Int 	  	 --Line(now called Unit)
 	 , @PL_Desc 	  	 Varchar(50)
 	 , @PU_Id                Int 	  	 --Location
 	 , @PU_Desc              Varchar(50)
 	 , @Start_Time 	  	 Datetime
 	 , @End_Time 	  	 DateTime
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
    , @DimensionSought      TinyInt
 	 , @ExtraCalcs 	  	 SmallInt
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
 	 --Needed for internal lookup
DECLARE 	 @MasterUnit 	  	 Integer
DECLARE @RowCount               Integer
 	 --Line/Unit Query
DECLARE @UnitType 	  	 TinyInt
DECLARE @Line 	  	  	 TinyInt
DECLARE @SingleUnit 	  	 TinyInt
DECLARE @AnyUnit 	  	 TinyInt
DECLARE @NOF             Int
DECLARE @NPTCOUNT        Int
 	 --Needed for Dimension Sought
DECLARE @Get_Initial_Dimension_A TinyInt
DECLARE @Get_Initial_Dimension_X TinyInt
DECLARE @Get_Initial_Dimension_Y TinyInt
DECLARE @Get_Initial_Dimension_Z TinyInt
DECLARE @Get_Final_Dimension_A   TinyInt
DECLARE @Get_Final_Dimension_X   TinyInt
DECLARE @Get_Final_Dimension_Y   TinyInt
DECLARE @Get_Final_Dimension_Z   TinyInt
 	 --Needed for statistical calculations
DECLARE @Average 	 Real
DECLARE @Min 	  	 Real
DECLARE @Max 	  	 Real
DECLARE @Std 	  	 Real
DECLARE @Total 	  	 Real
DECLARE @@PU_Id         Int
DECLARE @Count 	  	 Int
DECLARE @TimeOfMin 	 DateTime
DECLARE @TimeOfMax 	 DateTime
DECLARE @@Dimension 	 Real
DECLARE @@TimeStamp  	 DateTime
DECLARE @FetchCount  	 Int
DECLARE @TempMin  	 Real
DECLARE @TempMax  	 Real
DECLARE @SumXSqr 	 Real
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 -- Defining Dimension Sought
SELECT @Get_Initial_Dimension_A = 0
SELECT @Get_Initial_Dimension_X = 1
SELECT @Get_Initial_Dimension_Y = 2
SELECT @Get_Initial_Dimension_Z = 3
SELECT @Get_Final_Dimension_A   = 4
SELECT @Get_Final_Dimension_X   = 5
SELECT @Get_Final_Dimension_Y   = 6
SELECT @Get_Final_Dimension_Z   = 7
 	 -- Defining Line/Unit/Any Unit Selection
SELECT @Line 	  	  	 = 1
SELECT @SingleUnit 	  	 = 2
SELECT @AnyUnit 	  	  	 = 3
SELECT @NPTCOUNT       = 0
SELECT @NOF            = 0
SELECT @UnitType = 0
-- First Get PL_Id From PL_Id/PL_Desc Inputs
--
SELECT @RowCount = -1
If @PL_Desc Is NOT NULL 
  BEGIN
    SELECT @PL_Id = PL_Id FROM Prod_Lines WHERE PL_Desc = @PL_Desc
    SELECT @RowCount = @@ROWCOUNT
  END
Else --@PL_Desc Is NULL Assume @PL_Id Is NOT NULL
  BEGIN
    SELECT @PL_Desc = PL_Desc FROM Prod_Lines WHERE PL_Id = @PL_Id
    SELECT @RowCount = @@ROWCOUNT   
    --Take care of wrong @PL_Id input 
    If @RowCount = 0
      BEGIN
        SELECT @PL_Id = NULL
      END
    --EndIf
  END
--EndIf:
-- Decide How to return resultset: By Single Line; Single Unit; Or Any Units
-- DESIGN RULE: Line is not deciding the factor, UNIT IS!!  ( Add-In user may pull down Line list as filter for units )
--
If @PL_Id Is NULL AND @PU_Id Is NULL AND @PU_Desc Is NULL 
  BEGIN
    SELECT @UnitType = @AnyUnit
  END
Else If @PL_Id Is NOT NULL AND @PU_Id Is NULL AND @PU_Desc Is NULL 
  BEGIN    
    SELECT @UnitType = @Line
  END
Else If @PU_Id Is NULL AND @PU_Desc Is NULL  --Any Production Unit; Line selected or not
  BEGIN
    SELECT @UnitType = @AnyUnit
  END
Else --some unit is selected
  BEGIN
    SELECT @RowCount = -1
    If @PU_Desc Is NOT NULL
      BEGIN
        --SELECT @PU_Id = Case Master_Unit When NULL Then PU_Id Else Master_Unit End -- not reliable, returned NULL
        SELECT @PU_Id = Case COALESCE(Master_Unit, -1) When -1 Then PU_Id Else Master_Unit End   -- replaced with Coalesce(); ECR #28662: mt/8-20-2004
          FROM Prod_Units WHERE PU_Desc = @PU_Desc
        SELECT @RowCount = @@ROWCOUNT
      END
    Else If @PU_Desc Is NULL AND @PU_Id Is NOT NULL -- specific production unit requested
      BEGIN
        SELECT @PU_Desc = PU_Desc FROM Prod_Units WHERE PU_Id = @PU_Id
        SELECT @RowCount = @@ROWCOUNT
      END
    --EndIf:@PU_Desc
    If @RowCount = 0 RETURN 
    --EndIf:@RowCount = 0
    SELECT @UnitType = @SingleUnit
    SELECT @MasterUnit = @PU_Id
  END
--EndIf:Any Production Units
-- MT/5-20-2002: Event_Details.TimeStamp differ slightly from Events.TimeStamp; We Need Event_Id in temp table 
-- for later join with Events (in applied product querries)
--
CREATE TABLE #Event_Details (PU_Id Int, Event_Id Int, TimeStamp DateTime, Start_Time DateTime, Total real NULL,Dimension Real NULL)
CREATE TABLE #Prod_Units (PU_Id Int)
CREATE TABLE #EventsTotal ( PU_id int,Event_id int, TimeStamp DateTime, Start_Time DateTime , Total int NULL, Dim real, Diff real)
-- Get the desired Units based on what we decide above (all units in a given line, single unit, or any unit (all units))
--
If @UnitType = @Line
  BEGIN
    INSERT INTO #Prod_Units
    SELECT pu.PU_Id FROM Prod_Units pu JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @PL_Id
  END 
Else If @UnitType = @AnyUnit
  BEGIN
    INSERT INTO #Prod_Units
    SELECT pu.PU_Id FROM Prod_Units pu WHERE pu.PU_Id <> 0
  END
Else If @UnitType = @SingleUnit --@MasterUnit NOT NULL
  BEGIN
    INSERT INTO #Prod_Units
    SELECT pu.PU_Id FROM Prod_Units pu WHERE pu.PU_Id <> 0 AND pu.PU_Id = @MasterUnit
  END
--EndIf:@MasterUnit
--Determine Crew,shift types
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_EVENT_DETAILS_INSERT
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_EVENT_DETAILS_INSERT
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_EVENT_DETAILS_INSERT
Else                                                   GOTO HASCREW_HASSHIFT_EVENT_DETAILS_INSERT
--EndIf:Crew,Shift
-- INSERT THE "REQUESTED DIMENSION" INTO TEMP EVENT_DETAILS TABLE For SPECIFIED UNIT(S)
--
NOCREW_NOSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 	 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
        INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
 	  	 INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	 INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed
END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed
Update #EventsTotal SET Total = 10
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
         INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
         INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
 	  	 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime  e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
         INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
 	  	 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End NOCREW_NOSHIFT_EVENT_DETAILS_INSERT:
HASCREW_NOSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
         INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
  END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	 INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End HASCREW_NOSHIFT_EVENT_DETAILS_INSERT:
NOCREW_HASSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  	  
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	 INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End NOCREW_HASSHIFT_EVENT_DETAILS_INSERT:
HASCREW_HASSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Start_Time, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, e.Actual_Start_Time, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events_With_StartTime e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
 	  	  INSERT INTO #EventsTotal 
 	  	 SELECT ed.PU_Id, ed.Event_id, ed.TimeStamp, ed.Start_Time, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0, ed.Dimension, Datediff(ss,ed.Start_time,ed.TimeStamp)/60.0
 	  	 FROM #Event_details ed 	  
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End HASCREW_HASSHIFT_EVENT_DETAILS_INSERT:
COMMON_EVENT_CALC_START_POINT:
---NPT Logic Started -- To get the NPT events from the Non_Productive table
------------------------------------------------------------------------------------------------------
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                           AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@Pu_id)
      WHERE PU_Id = @Pu_id
                  AND np.Start_Time < @End_time
                  AND np.End_Time > @Start_Time
------------------------------------------------------------------------------------------------------
--Update #Event_Details set Diff = DateDiff(ss,Start_Time,TimeStamp)/60.0
---SC1---------------------------------------------------------------------------------------
--------   Start_time-------------------------------------Timestamp
--------                   n.St-----------n.End
UPDATE n SET NPDuration = DateDiff(ss,n.StarTTime,n.EndTime)/60.0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp > n.Endtime And n.starttime < T.Timestamp )
Update #EventsTotal set Total = (Total - isnull(n.NPDuration,0))
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp > n.Endtime)
-------SC2---------------------------------------------------------------------------------------
---                               Start_time-------------------------------------Timestamp
--------                   n.St-------------------------n.End
UPDATE n SET NPDuration = DateDiff(ss,T.Start_Time,n.EndTime)/60.0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
Update #EventsTotal set Total  = (T.Total  - isnull(n.NPDuration,0))
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
-- 	 
--------------------------------------------------------------------------------------------------
--SC3
UPDATE n SET NPDuration = DateDiff(ss,T.Start_Time,n.EndTime)/60.0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
Update #EventsTotal set Total  = (T.Total  - isnull(n.NPDuration,0))
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
----SC4------------------------------------------------------------------------------------------
---           Start_time-------------------------------------Timestamp
--------                                 n.St----------------------------------------------n.End
UPDATE n SET NPDuration = DateDiff(ss,n.StartTime,T.TimeStamp)/60.0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and n.Starttime < T.TimeStamp)
--
Update #EventsTotal set Total  = (T.Total - isnull(n.NPDuration,0))
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
----SC5------------------------------------------------------------------------------------------
---           Start_time-------------------------------------Timestamp
--------                                 n.St----------------n.End
UPDATE n SET NPDuration = DateDiff(ss,n.StartTime,T.TimeStamp)/60.0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp = n.Endtime and n.Starttime < T.TimeStamp)
--
Update #EventsTotal set Total  = (T.Total  - isnull(n.NPDuration,0))
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp = n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
--------------------------------------------------------------------------------------------------
---SC6--
--------             Start_time-----------Timestamp
--------                   n.St-----------n.End
UPDATE n SET NPDuration = DateDiff(ss,n.StarTTime,n.EndTime)/60.0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime) 
Update #EventsTotal set Total  = (T.Total  - isnull(n.NPDuration,0))
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime)
SELECT @NPTCOUNT = @NPTCOUNT + 1 
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime)
---------------------------------------------------------------------------------------------------
---SC7--
-------- 	  	  	  	  	 Start_time-----------Timestamp
--------        n.St------------------------------------------------n.End
UPDATE n SET NPDuration = 0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp <= n.Endtime) 
Update #EventsTotal set Total  = 0
FROM  #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp <= n.Endtime)
SELECT @NPTCOUNT = @NPTCOUNT + 1 
FROM #EventsTotal T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp <= n.Endtime)
---------------------------------------------------------------------------------------------------
--
--
Update #EventsTotal set Dim = (Total * Dim)/diff
--SELECT * FROM #Event_Details
--select * from #EventsTotal
--SELECT * FROM @Periods_NPT
  -- Retrieve SQL-Capable Statistics (Original Products)
  SELECT @Min     = MIN(ed.Dim)
       , @Max     = Max(ed.Dim)
       , @Total   = SUM(ed.Dim)
       , @Count   = COUNT(ed.Dim)- @NPTCOUNT
       , @Average = @Total / @Count
    FROM #EventsTotal ed
  If @ExtraCalcs = 1  --(Original Products)
    BEGIN
      DECLARE TCursor INSENSITIVE CURSOR 
          -- ECR #25385 (mt/4-15-2003): fixed alias error 
          --FOR (SELECT e.PU_Id, e.TimeStamp, ed.Dimension FROM #Event_Details ed JOIN Events e on e.Event_Id = #Event_Details.Event_Id ) FOR READ ONLY
          FOR (SELECT e.PU_Id, e.TimeStamp, ed.Dimension FROM #Event_Details ed JOIN Events e on e.Event_Id = ed.Event_Id ) FOR READ ONLY
      GOTO OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF
     END
  --EndIf
  GOTO DO_FINAL_RETRIEVAL
OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF:
  SELECT @FetchCount = 0
  SELECT @SumXSqr    = 0
  SELECT @@TimeStamp = 0
  SELECT @@Dimension = 0
  SELECT @@PU_Id     = 0
  OPEN TCursor
EXTRACALC_FETCH_LOOP:
  FETCH NEXT FROM TCursor INTO @@PU_Id, @@TimeStamp, @@Dimension
  If (@@Fetch_Status = 0)
    BEGIN
      If @@Dimension Is NULL GOTO EXTRACALC_FETCH_LOOP
      If @FetchCount = 0           
        BEGIN
          SELECT @TempMin   = @@Dimension
          SELECT @TempMax   = @TempMin
          SELECT @TimeOfMin = @@TimeStamp
          SELECT @TimeOfMax = @@TimeStamp 
        END
      --EndIf @FetchCount = 0
      If @@Dimension < @TempMin
        BEGIN
          SELECT @TempMin   = @@Dimension
          SELECT @TimeOfMin = @@TimeStamp
        END
      --EndIf CONVERT...
      If @@Dimension > @TempMax
        BEGIN
          SELECT @TempMax   = @@Dimension
          SELECT @TimeOfMax = @@TimeStamp
        END
      --EndIf CONVERT...
      SELECT @SumXSqr = @SumXSqr + POWER(@Average - @@Dimension, 2)      
      SELECT @FetchCount = @FetchCount + 1
      GOTO EXTRACALC_FETCH_LOOP
    END
  --EndIf (@@Fetch_Status = 0)
  CLOSE TCursor
  DEALLOCATE TCursor
  --If there is only one row MAX = MIN and standard deviation = 0
  If @Count = 1 SELECT @Std = 0 Else SELECT @Std = POWER(@SumXSqr / (1.0 * (@Count - 1)),0.5)
DO_FINAL_RETRIEVAL:
  If @Count = 0 SELECT @TimeOfMin = NULL, @TimeOfMax = NULL
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  --Return resultset
  SELECT Average           = @Average 
       , Minimum           = @Min
       , Maximum           = @Max
       , Total             = @Total
       , CountOfRows       = @Count
       , StandardDeviation = @Std
       , TimeOfMinimum     = @TimeOfMin at time zone @DBTz at time zone @InTimeZone
       , TimeOfMaximum     = @TimeOfMax at time zone @DBTz at time zone @InTimeZone  
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #Event_Details
  DROP TABLE #Prod_Units
  Drop TABLE #EventsTotal

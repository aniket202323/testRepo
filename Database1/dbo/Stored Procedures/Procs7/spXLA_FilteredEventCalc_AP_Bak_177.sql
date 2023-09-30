-- 
-- spXLA_FilteredEventCalc_AP() is derived from spXLAEventCalc_AP. Defect #24497:mt/9-17-2002:added Crew,Shift
-- ECR #28662: mt/8-20-2004: replace unreliable Case statement when NULL with COALESCE 
CREATE PROCEDURE dbo.[spXLA_FilteredEventCalc_AP_Bak_177]
 	   @PL_Id 	  	 Int 	  	 --Line(now called Unit)
 	 , @PL_Desc 	  	 Varchar(50)
 	 , @PU_Id                Int 	  	 --Location
 	 , @PU_Desc              Varchar(50)
 	 , @Start_Time 	  	 Datetime
 	 , @End_Time 	  	 DateTime
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
 	 , @Prod_Id 	  	 Integer 
 	 , @Group_Id 	  	 Integer 
 	 , @Prop_Id 	  	 Integer 
 	 , @Char_Id 	  	 Integer 
 	 , @AppliedProductFilter 	 TinyInt 	  	 --1 = Filter By Applied Product; 0 = Filter By Original Product
        , @DimensionSought      TinyInt
 	 , @ExtraCalcs 	  	 SmallInt
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	 --Needed for internal lookup
DECLARE 	 @MasterUnit 	  	 Integer
DECLARE @RowCount               Integer
 	 --Line/Unit Query
DECLARE @UnitType 	  	 TinyInt
DECLARE @Line 	  	  	 TinyInt
DECLARE @SingleUnit 	  	 TinyInt
DECLARE @AnyUnit 	  	 TinyInt
 	 --Needed to define query type
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
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
        --SELECT @PU_Id = Case Master_Unit When NULL Then PU_Id Else Master_Unit End            --not reliable, returned NULL when Master_Unit is NULL
        SELECT @PU_Id = Case COALESCE(Master_Unit, -1) When -1 Then PU_Id Else Master_Unit End  -- ECR #28662: mt/8-20-2004
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
CREATE TABLE #Event_Details (PU_Id Int, Event_Id Int, TimeStamp DateTime, Dimension Real NULL)
CREATE TABLE #Prod_starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Applied_Products (Pu_Id Int, Event_Id Int, Prod_Id Int, Applied_Prod_Id Int NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Prod_Units (PU_Id Int)
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
-- DEFINE REQUESTED Product(s) Based on Product input parameters
-- ( This information is needed by both original and applied product queries )
--
SELECT @SingleProduct 	  	 = 1 	 --@SingleProduct
SELECT @Group 	  	  	 = 2 	 --@Group
SELECT @Characteristic 	  	 = 3 	 --@Characteristic
SELECT @GroupAndProperty 	 = 4 	 --@GroupAndProperty  
SELECT @NoProductSpecified 	 = 5 	 --@NoProductSpecified
--Figure Out Query Type Based on Product Info given
-- NOTE: We DO NOT handle all possible null combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
-- Proficy Add-In blocks out illegal combinations, and allows only these combination:
--     * Property AND Characteristic 
--     * Group Only
--     * Group, Propery, AND Characteristic
--     * Product Only
--     * No Product Information At All 
If      @Prod_Id Is NOT NULL                           SELECT @QueryType = @SingleProduct
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL     SELECT @QueryType = @Group 
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL     SELECT @QueryType = @Characteristic 
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL SELECT @QueryType = @GroupAndProperty 
Else                                                   SELECT @QueryType = @NoProductSpecified 
--EndIf
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
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End NOCREW_NOSHIFT_EVENT_DETAILS_INSERT:
HASCREW_NOSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Crew_Desc = @Crew_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End HASCREW_NOSHIFT_EVENT_DETAILS_INSERT:
NOCREW_HASSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End NOCREW_HASSHIFT_EVENT_DETAILS_INSERT:
HASCREW_HASSHIFT_EVENT_DETAILS_INSERT:
  If @DimensionSought = @Get_Initial_Dimension_A 
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END
  Else If @DimensionSought = @Get_Initial_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Initial_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Initial_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_A
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_A
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_X
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_X
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Y
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Y
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  Else If @DimensionSought = @Get_Final_Dimension_Z
    BEGIN
      INSERT INTO #Event_Details (PU_Id, Event_Id, TimeStamp, Dimension) 
        SELECT e.PU_Id, ed.Event_Id, e.TimeStamp, ed.Final_Dimension_Z
          FROM Event_Details ed
          JOIN Events e on e.Event_Id = ed.Event_Id
          JOIN #Prod_Units pu ON pu.PU_Id = e.PU_Id
          JOIN Crew_Schedule C ON C.PU_Id = e.PU_Id AND e.TimeStamp >= C.Start_Time AND e.TimeStamp < C.End_Time 
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time 
    END 
  --EndIf:@Dimension
  GOTO COMMON_EVENT_CALC_START_POINT
--End HASCREW_HASSHIFT_EVENT_DETAILS_INSERT:
COMMON_EVENT_CALC_START_POINT:
  If @AppliedProductFilter = 1 GOTO RETRIEVE_WITH_APPLIED_PRODUCT_FILTER
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Extract Product information from Production Start data into Temp table (#Prod_Starts)--
If @QueryType = @NoProductSpecified  --5
  BEGIN
    INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM Production_starts ps
      JOIN #Prod_Units pu ON pu.PU_Id = ps.PU_Id
     WHERE (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
             OR (ps.End_Time BETWEEN @Start_Time AND @End_Time) 
             OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
           ) 
  END
Else If @QueryType = @SingleProduct  --1
  BEGIN
    INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM Production_Starts ps
      JOIN #Prod_Units pu ON pu.PU_Id = ps.PU_Id
     WHERE ps.Prod_Id = @Prod_Id 
       AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
             OR ps.End_Time BETWEEN @Start_Time AND @End_Time
             OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
           ) 
  END
Else
  BEGIN     	 
    If @QueryType = @Group  --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic  --3
      BEGIN
        INSERT INTO  #Products
        SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else --By Group & Property
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
        INSERT INTO #Products
        SELECT distinct Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END  
    --EndIf
    INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
        JOIN #Products p on ps.Prod_Id = p.Prod_Id 
        JOIN #Prod_Units pu ON pu.PU_Id = ps.PU_Id
       WHERE (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
               OR ps.End_Time BETWEEN @Start_Time AND @End_Time                 
               OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
             ) 
    END
--EndIf @QueryType ...
-- Retrieve SQL-Capable Statistics (Original Products)
SELECT @Average = AVG(ed.Dimension)
     , @Min     = MIN(ed.Dimension)
     , @Max     = Max(ed.Dimension)
     , @Total   = SUM(ed.Dimension)
     , @Count   = COUNT(ed.Dimension)
  FROM #Event_Details ed
  JOIN Events e on e.Event_Id = ed.Event_Id 
  JOIN #Prod_Starts ps On ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
   AND ps.PU_Id = e.PU_Id
If @ExtraCalcs = 1  --(Original Products)
  BEGIN
    DECLARE TCursor INSENSITIVE CURSOR 
        FOR (SELECT e.PU_Id, e.TimeStamp, ed.Dimension 
               FROM #Event_Details ed 
               JOIN Events e on e.Event_Id = ed.Event_Id
               JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)    
                AND ps.PU_Id = e.PU_Id
            )
        FOR READ ONLY
    GOTO OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF
  END
--EndIf
GOTO DO_FINAL_RETRIEVAL
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
RETRIEVE_WITH_APPLIED_PRODUCT_FILTER:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Get Relevant information from production_Starts for any product in the specified time range.
  INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM Production_starts ps
      JOIN #Prod_Units pu ON pu.PU_Id = ps.PU_Id
     WHERE (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
             OR (ps.End_Time BETWEEN @Start_Time AND @End_Time) 
             OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
           ) 
  --Grab all of the "Specified" to filter product(s) filter, put them into Temp Table #Products
  BEGIN      
    If @QueryType = @Group
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
      END
    Else If @QueryType = @Characteristic
      BEGIN
         INSERT INTO #Products
         SELECT DISTINCT Prod_Id FROM Pu_Characteristics WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
      END
    Else If @QueryType = @GroupAndProperty
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
 	  INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE Prop_Id = @Prop_Id AND char_id = @Char_Id
      END
    Else -- must be @OneProductFilter
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id = @Prod_Id
      END
    --EndIf
  END
  -- RETRIEVE RESULTSET BASED ON WHETHER OR NOT "Applied Products" information is asked for.
  -- NOTE:  Definition of matched "Applied Products" from Events Table.  
  --        When matched product has Applied_Product = NULL, we take that the original product is applied product.
  --        When matched product has Applied_Product <> NULL, include that product as applied product
  -- NOTE2: JOIN condition for Production_Starts consistent with AutoLog's
  -- NOTE3: Event_Details.TimeStamp are exactly the same as Events.TimeStamp. Must use Event_Id to join: Mt/5-20-2002
  INSERT INTO #Applied_Products
      --SELECT e.Pu_Id, e.TimeStamp, ps.Prod_Id, e.Applied_Product 
      SELECT e.Pu_Id, e.Event_Id, ps.Prod_Id, e.Applied_Product 
        FROM Events e
        JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Applied_Product Is NOT NULL
       WHERE e.TimeStamp BETWEEN @Start_Time AND @End_Time
    UNION
      SELECT e.Pu_Id, e.Event_Id, ps.Prod_Id, e.Applied_Product 
        FROM Events e
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
       WHERE e.TimeStamp BETWEEN @Start_Time AND @End_Time
  --Collect Database retrievable statistics ( Applied Products )
  SELECT @Average = AVG(ed.Dimension)
       , @Min     = MIN(ed.Dimension)
       , @Max     = Max(ed.Dimension)
       , @Total   = SUM(ed.Dimension)
       , @Count   = COUNT(ed.Dimension)
    FROM #Event_Details ed
    JOIN #Applied_Products ap On ap.Event_Id = ed.Event_Id AND ap.PU_Id = e.PU_Id
  If @ExtraCalcs = 1  -- (Applied Products)
    BEGIN
      DECLARE TCursor INSENSITIVE CURSOR 
          FOR (SELECT e.PU_Id, e.TimeStamp, ed.Dimension
                 FROM #Event_Details ed 
                 JOIN Events e on e.Event_Id = ed.Event_Id
                 JOIN #Applied_Products ap On ap.Event_Id = ed.Event_Id AND ap.PU_Id = e.PU_Id
              )
          FOR READ ONLY
      GOTO OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF
    END
  --EndIf
  GOTO DO_FINAL_RETRIEVAL
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
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
       , TimeOfMinimum     = dbo.fnServer_CmnConvertFromDBTime(@TimeOfMin,@InTimeZone)
       , TimeOfMaximum     = dbo.fnServer_CmnConvertFromDBTime(@TimeOfMax,@InTimeZone)  
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #Event_Details
  DROP TABLE #Prod_Starts 
  DROP TABLE #Products
  DROP TABLE #Applied_Products
  DROP TABLE #Prod_Units

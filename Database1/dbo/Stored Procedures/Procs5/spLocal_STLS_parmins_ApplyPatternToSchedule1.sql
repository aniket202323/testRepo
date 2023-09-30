/*  
Name: spLocal_STLS_parmins_ApplyPatternToSchedule1  
Purpose: Apply a pattern to the crew schedule.  
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version: 1.2
---------------------------------------------------------------------------------------------------------------------------------------  
Build#8
Modified by Vinayak Pate
Date: 31 Jan 2008
Change: Follower units to follow master unit
maintain proficy standards be removing t ransactions and l ocks
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Debbie Linville  
On 30-Oct-02   Version 1.0.1  
Change :  Use times from pattern to check for overlaps  
---------------------------------------------------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Rajnikant Kapadia 
On 13-Dec-05   Version 1.0.2
Change :  STLS change UID -2, Added nDayChange variable to add 1 day in startdatetime whenever there is a day change in 
	  second shift.
--------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001  

*/  
  
CREATE   PROCEDURE [dbo].[spLocal_STLS_parmins_ApplyPatternToSchedule1]  
--Parameters  
  @StartTime VARCHAR(35) OUTPUT,  
  @EndTime VARCHAR(35) OUTPUT,  
  @Pattern VARCHAR(32),  
  @StartWithDay INT,  
  @UnitDesc VARCHAR(50)  
 --TEST  
 --SET @StartTime = '01 Jan 2001'  
 --SET @EndTime = '07 Jan 2001'  
 ---SET @Pattern = 'PatternB'  
 --SET @StartWithDay = '1'  
 --SET @UnitDesc = 'CR15AW Converter'  
AS  
--------------------------------------------------------  
--------------------------------------------------------  
--Local Variables  
DECLARE @PatternID INT  
DECLARE @nTotalDaysInPattern INT  
DECLARE @nTimeFrameDays INT  
DECLARE @nUnitID INT  
  
DECLARE @nEntirePatternLoop INT  
DECLARE @nTotalDayCounter INT  
DECLARE @nPatternDay INT  
DECLARE @nEndPatternDay INT  
  
DECLARE @nShiftsPerDay INT  
DECLARE @nShift INT  
DECLARE @nMaxShift INT  
  
DECLARE @vcStartDateTime VARCHAR(35)  
DECLARE @nTeamID INT  
DECLARE @vcTeamName VARCHAR(10)  
DECLARE @vcStartDateandTime VARCHAR(35)  
DECLARE @dtStartDateandTime DATETIME  
DECLARE @dtStartDateandTime1 DATETIME  
DECLARE @dtStartDateandTime2 DATETIME  -- added by vinayak for correcting deletion logic
DECLARE @dtStartDateandTime3 DATETIME  -- added by vinayak for follower logic
DECLARE @vcEndDateandTime VARCHAR(35)  
DECLARE @dtEndDateandTime DATETIME  
DECLARE @dtEndDateandTime1 DATETIME  
DECLARE @dtEndDateandTime2 DATETIME -- added by vinayak for correcting deletion logic 
DECLARE @nPatternDayChange INT  
DECLARE @charPatternStartTime CHAR(5)  
DECLARE @charPatternEndTime CHAR(5)  

--***Added STLS Change UID -2 *******************
--***By : Rajnikant on 13-Dec-2005 **************
DECLARE @nDayChange INT
--***********************************************

DECLARE	 @MasterUnitId INT	-- Vinayak Follower Logic
--Get Master Unit ID
SET @MasterUnitId = (SELECT Distinct PU_Id FROM Prod_Units WHERE PU_Desc = @UnitDesc)



SET @dtStartDateandTime = CAST(@StartTime as DATETIME)  
SET @dtEndDateandTime = CAST(@EndTime as DATETIME)  
  
--**********************************  
  
 SET @nEntirePatternLoop = 1  
 SET @nTotalDayCounter = 1  
  
 SET @nPatternDay = @StartWithDay  
  
   
--Get Pattern ID  
 SET @PatternID =  (SELECT PatternID  
    FROM Local_PG_Patterns  
    WHERE PatternName = @Pattern)  
  
    
-- Test to make sure that StartWithDay does not exceed total # days in pattern   
 SET @nTotalDaysInPattern = (SELECT PatternDays  
    FROM Local_PG_Patterns  
    WHERE PatternID = @PatternID)  
------------------------------------------------------------  
  
 IF @StartWithDay > @nTotalDaysInPattern  
  BEGIN  
  RETURN 2  
  END  
  
--  Get Total Days for Loop Counter  
 SET @nTimeFrameDays = DATEDIFF(DAY, @dtStartDateandTime, @dtEndDateandTime)   
  
  
-- Get Pattern Start Time
 SET @charPatternStartTime = (SELECT StartTime  
     FROM Local_PG_Pattern_Schedule
     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
     AND Local_PG_Pattern_Schedule.PatternDayID = @nPatternDay  
     AND Local_PG_Pattern_Schedule.ShiftId = 1)  
  
-- Get Pattern End Day  
 SET @nEndPatternDay = @nPatternDay + (@nTimeFrameDays  % @nTotalDaysInPattern)  
 IF @nEndPatternDay > @nTotalDaysInPattern  
  BEGIN  
  SET @nEndPatternDay = @nEndPatternDay - @nTotalDaysInPattern  
  END  
  
-- Get Pattern End Time  
        SET @nMaxShift = (SELECT max(Local_PG_Pattern_Schedule.ShiftId)  
             FROM Local_PG_Pattern_Schedule  
      WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
        AND Local_PG_Pattern_Schedule.PatternDayID = @nEndPatternDay)  
  
 SET @charPatternEndTime = (SELECT EndTime  
     FROM Local_PG_Pattern_Schedule  
     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
     AND Local_PG_Pattern_Schedule.PatternDayID = @nEndPatternDay  
     AND Local_PG_Pattern_Schedule.ShiftId = @nMaxShift)  
  
 SET @nPatternDayChange = (SELECT DayChangeFlag  
     FROM Local_PG_Pattern_Schedule  
     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
     AND Local_PG_Pattern_Schedule.PatternDayID = @nEndPatternDay  
     AND Local_PG_Pattern_Schedule.ShiftId = @nMaxShift)  
  
--  Get Unit ID  
 SET @nUnitID = (SELECT PU_Id  
   FROM Prod_Units  
   WHERE PU_Desc = @UnitDesc)  
  
--  Test for existing, overlapping records  
 SET @vcStartDateandTime = CONVERT(VARCHAR,@dtStartDateandTime, 113)  
 SET @vcStartDateandTime = LEFT(@vcStartDateandTime, (LEN(@vcStartDateandTime) - 13))  
 SET @StartTime = @vcStartDateandTime + ' 00:00:00:000'   	-- vinayak Start Day from 00:00 
 SET @dtStartDateandTime2 = CAST(@StartTime as DATETIME)  	-- vinayak Start Day from 00:00
 SET @vcStartDateandTime = @vcStartDateandTime + ' ' + @charPatternStartTime + ':00:000'   
 SET @dtStartDateandTime1 = CAST(@vcStartDateandTime as DATETIME)  
 SET @dtStartDateandTime3 = @dtStartDateandTime1  		-- vinayak store for follower / deletion logic
   
 SET @vcEndDateandTime = CONVERT(VARCHAR,@dtEndDateandTime, 113)  
 SET @vcEndDateandTime = LEFT(@vcEndDateandTime, (LEN(@vcEndDateandTime) - 13))  

 SET @EndTime = @vcEndDateandTime + ' 00:00:00:000' 		-- vinayak End Day till 00:00
 SET @dtEndDateandTime2 = CAST(@EndTime as DATETIME)  		-- vinayak End Day till 00:00
 SET @dtEndDateandTime2 = DATEADD(DAY, 1, @dtEndDateandTime2)  	-- vinayak End Day till 24:00

 SET @vcEndDateandTime = @vcEndDateandTime + ' ' + @charPatternEndTime + ':00:000'   
 SET @dtEndDateandTime1 = CAST(@vcEndDateandTime as DATETIME)  

 IF @nPatternDayChange = 1  
  BEGIN  
  SET @dtEndDateandTime1 = DATEADD(DAY, 1, @dtEndDateandTime1)  
  SET @vcEndDateandTime = CONVERT(VARCHAR,@dtEndDateandTime, 113)  
  SET @dtEndDateandTime2 = @dtEndDateandTime1 			-- vinayak End Day till pattern end
  END  

   
 SELECT DISTINCT CS_Id  -- vinayak distinct ID's
 FROM Crew_Schedule  
 WHERE 
 (
	(Crew_Schedule.Start_Time >= @dtStartDateandTime2  	-- vinayak Start day 00:00 to
   	AND Crew_Schedule.Start_Time <  @dtEndDateandTime2)  -- vinayak higher of end day till 24:00 OR end day till pattern end time on next day
	  OR  
  	(Crew_Schedule.End_Time >  @dtStartDateandTime3  	-- vinayak Start day from Pattern start time to
   	AND Crew_Schedule.End_Time <= @dtEndDateandTime2)  	-- vinayak higher of end day till 24:00 OR end day till pattern end time on next day
  )  
  AND  
  PU_Id = @nUnitID  
  
  
--  If Rowcount > 0, overlapping records exist.  Return 1 and exit.  
 IF @@ROWCOUNT > 0  
  BEGIN  
  RETURN 1  
  END  
 

-- Added below Follower module for follower units by vinayak 
-- Get Followers List
DECLARE @MyTableVar TABLE (FU_ID integer)	-- This stores the unit id's of follower units
	INSERT INTO @MyTableVar 
         SELECT PU.PU_Id FROM Tables T (NOLOCK) INNER JOIN Table_Fields_Values TFV (NOLOCK) 
                ON T.TableId = TFV.TableId INNER JOIN Table_Fields TF (NOLOCK) ON 
                TFV.Table_Field_Id = TF.Table_Field_Id INNER JOIN Prod_Units PU (NOLOCK) ON 
                TFV.KeyId = PU.PU_Id INNER JOIN Prod_Units PU_1 (NOLOCK) ON TFV.Value = 
                CAST(PU_1.PU_Id as varchar)
         WHERE (T.TableName = 'Prod_Units') AND (TF.Table_Field_Desc = 'STLS_ST_MASTER_UNIT_ID') 
                AND (PU_1.PU_Id = @MasterUnitId)



-- Follower List available

-- Delete Follower crew scheduele for the given period (because Master has no overlap records)
	DELETE						
	FROM Crew_Schedule
	WHERE
	(
		(Crew_Schedule.Start_Time >= @dtStartDateandTime2  	-- vinayak Start day 00:00 to
   		AND Crew_Schedule.Start_Time <  @dtEndDateandTime2)  -- vinayak higher of end day till 24:00 OR end day till pattern end time on next day
		OR  
	  	(Crew_Schedule.End_Time >  @dtStartDateandTime3  	-- vinayak Start day from Pattern start time to
   		AND Crew_Schedule.End_Time <= @dtEndDateandTime2)  	-- vinayak higher of end day till 24:00 OR end day till pattern end time on next day
  	)  
  	AND Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
-- Follower module ends


--Begin Looping through days  
WHILE @nTotalDayCounter <= (@nTimeFrameDays + 1)  
  BEGIN  
  
--***Added STLS Change UID -2 *******************
--***By : Rajnikant on 13-Dec-2005 **************
  SET @nDayChange = 0
--***********************************************
 
  SET @nShiftsPerDay = 0  
  SET @nShift = 1  
  --Count shifts per this day, if any  
  SELECT PatternDayID  
  FROM Local_PG_Pattern_Schedule  
  WHERE PatternDayID = @nPatternDay  
  AND PatternID = @PatternID  
  --Count  
  SET @nShiftsPerDay = @@ROWCOUNT  
     
	IF @nShiftsPerDay > 0  
	  BEGIN  
  
		WHILE @nShift <= @nShiftsPerDay  
    		  BEGIN  
  
		    --Get Team Name  
		    SET @vcTeamName = (SELECT TeamName  
		     FROM Local_PG_Teams  
		     JOIN Local_PG_Pattern_Schedule ON Local_PG_Teams.TeamID = Local_PG_Pattern_Schedule.TeamID  
		     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
		     AND Local_PG_Pattern_Schedule.PatternDayID = @nPatternDay  
		     AND Local_PG_Pattern_Schedule.ShiftId = @nShift)  
  
		    --Get Start Date and Time  
		    SET @charPatternStartTime = (SELECT StartTime  
		     FROM Local_PG_Pattern_Schedule  
		     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
		     AND Local_PG_Pattern_Schedule.PatternDayID = @nPatternDay  
		     AND Local_PG_Pattern_Schedule.ShiftId = @nShift)  
		     
		    SET @charPatternEndTime = (SELECT EndTime  
		     FROM Local_PG_Pattern_Schedule  
		     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
		     AND Local_PG_Pattern_Schedule.PatternDayID = @nPatternDay  
		     AND Local_PG_Pattern_Schedule.ShiftId = @nShift)  
		      
		    SET @nPatternDayChange = (SELECT DayChangeFlag  
		     FROM Local_PG_Pattern_Schedule  
		     WHERE Local_PG_Pattern_Schedule.PatternID = @PatternID  
		     AND Local_PG_Pattern_Schedule.PatternDayID = @nPatternDay  
		     AND Local_PG_Pattern_Schedule.ShiftId = @nShift)  
		  
		---------------------------------------------------------------  
		    SET @vcStartDateandTime = CONVERT(VARCHAR,@dtStartDateandTime, 113)  
		    SET @vcStartDateandTime = LEFT(@vcStartDateandTime, (LEN(@vcStartDateandTime) - 13))  
		    SET @vcStartDateandTime = @vcStartDateandTime + ' ' + @charPatternStartTime + ':00:000'   
		    SET @dtStartDateandTime1 = CAST(@vcStartDateandTime as DATETIME)  
		    SET @dtStartDateandTime1 = DATEADD(DAY, (@nTotalDayCounter - 1), @dtStartDateandTime1)  

		--***Added STLS Change UID -2 *******************
		--***By : Rajnikant on 13-Dec-2005 **************
		    IF @nDayChange = 1 
		     BEGIN	
		     SET @dtStartDateandTime1 = DATEADD(DAY, 1, @dtStartDateandTime1)  	
		     END
		--***********************************************

		    SET @vcEndDateandTime = CONVERT(VARCHAR,@dtStartDateandTime1, 113)  
		    SET @vcEndDateandTime = LEFT(@vcEndDateandTime, (LEN(@vcEndDateandTime) - 13))  
		    SET @vcEndDateandTime = @vcEndDateandTime + ' ' + @charPatternEndTime + ':00:000'   
		    SET @dtEndDateandTime1 = CAST(@vcEndDateandTime as DATETIME)  

		--***Added STLS Change UID -2 *******************
		--***By : Rajnikant on 13-Dec-2005 **************
		
		    IF ( ( @nPatternDayChange = 1) AND (@nDayChange = 0 ) )
		     BEGIN  
		     SET @nDayChange = 1
		--***********************************************
		     SET @dtEndDateandTime1 = DATEADD(DAY, 1, @dtEndDateandTime1)  
		     END  
  
		--INSERT  with Follower 
			INSERT INTO Crew_Schedule (Start_Time,End_Time,PU_Id,Crew_Desc,Shift_Desc)  
		--    VALUES(@dtStartDateandTime1,@dtEndDateandTime1,@nUnitID,@vcTeamName,CAST(@nShift AS CHAR(1)))  
			SELECT @dtStartDateandTime1,@dtEndDateandTime1,FU_ID,@vcTeamName,CAST(@nShift AS CHAR(1))
			FROM @MyTableVar


		    SET @nShift = @nShift + 1  
		END  -- End Inner while loop of @nShift
	END  -- End IF module of @nShiftsPerDay 
  
	   SET @nTotalDayCounter = @nTotalDayCounter + 1  
	   SET @nPatternDay = @nPatternDay + 1  
	   IF @nPatternDay > @nTotalDaysInPattern  
	     BEGIN  
	     SET @nPatternDay = 1  
	     SET @nEntirePatternLoop = @nEntirePatternLoop +1  
	   END  
  
END -- End Outer While Loop of @nTotalDayCounter 

  
 IF @@ERROR > 0  
   BEGIN  
   RAISERROR('Insert Pattern to Shedule failed (1).', 16, 1)  
   RETURN 99  
   END  
   
  
RETURN 0




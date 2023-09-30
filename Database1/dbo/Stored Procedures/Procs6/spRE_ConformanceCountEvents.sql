-- Rename spRE_ConformanceCountEvents to spRE_ConformanceCountEvents without code change to maintain unified format spRE_Conformance___
-- ECR #27312 (mt/1-20-2004) create new Conformance webpackage
-- ECR #29451(mt/3-30-2005) - Correct event status in where clause to include only 10(Broke-Inv) and 12 (Broke-Cns)
--
CREATE PROCEDURE dbo.spRE_ConformanceCountEvents
 	   @Master_Unit  Int
 	 , @Prod_Id      Int
 	 , @Start_Time   DateTime
 	 , @End_Time     DateTime
 	 , @EventCount   Int OUTPUT
 	 , @RejectCount  Int OUTPUT
AS
DECLARE @TempE        Int
DECLARE @TempR        Int 
SELECT @EventCount    = 0
SELECT @RejectCount   = 0
If @Prod_Id is NOT NULL
  BEGIN
    CREATE TABLE #TempStarts (start_time datetime, end_time datetime NULL)
    INSERT INTO #TempStarts
      SELECT PS.start_time, PS.end_time
      FROM production_starts PS 
      WHERE  (PS.PU_id = @Master_Unit) AND
             (PS.Prod_id = @Prod_Id) AND 
             ((PS.Start_Time <= @Start_Time AND PS.End_Time IS NULL) OR
              (PS.Start_Time <= @Start_Time AND PS.End_Time > @Start_Time) OR
              (PS.Start_Time > @Start_Time AND PS.End_Time < @End_Time) OR
              (PS.Start_Time > @Start_Time AND PS.Start_Time < @End_Time))
     SELECT @TempE = COUNT(Event_id) 
       FROM Events EV
       JOIN #TempStarts ps On EV.Timestamp >= ps.Start_Time and ((EV.TimeStamp < ps.end_time) or (ps.end_time is null)) 
       WHERE (EV.pu_id = @Master_Unit) and 
             (EV.timestamp >= @Start_Time AND EV.timestamp < @End_Time)
 	  	     
     SELECT @TempR = COUNT(Event_id) 
       FROM Events EV
       JOIN #TempStarts ps On EV.Timestamp >= ps.Start_Time and ((EV.TimeStamp < ps.end_time) or (ps.end_time is null)) 
       WHERE (EV.pu_id = @Master_Unit) and 
             (EV.timestamp >= @Start_Time AND EV.timestamp < @End_Time) and
             ((EV.event_status = 10) or (EV.Event_Status = 12) or (ev.Applied_Product Is NOT NULL))      --ECR #29451
             --((EV.event_status = 8) or (EV.Event_Status = 12) or (ev.Applied_Product Is NOT NULL))     --ECR #29451
     DROP TABLE #TempStarts
  END
Else
  BEGIN
     SELECT @TempE = COUNT(Event_id) 
       FROM Events EV
       WHERE (EV.pu_id = @Master_Unit) and 
             (EV.timestamp >= @Start_Time AND EV.timestamp < @End_Time)
           	  	     
     SELECT @TempR = COUNT(Event_id) 
       FROM Events EV
       WHERE (EV.pu_id = @Master_Unit) and 
             (EV.timestamp >= @Start_Time AND EV.timestamp < @End_Time) and
             ((EV.event_status = 10) or (EV.Event_Status = 12) or (ev.Applied_Product Is NOT NULL))      --ECR #29451
             --((EV.event_status = 8) or (EV.Event_Status = 12) or (ev.Applied_Product Is NOT NULL))     --ECR #29451
  END
--EndIf
If @TempE Is NULL SELECT @EventCount  = 0 Else SELECT @EventCount  = @TempE
If @TempR Is NULL SELECT @RejectCount = 0 Else SELECT @RejectCount = @TempR

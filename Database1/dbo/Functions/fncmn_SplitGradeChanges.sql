CREATE FUNCTION [DBO].[fncmn_SplitGradeChanges](@StartTime DateTime,@EndTime DateTime,@Unit INT)
 	 RETURNS @EventSplits TABLE (ProductKey int, StartTime datetime, EndTime datetime)
Begin
--**********************************************/
DECLARE @GradeSliceTable Table (Id Int Identity(1,1),Start_Time DateTime,End_Time DateTime,Prod_Key  int)
DECLARE @APTable Table (Id Int Identity(1,1),Start_Time DateTime,End_Time DateTime,Prod_Key  int)
DECLARE @EventAPSliceTable Table (Id Int Identity(1,1),Start_Time DateTime ,End_Time DateTime,Prod_Key int)
DECLARE @UnitTable Table (Unit_Key Int)
DECLARE @MaxId 	  	  	  	  	 INT
DECLARE @MinId 	  	  	  	  	 INT
DECLARE @ST 	  	  	  	  	  	 DateTime
DECLARE @ET 	  	  	  	  	  	 DateTime
DECLARE @ProdKey 	  	  	  	 INT
DECLARE @CurrentSplitTime 	  	 DATETIME
DECLARE @MinStartTime 	  	  	 DATETIME
DECLARE @MinEndTime 	  	  	  	 DATETIME
DECLARE @PrevStartTime 	  	  	 DATETIME
DECLARE @PrevEndTime 	  	  	 DATETIME
DECLARE @PrevProdKey 	  	  	 INT
DECLARE @AdjustedStartTime 	  	 DATETIME
DECLARE @AdjustedEndTime 	  	 DATETIME
DECLARE @ProductionVariable 	  	 INT
DECLARE @ProductionVariableType INT
DECLARE @CheckEventsFlag 	  	 INT
DECLARE @MaxEventTimestamp 	  	 datetime, @MinEventTimestamp datetime
Select @CheckEventsFlag = 1
/*------------------------------------------------------
-- Check For Production Variable and Type
et_id et_desc
----- --------------------------------------------------
0     Time
1     Production Event
------------------------------------------------------*/
select @ProductionVariable = Production_Variable from prod_units where PU_ID = @Unit
If @ProductionVariable Is Not Null
Begin
 	 Select @ProductionVariableType = Event_Type From Variables Where Var_Id = @ProductionVariable
 	 -- If it is a Time-Based variable, then do not check for Events.  Just use Production_Starts
 	 If @ProductionVariableType = 0  Select @CheckEventsFlag = 0
End
insert into @UnitTable(Unit_Key) 
values(@Unit)
------------------------------------------------------
-- Get Production Starts
------------------------------------------------------
INSERT INTO  @GradeSliceTable  (Start_Time ,End_Time,Prod_Key)
SELECT  Start_Time = CASE WHEN Start_Time < @StartTime THEN @StartTime ELSE Start_Time END,
 	 End_Time   = CASE WHEN End_Time Is Null THEN @EndTime 
 	 WHEN End_Time > @EndTime THEN @EndTime ELSE End_Time END,
 	 Prod_Id
FROM Production_Starts  a
Join @UnitTable b On b.Unit_Key = a.PU_ID
WHERE  Start_Time <= @EndTime
AND (End_Time >  @StartTime or End_Time Is Null)
Order by Start_Time
if @CheckEventsFlag = 0
Begin
 	 Goto PROC_END
End
------------------------------------------------------
-- Looking for Events With Applied Product
------------------------------------------------------
INSERT INTO @EventAPSliceTable (Start_Time,End_Time,Prod_Key)
select Start_Time, Timestamp, Applied_Product
From Events 
where PU_ID = @Unit
 	 and Timestamp < @EndTime and timestamp >= @StartTime
Order By Timestamp
Select @MinEventTimestamp = Min(End_Time) From @EventAPSliceTable
Select @MaxEventTimestamp = Max(End_Time) From @EventAPSliceTable
------------------------------------------------------
-- Get Next Occuring Event
------------------------------------------------------
INSERT INTO @EventAPSliceTable (Start_Time,End_Time,Prod_Key)
select top 1 Start_Time, Timestamp, Applied_Product
From Events 
where PU_ID = @Unit
 	 and Timestamp > @MaxEventTimestamp
Order By Timestamp
/*
Select @MinEventTimestamp
print 'select * from @EventAPSliceTable'
select * from @EventAPSliceTable
print 'select * from @GradeSliceTable'
select * from @GradeSliceTable
*/
------------------------------------------------------
-- This is a fix for events with NO Start_Time
------------------------------------------------------
if (select count(*) From @EventAPSliceTable where Start_Time Is Null ) > 0
Begin
 	 Update O 
 	  	  Set O.Start_Time = P.End_Time
 	  	  From @EventAPSliceTable p 
 	  	  Join @EventAPSliceTable O on O.ID = P.ID + 1
 	  	 Where O.Start_Time Is Null
 	 Update @EventAPSliceTable 
 	 Set Start_Time = (select max(timestamp) from Events where pu_ID = @Unit and timestamp < @MinEventTimestamp)
 	 where Start_Time Is NULL
End
------------------------------------------------------
-- Slide Production_Start Times To Align With Event Times
------------------------------------------------------
SELECT @MinId = 1
SELECT @MaxId = MAX(Id) From @GradeSliceTable
IF @MaxId IS NULL SELECT @MaxId = 0
WHILE @MinId <= @MaxId
BEGIN
 	 SELECT @ST = Start_Time FROM @GradeSliceTable WHERE Id = @MinId
 	 SELECT @AdjustedStartTime = Null
 	 SELECT @AdjustedStartTime = Start_Time FROM @EventAPSliceTable WHERE  Start_Time < @ST And End_Time >  @ST 
 	 IF @AdjustedStartTime Is Not NULL
 	 BEGIN
 	  	   IF @AdjustedStartTime < @StartTime SELECT @AdjustedStartTime = @StartTime
 	  	   UPDATE @GradeSliceTable Set Start_Time = @AdjustedStartTime Where Id = @MinId
 	  	   UPDATE @GradeSliceTable Set End_Time = @AdjustedStartTime Where Id = @MinId - 1
 	 END
 	 SELECT @MinId = @MinId + 1
END
------------------------------------------------------
-- Copy Applied Product Data
------------------------------------------------------
INSERT INTO @APTable(Start_Time, End_Time, Prod_Key)
SELECT Start_Time = Case When Start_Time < @StartTime Then @STartTime Else Start_Time End,
 	 End_Time = Case When End_Time > @EndTime then @EndTime Else End_Time End,
Prod_Key
FROM  @EventAPSliceTable
WHERE Prod_Key Is Not Null
------------------------------------------------------
-- Reconcile Grade Slices
------------------------------------------------------
DECLARE @X Int
DECLARE @X2 Int
DECLARE @CurrentET      DateTime
SELECT @MinId = 1
SELECT @MaxId = MAX(Id) From @APTable
IF @MaxId IS NULL SELECT @MaxId = 0
WHILE @MinId <= @MaxId
BEGIN
    SELECT @X = Null,@X2 = Null
    SELECT @ST = Start_Time,@ET = End_Time,@ProdKey = Prod_Key FROM @APTable WHERE Id = @MinId
    SELECT @X = Id, @PrevEndTime = End_Time, @PrevProdKey = Prod_Key
          FROM @GradeSliceTable 
          WHERE Start_Time <= @ST And End_Time >= @ET
 	  	   
    IF @X Is Not Null -- inside split
    BEGIN
          UPDATE @GradeSliceTable SET End_Time = @ST WHERE Id = @X
          INSERT INTO @GradeSliceTable(Start_Time,End_Time,Prod_Key)  SELECT @ST,@ET,@ProdKey
          INSERT INTO @GradeSliceTable(Start_Time,End_Time,Prod_Key)  SELECT @ET,@PrevEndTime,@PrevProdKey 
    END
    SELECT @MinId = @MinId + 1
END
DELETE FROM @GradeSliceTable where End_Time <= Start_Time 
PROC_END:
update @GradeSliceTable Set Start_Time = @StartTime where Start_Time < @StartTime
------------------------------------------------------
-- Return Modified Grade Slice Table
------------------------------------------------------
INSERT INTO @EventSplits (ProductKey,StartTime,EndTime)
    SELECT Prod_Key,Start_Time,End_Time 
 	 FROM @GradeSliceTable
 	 Order by Start_Time
 	 
-- 	 select * from @GradeSliceTable Order by Start_Time
--/**************************
      RETURN
END


CREATE PROCEDURE dbo.spActivities_GetVariableStatistics
@ActivityId int

 AS

DECLARE @ReturnSize Int = 20
DECLARE @KeyId DateTime, @KeyId1 Int, @PU_Id Int, @ActivityProductId Int, @ActivityEndTime DateTime
DECLARE @SheetId Int, @Title NVarchar(50), @ActivityTypeId Int
DECLARE @Variables Table(varId Int,VarOrder Int,Title NVarchar(50), PUId Int)
DECLARE @ActivityData TABLE (ActivityId Int, KeyId1 Int, KeyId DateTime)
DECLARE @VariableData TABLE (ActivityId Int, VariableId Int, Result Float, DataTypeId Int)
DECLARE @RowOrderedData TABLE (VariableId Int, Result Float, RowAsc Int, RowDesc Int, TopHalfRowAsc Int, BottomHalfRowDesc Int)
DECLARE @Median TABLE (VariableId Int, Median Float)
DECLARE @UpperQuartile TABLE (VariableId Int, UpperQuartile Float)
DECLARE @LowerQuartile TABLE (VariableId Int, LowerQuartile Float)
DECLARE @ReturnSet TABLE (VariableId Int, Maximum Float, Minimum Float, Average Float, Median Float, UpperQuartile Float, LowerQuartile Float, DataTypeId Int)

SELECT @KeyId = KeyId,
	@KeyId1 = KeyId1,
	@SheetId = Sheet_Id,
	@Title = ISNULL(Title,''),
	@ActivityTypeId = Activity_Type_Id
FROM Activities (nolock) 
Where Activity_Id = @ActivityId

--Get Variables for this Activity
INSERT INTO @Variables(varId, VarOrder, Title)
SELECT varId,VarOrder,Title FROM dbo.fnActivities_GetVariablesForActivity(@ActivityId) 

UPDATE a 
SET a.PUID = Coalesce(c.Master_Unit,c.PU_Id)
FROM @Variables a 
JOIN Variables_Base b (nolock) on a.VarId = b.Var_Id 
JOIN Prod_Units_Base c (nolock) on c.PU_Id = b.PU_Id 

IF Not Exists(SELECT 1 FROM @Variables) 
BEGIN
	Select 'Error - No Variables Found'
	RETURN
END
IF (SELECT Count(Distinct (PUId)) FROM @Variables) != 1
BEGIN
	Select 'Error - Mixed  Units not currently supported'
	RETURN
END

SELECT @PU_Id = MIN(PUId) FROM @Variables

--Get the actual time from the Event itself
IF @ActivityTypeId IN (1,4,5) --Timed Event, Procuct change event, process order change event
BEGIN
	SELECT @ActivityEndTime = @KeyId
END
ELSE IF @ActivityTypeId = 2 --Production Event
BEGIN
	SELECT @ActivityEndTime = e.Timestamp
	FROM Events e (nolock)
	WHERE e.Event_Id = @KeyId1
END
ELSE IF @ActivityTypeId = 3 --User Define Event
BEGIN
	SELECT @ActivityEndTime = e.End_Time
	FROM User_Defined_Events e (nolock) 
	WHERE e.UDE_Id = @KeyId1
END
ELSE
BEGIN
	Select 'Error - Activity Type not supported'
END

SELECT @ActivityProductId = ps.Prod_Id
FROM production_starts ps (nolock)
WHERE ps.PU_Id = @PU_Id
	AND (@ActivityEndTime >= Start_Time AND (@ActivityEndTime < End_Time OR End_Time is null))


	

IF @ActivityTypeId = 2
Begin
	;WITH ProdStarts As (Select Start_Time,End_Time, Pu_Id,Prod_Id from Production_Starts ps (nolock) where  (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
	AND ps.Prod_Id = @ActivityProductId AND End_time is not null
	union
	Select Start_Time,cast('9999-12-31' as datetime) End_Time, Pu_Id,Prod_Id from Production_Starts ps (nolock) where  (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
	AND ps.Prod_Id = @ActivityProductId AND End_time is null
	)
	INSERT INTO @ActivityData (ActivityId, KeyId1, KeyId)
	SELECT TOP (@ReturnSize) a.Activity_Id, a.KeyId1, a.KeyId
	FROM Activities a (nolock)
	--LEFT JOIN Events e (nolock) on e.Event_Id = a.KeyId1
	INNER JOIN /*ProdStarts*/Production_Starts ps (nolock) on (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
		AND ps.Prod_Id = @ActivityProductId
		AND (a.KeyId  >= ps.Start_Time AND (a.KeyId < ps.End_Time or ps.End_Time is null) )
	WHERE a.Sheet_Id = @SheetId
		AND a.KeyId < @ActivityEndTime
		AND ISNULL(Title,'') = @Title
		AND Activity_Status = 3
		--AND PercentComplete = 100
	Order by KeyId Desc	
	
End
ELSE IF @ActivityTypeId = 3
Begin
	;WITH ProdStarts As (Select Start_Time,End_Time, Pu_Id,Prod_Id from Production_Starts ps (nolock) where  (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
	AND ps.Prod_Id = @ActivityProductId AND End_time is not null
	union
	Select Start_Time,cast('9999-12-31' as datetime) End_Time, Pu_Id,Prod_Id from Production_Starts ps (nolock) where  (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
	AND ps.Prod_Id = @ActivityProductId AND End_time is null
	)

	INSERT INTO @ActivityData (ActivityId, KeyId1, KeyId)
	SELECT TOP (@ReturnSize) a.Activity_Id, a.KeyId1, e2.End_Time
	FROM Activities a (nolock)
	LEFT JOIN User_Defined_Events e2 (nolock) on e2.UDE_Id = a.KeyId1
	INNER JOIN ProdStarts/*Production_Starts*/ ps (nolock) on (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
		AND ps.Prod_Id = @ActivityProductId
		AND (a.KeyId  >= ps.Start_Time 
			AND a.KeyId < ps.End_Time )
	WHERE a.Sheet_Id = @SheetId
		AND a.KeyId < @ActivityEndTime
		AND ISNULL(Title,'') = @Title
		AND Activity_Status = 3
		--AND PercentComplete = 100
	Order by KeyId Desc
End
Else
Begin
	;WITH ProdStarts As (Select Start_Time,End_Time, Pu_Id,Prod_Id from Production_Starts ps (nolock) where  (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
		AND ps.Prod_Id = @ActivityProductId AND End_time is not null
		union
		Select Start_Time,cast('9999-12-31' as datetime) End_Time, Pu_Id,Prod_Id from Production_Starts ps (nolock) where  (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
		AND ps.Prod_Id = @ActivityProductId AND End_time is null
		)
	INSERT INTO @ActivityData (ActivityId, KeyId1, KeyId)
	SELECT TOP (@ReturnSize) a.Activity_Id, a.KeyId1, a.KeyID
	FROM Activities a (nolock)
	INNER JOIN ProdStarts/*Production_Starts*/ ps (nolock) on (ps.PU_Id = @PU_Id AND ps.PU_Id <> 0)
		AND ps.Prod_Id = @ActivityProductId
		AND (a.KeyId >= ps.Start_Time 
			AND a.KeyId < ps.End_Time )
	WHERE a.Sheet_Id = @SheetId
		AND a.KeyId < @ActivityEndTime
		AND ISNULL(Title,'') = @Title
		AND Activity_Status = 3
		--AND PercentComplete = 100
	Order by KeyId Desc
End

SET @ReturnSize = (SELECT COUNT(*) FROM @ActivityData)

--Get Result values for all variables for all activities
INSERT INTO @VariableData(ActivityId,VariableId,Result,DataTypeId)
SELECT a.ActivityId,v1.VarId,cast(t.Result as float),v.Data_Type_Id
FROM @ActivityData a
CROSS APPLY @Variables v1
JOIN Variables_Base v  (nolock) on v.Var_Id = v1.varId
JOIN Data_Type dt  (nolock) on dt.Data_Type_Id = v.Data_Type_Id
LEFT JOIN Tests t  (nolock) on t.Var_Id = v.Var_Id and t.Result_On = a.KeyId AND ISNUMERIC(t.Result) = 1
WHERE v.Data_Type_Id in (1,2,6,7)
AND (coalesce(@ActivityTypeId,0) > 0) -- valid activity was found
ORDER BY VarId

;with varIdsWithNullTests AS (SELECT VariableId FROM @VariableData GROUP BY VariableId HAVING SUM(RESULT) IS NULL)
-- Remove any variable which does not have any test values at all in any samples
DELETE V FROM @VariableData V JOIN  varIdsWithNullTests V1 ON V.VariableId = V1.VariableId

--Calculate Min, Max, and Average using SQL function
INSERT INTO @ReturnSet(VariableId,Maximum,Minimum,Average,DataTypeId)
SELECT VariableId,
	Maximum = MAX(Result),
	Minimum = MIN(Result),
	Average = AVG(ISNULL(Result, 0)),
	DataTypeId 
FROM @VariableData
GROUP BY VariableId, DataTypeId
ORDER BY VariableId

--Get Row Orders for determining Median and Quartiles
INSERT INTO @RowOrderedData(VariableId,Result,RowAsc,RowDesc,TopHalfRowAsc,BottomHalfRowDesc)
SELECT
    VariableId,
    Result,
    ROW_NUMBER() OVER (
        PARTITION BY VariableId 
        ORDER BY Result ASC, ActivityId ASC) AS RowAsc, -- For Median/Lower Quartile
    ROW_NUMBER() OVER (
        PARTITION BY VariableId 
        ORDER BY Result DESC, ActivityId DESC) AS RowDesc, -- For Median/Upper Quartile
    (ROW_NUMBER() OVER (
        PARTITION BY VariableId 
        ORDER BY Result ASC, ActivityId ASC)) - (@ReturnSize/2) AS TopHalfRowAsc, -- For Upper Quartile
    (ROW_NUMBER() OVER (
        PARTITION BY VariableId 
        ORDER BY Result DESC, ActivityId DESC)) - (@ReturnSize/2) AS BottomHalfRowDesc -- For Upper Quartile
FROM @VariableData
ORDER BY VariableId, RowDesc

--Calculate Median
INSERT INTO @Median (VariableId, Median)
SELECT	VariableId,
	AVG(ISNULL(Result, 0))
	FROM @RowOrderedData
WHERE 
	RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
GROUP BY VariableId
ORDER BY VariableId

--The following code removes the middle value in cases where there is an odd number of values. 
--This makes the Quartile calculation 'Exclusive'
--To calculate Quartiles as 'Inclusive', skip this section
IF(@ReturnSize > 1
	AND @ReturnSize % 2 = 1)
BEGIN
	DELETE @RowOrderedData WHERE RowAsc = RowDesc
	UPDATE @RowOrderedData SET TopHalfRowAsc = TopHalfRowAsc - 1, BottomHalfRowDesc = BottomHalfRowDesc - 1
END

--Calculate Upper Quartile
INSERT INTO @UpperQuartile (VariableId, UpperQuartile)
SELECT	VariableId,
	AVG(ISNULL(Result, 0))
	FROM @RowOrderedData
WHERE 
	TopHalfRowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
GROUP BY VariableId
ORDER BY VariableId

--Calculate Lower Quartile
INSERT INTO @LowerQuartile (VariableId, LowerQuartile)
SELECT	VariableId,
	AVG(ISNULL(Result, 0))
	FROM @RowOrderedData
WHERE 
	RowAsc IN (BottomHalfRowDesc, BottomHalfRowDesc - 1, BottomHalfRowDesc + 1)
GROUP BY VariableId
ORDER BY VariableId

--Update Result Set with Median, Upper Quartile, and Lower QUartile
UPDATE rs
SET rs.Median = m.Median,
	rs.UpperQuartile = u.UpperQuartile,
	rs.LowerQuartile = l.LowerQuartile
FROM @ReturnSet rs
LEFT JOIN @Median m on m.VariableId = rs.VariableId
LEFT JOIN @UpperQuartile u on u.VariableId = rs.VariableId
LEFT JOIN @LowerQuartile l on l.VariableId = rs.VariableId

SELECT VariableId, 
	Maximum, 
	Minimum, 
	Average, 
	Median, 
	UpperQuartile, 
	LowerQuartile, 
	DataTypeId 
FROM @ReturnSet


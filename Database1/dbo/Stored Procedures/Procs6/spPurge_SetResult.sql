CREATE PROCEDURE dbo.spPurge_SetResult(@desc varchar(255),@recs int,@RunId Int Output ) 
AS
DECLARE @CurrentId Int
DECLARE @PrevTime DateTime
DECLARE @CurrentTime DateTime
DECLARE @TotalSeconds int
Select @CurrentTime = GetDate()
if @recs is null
 	 RETURN
IF @RunId = -1 --need New Id
BEGIN
 	 SELECT @RunId = Null
 	 SELECT @RunId = Max(RunId) FROM PurgeResult
 	 IF @RunId Is Null
 	  	 Set @RunId = 1
 	 ELSE
 	  	 Set @RunId = @RunId + 1
END
IF @RunId Is Null 
BEGIN
 	 SELECT @RunId = Max(RunId) FROM PurgeResult
 	 IF @RunId Is Null
 	  	 Set @RunId = 1
END
SELECT @PrevTime = Max(PurgeResult_Date) 
 	 FROM PurgeResult
 	 WHERE RunId = @RunId
IF @PrevTime Is Null
 	 SET @PrevTime = @CurrentTime
IF CharIndex('Job Complete',@desc) > 0
BEGIN
 	 SELECT @PrevTime = Min(PurgeResult_Date)
 	 FROM PurgeResult
 	 WHERE RunId = @RunId
END
SET @TotalSeconds = DateDiff(Second,@PrevTime,@CurrentTime)
SELECT @CurrentId =  PurgeResult_Id
 	 FROM PurgeResult
 	 WHERE RunId = @RunId and PurgeResult_Desc = @desc
IF @CurrentId Is Null
 	 insert into PurgeResult (PurgeResult_Desc,PurgeResult_Recs,RunId,PurgeResult_Date,TotalSeconds) 
 	  	 SELECT substring(@desc,1,50),@recs,@RunId,@CurrentTime,@TotalSeconds
ELSE
 	 UPDATE PurgeResult SET PurgeResult_Recs = PurgeResult_Recs + @recs, TotalSeconds = @TotalSeconds + TotalSeconds,PurgeResult_Date = @CurrentTime
 	 WHERE PurgeResult_Id = @CurrentId

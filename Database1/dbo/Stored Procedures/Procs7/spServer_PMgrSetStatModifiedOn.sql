CREATE PROCEDURE dbo.spServer_PMgrSetStatModifiedOn
@ServiceId int,
@StartTime datetime,
@ModifiedOn datetime
AS 
update Performance_Statistics_Keys set Modified_on = @ModifiedOn where Service_Id=@ServiceId and Start_Time = @StartTime

CREATE Procedure [dbo].[spMSITopic_ProductionUnitDetails_24Hr]
@value int OUTPUT,
@Key int,
@Topic int
 AS
Declare @EndTime  	  	 DateTime,
 	  	 @StartTime 	  	 DateTime
Execute spMSITopic_CalculateStartandEndTimes 3,@StartTime Output,@EndTime Output,@Key
Execute spMSITopic_ProductionUnitDetails @StartTime,@EndTime,@Key,@Topic

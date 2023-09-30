CREATE Procedure [dbo].[spMSITopic_InventoryUnitDetails_24Hr]
@value int OUTPUT,
@Key int,
@Topic int
 AS
Declare @EndTime  	  	 DateTime,
 	  	 @StartTime 	  	 DateTime
Execute spMSITopic_CalculateStartandEndTimes 3,@StartTime Output,@EndTime Output,@Key
Execute spMSITopic_InventoryUnitDetails @Topic,@StartTime,@EndTime,@Key

CREATE Procedure [dbo].[spMSITopic_LineDetails_Shift]
@value int OUTPUT,
@Key int,
@Topic int
 AS
Declare @EndTime  	  	 DateTime,
 	  	 @StartTime 	  	 DateTime
Execute spMSITopic_CalculateStartandEndTimes 2,@StartTime Output,@EndTime Output,Null
Execute spMSITopic_LineDetails @Topic,@StartTime,@EndTime,@Key

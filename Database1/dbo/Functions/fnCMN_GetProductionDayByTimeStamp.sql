/*
select  dbo.fnCMN_GetProductionDayByTimeStamp('2005-01-25 7:00:00')
*/
CREATE FUNCTION dbo.fnCMN_GetProductionDayByTimeStamp(@ProductionTimeStamp DATETIME) 
     RETURNS DateTime 
AS 
Begin
     Declare @ProductionDay DateTime
     Declare @MillStartTime nvarchar(8)
     Select @MillStartTime = dbo.fnRS_GetMillStartTime()
     Select @ProductionDay =
     Case 
          When @ProductionTimeStamp > Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, @ProductionTimeStamp)) + '-' + Convert(nVarChar(2), DatePart(mm, @ProductionTimeStamp)) + '-' + Convert(nVarChar(2), DatePart(dd, @ProductionTimeStamp)) + ' ' + @MillStartTime) 
          then Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, @ProductionTimeStamp)) + '-' + Convert(nVarChar(2), DatePart(mm, @ProductionTimeStamp)) + '-' + Convert(nVarChar(2), DatePart(dd, @ProductionTimeStamp)) + ' ' + @MillStartTime) 
          Else Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, dateadd(d, -1, @ProductionTimeStamp))) + '-' + Convert(nVarChar(2), DatePart(mm, dateadd(d, -1, @ProductionTimeStamp))) + '-' + Convert(nVarChar(2), DatePart(dd, dateadd(d, -1, @ProductionTimeStamp))) + ' ' + @MillStartTime) 
     End
     RETURN @ProductionDay
END

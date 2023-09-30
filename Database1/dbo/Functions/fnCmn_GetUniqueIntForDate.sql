CREATE FUNCTION  dbo.fnCmn_GetUniqueIntForDate
(
 	 @Forecaststartdate Datetime, @PathId int
)
RETURNS nVarChar(15)
AS
BEGIN
 	 Declare @DuplicatePPIdCnt int
 	 declare @ReturnString nVarChar(15)
 	 Select @DuplicatePPIdCnt = 0
 	 select top 1 @DuplicatePPIdCnt = Implied_Sequence_Offset + 1 from Production_Plan where Path_Id =@PathId and Forecast_Start_Date = @Forecaststartdate
 	 Order by Implied_Sequence_Offset DESC 
 	 SELECT @DuplicatePPIdCnt = ISNULL(@DuplicatePPIdCnt,1)
 	 --Return ((Datediff(s,'1990-01-01',@Forecaststartdate)%1000000000)*10+@DuplicatePPIdCnt)
 	 Select @ReturnString = Cast((Datediff(s,'1990-01-01',@Forecaststartdate)%1000000000) as varchar)+';'+Cast(@DuplicatePPIdCnt as varchar)
 	 Return @ReturnString
END

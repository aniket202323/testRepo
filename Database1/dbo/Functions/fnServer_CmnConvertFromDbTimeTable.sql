CREATE FUNCTION [dbo].[fnServer_CmnConvertFromDbTimeTable](
@InTbl dbo.FrmDBTimeTable READONLY
)
returns @OutTbl TABLE
(
 	 InputTime Datetime,
 	 OutputTimeZone nvarchar(200),
 	 DBTimeZone nvarchar(200),
 	 ConvertedTime Datetime,
 	 Bias1 Int, UTCtime Datetime, Bias2 Int
)
AS
begin
Insert Into @OutTbl(InputTime,OutputTimeZone,DBTimeZone,ConvertedTime)
Select InputTime,OutputTimeZone,DBTimeZone,ConvertedTime from @InTbl
UPDATE @OutTbl SET ConvertedTime = InputTime where OutputTimeZone IS NULL
UPDATE @OutTbl SET ConvertedTime = InputTime where LEN(OutputTimeZone) = 0
UPDATE @OutTbl SET ConvertedTime = InputTime where InputTime IS NULL
UPDATE @OutTbl SET DBTimeZone = (select Value from site_parameters where parm_id=192)
UPDATE T
 SET Bias1 = ISNULL((SELECT UTCbias from TimeZoneTranslations where TimeZone = T.DBTimeZone and T.InputTime >= StartTime and T.InputTime < EndTime),0)
 From @OutTbl T
UPDATE T
SET UTCtime =  DateAdd(mi,T.Bias1 ,T.InputTime)
 From @OutTbl T
UPDATE T
 SET Bias2 = ISNULL((SELECT UTCbias from TimeZoneTranslations where TimeZone = T.OutputTimeZone and T.UTCtime >= UtcStartTime and T.UTCtime < UtcEndTime),0)
 From @OutTbl T
UPDATE T
SET T.ConvertedTime = DateAdd(mi,-T.Bias2,T.UTCtime)
From @OutTbl T 
Return
  	  
end

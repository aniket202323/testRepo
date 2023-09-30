CREATE PROCEDURE [dbo].[spRS_GetStandardTimeZones]
AS
DECLARE @StandardTimes TABLE (LocalDesc varchar(100),NLSDesc varchar(1000))
SELECT Distinct Timezone as LocalDesc,Timezone as NLSDesc FROM TimeZoneTranslations
 	  	  	 --WHERE Timezone<>'GMT Standard Time'
--INSERT INTO @StandardTimes VALUES('Central Standard Time','Central Standard Time')
--INSERT INTO @StandardTimes VALUES('Pacific Standard Time','Pacific Standard Time')
--SELECT * FROM @StandardTimes

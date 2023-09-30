CREATE PROCEDURE [dbo].[spDBR_GetStandardTimeZones]
AS
DECLARE @StandardTimes TABLE (LocalDesc varchar(100),NLSDesc varchar(1000))
INSERT INTO @StandardTimes VALUES('India Standard Time','India Standard Time')
INSERT INTO @StandardTimes VALUES('Central Standard Time','Central Standard Time')
INSERT INTO @StandardTimes VALUES('Pacific Standard Time','Pacific Standard Time')
SELECT * FROM @StandardTimes

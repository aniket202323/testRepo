
CREATE PROCEDURE dbo.spProductChange_GetHistory @AssetId INT

AS
BEGIN
    DECLARE @MinDate DATETIME= (SELECT dbo.fnServer_CmnGetDate(DATEADD(DAY, -10, CAST(dbo.fnServer_CmnConvertToDBTime(GETUTCDATE(), 'UTC') AS DATE))));
    WITH TZ(StartTime,
            EndTime,
            Bias)
         AS (
         SELECT StartTime,
                EndTime,
                UTCbias FROM TimeZoneTranslations WHERE TimeZone = (SELECT TOP 1 Value FROM site_parameters WHERE parm_id = 192))
         SELECT P.Prod_Id AS                                                                                        ProductId,
                P.Prod_Code AS                                                                                      ProductCode,
                Prod_Desc AS                                                                                        ProductDescription,
                DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE PS.Start_Time >= TZ.StartTime
                                                                 AND PS.Start_Time < TZ.EndTime), PS.Start_Time) AS StartTime,
                DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE PS.End_Time >= TZ.StartTime
                                                                 AND PS.End_Time < TZ.EndTime), PS.End_Time) AS     EndTime
                FROM Production_Starts AS PS
                     JOIN Products AS P ON PS.Prod_Id = P.Prod_Id
                WHERE PS.PU_id = @AssetId
                      AND PS.Start_Time >= @MinDate
                ORDER BY Start_Time DESC
END

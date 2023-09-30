 --------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Version 1.02  2007-01-09 Vince King  
--  
-- PG Line Status Report.  This stored procedure provides a result set consisting of Line Status values for a set of Production Units and   
-- a given report period.  The result set is used in the template RptPGLineStatus.xlt.  
--  
-- 2007-01-03 Vince King Rev1.00  
--  -  Original version.  
--  
-- 2007-01-07  Vince King Rev1.01  
--  -  Changed INNER JOIN from original code provided by FDL to LEFT JOIN.  There were cases where there were no rows in those tables and  
--   thus no results were being returned.  
--   
-- 2007-01-09 Vince King Rev1.02  
--  - Added @LineStatusResults table which holds the results from the SELECT based on time period.  
--  - Added IF statement in ReturnResultSets section that checks to see if there are any Prod_Units  
--   that did not have a Line Status row returned.  If there is, then go out and get the last row  
--   for each of those units.  
--  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
CREATE PROCEDURE [dbo].[spLocal_RptPGLineStatus]  
-- DECLARE   
 @StartTime DATETIME,  
 @EndTime  DATETIME,  
 @RptName  VARCHAR(100)  
  
AS  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-------------------------------------------------------------------------------  
-- Testing  
-------------------------------------------------------------------------------  
-- SELECT @StartTime = '2006-01-01',  
--    @EndTime = '2006-11-01',  
--    @RptName = 'PG Line Status Test'  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE   
 -------------------------------------------------------------------------  
 -- Report Parameters.  
 -------------------------------------------------------------------------  
 @PUIdList      VARCHAR(4000),  -- Collection of Prod_Units.PU_Id for CONVERTing units delimited by "|".  
 @UserName      VARCHAR(30),  -- User calling this report  
 @RptTitle      VARCHAR(300),  -- Report title from Web Report.  
 @RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
 @RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
 @RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
 @RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
 @RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
 @RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
 @@PUId       INTEGER    -- 2007-01-09 VMK Rev1.02, added  
  
-------------------------------------------------------------------------------  
-- TABLE Declarations  
-------------------------------------------------------------------------------  
DECLARE @ProdUnits    TABLE (  
    PUId      INTEGER )  
  
DECLARE @ErrorMessages   TABLE (  
    ErrMsg     VARCHAR(255) )  
  
DECLARE @LineStatusResults TABLE (       -- 2007-01-09 VMK Rev1.02, added  
    PUId      INTEGER,  
      PUDesc     VARCHAR(100),   
    StartDateTime   DATETIME,   
    EndDateTime    DATETIME,   
    LineStatus    VARCHAR(100),   
    UpdateStatus   VARCHAR(100),   
    Comment     VARCHAR(255),  
    UserName     VARCHAR(100) )  
  
---------------------------------------------------------------------------------------------------  
-- 2005-JUN-13 VMK Rev6.89  
-- Retrieve parameter values FROM report definition using spCmn_GetReportParameterValue  
---------------------------------------------------------------------------------------------------   
IF Len(@RptName) > 0   
BEGIN  
  -- print 'Get Report Parameters.'  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPUIdList',     '',  @PUIdList      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner',        '',  @UserName      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle',      '',  @RptTitle      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation',  '',  @RptPageOrientation   OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize',     '',  @RptPageSize     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom',    '',  @RptPercentZoom    OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut',     '',  @RptTimeout     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation',   '',  @RptFileLocation    OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString',  '',  @RptConnectionString  OUTPUT  
END  
ELSE   -- 2005-MAR-16 VMK Rev8.81, If no Report Name provided, return error.  
BEGIN  
 INSERT INTO @ErrorMessages (ErrMsg)  
  VALUES ('No Report Name specified.')  
  GOTO ReturnResultSets  
  
END    
  
-- SELECT @PUIdList = '1540|280'  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF isDate(@StartTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
IF isDate(@EndTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being printed on report.  
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VARCHAR(4),YEAR(GetDate())) + '-' + CONVERT(VARCHAR(2),MONTH(GetDate())) + '-' +   
     CONVERT(VARCHAR(2),DAY(GetDate())) + ' ' + CONVERT(VARCHAR(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VARCHAR(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VARCHAR(2),DATEPART(ss,@EndTime))  
  
-------------------------------------------------------------------------------  
-- INSERT PU_Ids provided by the @PUIdList parameter.  If the @PUIdList  
-- parameter is NULL, then return ALL Prod Units.  
-------------------------------------------------------------------------------  
IF @PUIdList IS NULL OR @PUIdList = ''  
 INSERT @ProdUnits  
  (  
  PUId)  
 SELECT   
  PU_Id  
 FROM dbo.Prod_Units  
 OPTION (KEEP PLAN)  
ELSE  
 INSERT @ProdUnits  
  (  
  PUId)  
 SELECT   
  PU_Id  
 FROM dbo.Prod_Units  
 WHERE CHARINDEX('|' + CONVERT(VARCHAR,PU_Id) + '|','|' + @PUIdList + '|') > 0  
 OPTION (KEEP PLAN)  
  
-------------------------------------------------------------------------------  
-- Testing  
-------------------------------------------------------------------------------  
-- SELECT '@ProdUnits' [@ProdUnits], ppu.PUId, pu.PU_Desc from @ProdUnits ppu JOIN dbo.Prod_Units pu ON ppu.PUId = pu.PU_Id  
  
-------------------------------------------------------------------------------  
-- Return Result Sets  
-------------------------------------------------------------------------------  
ReturnResultSets:  
  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
 SELECT ErrMsg  
 FROM @ErrorMessages  
 OPTION (KEEP PLAN)  
  
 -------------------------------------------------------------------------------  
 -- Build Line Status Results.  
 -------------------------------------------------------------------------------  
 INSERT INTO @LineStatusResults  
 SELECT   pu.PU_Id    AS 'PUId',  
    pu.PU_Desc    AS 'Production Unit',   
    ls.Start_DateTime AS 'Start Time',   
    ls.End_DateTime  AS 'End Time',   
    p.Phrase_Value  AS 'Status',   
    ls.Update_Status  AS 'Update Status',   
    lsc.Comment_Text  AS 'Comment',  
    u.UserName    AS 'Entered By'  
 FROM   dbo.Local_PG_Line_Status     ls   
 JOIN   @ProdUnits         ppu ON ppu.PUId      = ls.Unit_Id  
 INNER JOIN  dbo.Prod_Units        pu  ON pu.PU_Id      = ppu.PUId  
 LEFT  JOIN  dbo.Local_PG_Line_Status_Comments lsc  ON lsc.Status_Schedule_Id  = ls.Status_Schedule_Id   
 LEFT  JOIN  dbo.Phrase          p   ON p.Phrase_Id     = ls.Line_Status_Id  
 LEFT JOIN dbo.Users          u   ON u.User_Id      = lsc.User_Id  
 WHERE ((ls.Start_DateTime >= @StartTime)              --Beginning of Report Window  
   AND (ls.Start_DateTime < @EndTime)          --End of Report Window  
   OR    
       (ls.End_DateTime >= @StartTime)           --Beginning of Report Window  
   AND (ls.End_DateTime < @EndTime))           --End of Report Window  
 ORDER BY pu.PU_Desc, ls.Start_DateTime  
 OPTION (KEEP PLAN)  
  
  -----------------------------------------------------------------------------------------------------  
  -- 2007-01-09 VMK Rev1.02  
  -- Check to see if there is a Prod Unit that should be included in the report, but does not have  
  -- a line status change during the report period.  If there is, then return the last line status  
  -- change prior to the report period.  
  -- There may be a better way to do this.  
  -----------------------------------------------------------------------------------------------------  
   DECLARE ProdUnit_CURSOR CURSOR FOR  
   SELECT PUId FROM @ProdUnits  
   WHERE PUId NOT IN (SELECT DISTINCT PUId FROM @LineStatusResults)  
   OPTION (KEEP PLAN)  
  
   OPEN ProdUnit_CURSOR  
     
   FETCH NEXT FROM ProdUnit_CURSOR  
   INTO @@PUId  
     
   WHILE @@FETCH_STATUS = 0  
   BEGIN  
    INSERT INTO @LineStatusResults  
     SELECT TOP 1  
        pu.PU_Id     AS 'PUId',  
        pu.PU_Desc     AS 'Production Unit',   
        ls.Start_DateTime  AS 'Start Time',   
        ls.End_DateTime   AS 'End Time',   
        p.Phrase_Value   AS 'Status',   
        ls.Update_Status   AS 'Update Status',   
        lsc.Comment_Text   AS 'Comment',  
        u.UserName     AS 'Entered By'  
     FROM @LineStatusResults          lsr  
     FULL  OUTER JOIN  dbo.Local_PG_Line_Status    ls  ON lsr.PUId      = ls.Unit_Id  
     INNER JOIN    dbo.Prod_Units        pu  ON pu.PU_Id      =  ls.Unit_Id  
     LEFT  JOIN    dbo.Local_PG_Line_Status_Comments lsc  ON lsc.Status_Schedule_Id  =  ls.Status_Schedule_Id   
     LEFT  JOIN    dbo.Phrase          p   ON p.Phrase_Id     =  ls.Line_Status_Id  
     LEFT JOIN   dbo.Users          u   ON u.User_Id      =  lsc.User_Id  
     WHERE ls.Unit_Id = @@PUId  
     ORDER BY pu.PU_Desc, ls.Start_DateTime DESC  
     OPTION (KEEP PLAN)  
  
      FETCH NEXT FROM ProdUnit_CURSOR  
    INTO @@PUId  
   END  
     
   CLOSE ProdUnit_CURSOR  
   DEALLOCATE ProdUnit_CURSOR  
  
  -------------------------------------------------------------------------------------  
  -- 2007-01-09 VMK Rev1.02, added  
  -- Return Line Status Results  
  -------------------------------------------------------------------------------------  
  SELECT PUDesc   AS  'Production Unit',  
     StartDateTime AS  'Start Time',  
     EndDateTime  AS  'End Time',  
     LineStatus  AS  'Status',  
     UpdateStatus AS  'Update Status',  
     Comment   AS  'Comment',  
     UserName   AS  'Entered By'  
  FROM @LineStatusResults  
  ORDER BY PUDesc, StartDateTime  
  OPTION (KEEP PLAN)  
    
SET NOCOUNT OFF  
  

  CREATE PROCEDURE [dbo].[spLocal_RptQA_ChangeHistory]  
-----------------------------------------------------------------------------------------------------------------------  
--    This procedure provides information related to user-modified variable   
--    values per a provided timeframe.    
-----------------------------------------------------------------------------------------------------------------------  
-- FRio : 5-Sep-2005  RE-WRITTEN  
-- FRio : 31-May-2007  Change the JOIN to the Comments table; it is causing duplicates.  
-- FRio : 29-Ago-2008  Added UDPs capabilities to be consistent with other reports like Details and PPM/VAS.  
--        Renamed to spLocal_RptQA_ChangeHistory to match standard namings.  
-----------------------------------------------------------------------------------------------------------------------  
-- EXEC spLocal_RptQA_ChangeHistory 'Line 36-39 Validation Report Variable Change History'  
  
-- SELECT * FROM Report_Definitions WHERE Report_Name LIKE '%change%'  
-- Declare  
  
 @RptName            NVARCHAR(500)  
  
AS  
-- SET @RptName = 'Pearl Last Month Variable Change History'  
-----------------------------------------------------------------------------------------------------------------------  
PRINT ' - Create temporary tables '  
-----------------------------------------------------------------------------------------------------------------------  
  
CREATE TABLE #Tests(  
        EntryOn  DATETIME,  
        ResultOn  DATETIME,  
        Username  VARCHAR(30),  
        Result   VARCHAR(50),  
        VarDesc  VARCHAR(50),  
        LineDesc  VARCHAR(50),  
        Comment_id  INT,  
        CommentDesc  VARCHAR(4000)  
)  
  
CREATE TABLE #Variables(  
        RCDID   INT,  
        VarID   INT,  
        Var_Desc       NVARCHAR(250),  
        PU_Id          INT  
)  
  
CREATE TABLE #PL_IDs(  
        RCDID   INT,  
        PL_ID   INT,  
        PL_Desc        VARCHAR(100)  
)  
  
CREATE TABLE #PUGDescList (  
        RCDID   INT,  
        PUG_Desc     NVARCHAR(4000)  
)  
  
CREATE TABLE #LookUp_Tests  
       (Test_Id         INT,  
        Var_Id          INT,  
        Result_On       DATETIME,  
        Entry_On        DATETIME,  
        Comment_Id      INT,  
        Entry_By        INT,  
        Result          VARCHAR(25))  
  
---------------------------------------------------------------------------------------------------------------  
CREATE TABLE #Temp_Dates (  
       StartDate        DATETIME,  
       EndDate          DATETIME)  
  
-----------------------------------------------------------------------------------------------------------------------  
-- Variables to hold parameters  
-----------------------------------------------------------------------------------------------------------------------  
  
DECLARE  
  
    @in_LineId       NVARCHAR(1000) ,  
    @in_VarId        NVARCHAR(4000) ,  
 @TimeOption   INT    ,  
  @in_StartTime   DATETIME  ,     -- start of query timeframe  
  @in_EndTime   DATETIME      -- end of query timeframe  
  
  
--=====================================================================================================================  
PRINT ' - Retrive parameter values from report definition '  
--=====================================================================================================================  
  
IF Len(@RptName) > 0   
BEGIN  
    EXEC spCmn_GetReportParameterValue @RptName, 'Local_PG_strLinesById1', Null, @in_LineId OUTPUT  
 EXEC spCmn_GetReportParameterValue  @RptName, 'Variables', '', @in_VarId OUTPUT  
 EXEC spCmn_GetReportParameterValue  @RptName, 'TimeOption','', @TimeOption OUTPUT  
 -- EXEC spCmn_GetReportParameterValue @RptName, 'Local_PG_strRptDefaultPUGDescList', 'QV PQM' , @RptDefaultPUGDescList OUTPUT    
END  
ELSE  
BEGIN  
 SELECT   
            @in_LineId                          = 7,  
            @in_VarId                           = ''  
    --        @RptDefaultPUGDescList    = 'QV PQM'  
 END  
  
-----------------------------------------------------------------------------------------------------------------------  
-- RESOLVE THE @StartDateTime AND @ENDDateTime  
-----------------------------------------------------------------------------------------------------------------------  
DECLARE  
   @strShiftStart    NVARCHAR(200),  
   @intShiftLenght    INT  
  
SELECT @strShiftStart = ((SELECT CASE Len(value) WHEN 1 THEN '0'+Value ELSE Value END AS Minutes   
FROM dbo.Site_Parameters WITH(NOLOCK)  
WHERE parm_id = 14) + ':' +  
 (SELECT CASE Len(value) WHEN 1 THEN '0'+Value ELSE Value END as Minutes   
  FROM dbo.Site_Parameters WITH(NOLOCK)  
  WHERE parm_id = 15))  
    
SELECT @intShiftLenght = value / 60 FROM dbo.Site_Parameters WITH(NOLOCK) WHERE parm_id = 16  
  
INSERT INTO #Temp_Dates (StartDate,ENDDate)  
EXEC dbo.spLocal_RptRunTime @TimeOption,@intShiftLenght,@strShiftStart,'',''  
  
IF @TimeOption <> 0   
BEGIN  
  IF EXISTS(SELECT * FROM #Temp_Dates WHERE StartDate IS NULL AND EndDate IS NULL)  
  BEGIN  
     EXEC dbo.spCMN_GetRelativeDate @TimeOption,@in_StartTime, @in_EndTime  
  END  
  ELSE  
  BEGIN  
   SELECT  @in_StartTime = StartDate, @in_EndTime = ENDDate FROM #Temp_Dates  
  END  
END  
  
-- SELECT  @in_StartTime, @in_EndTime  
-----------------------------------------------------------------------------------------------------------------------  
-- SP Variables  
-----------------------------------------------------------------------------------------------------------------------  
  
DECLARE  
    @Var_Id       INT   ,  
    @Test_Id      INT   ,  
     @Change      INT   ,  
    @intTableId     INT   ,  
    @intTableFieldId     INT   ,  
    @Entry_On      DATETIME ,  
    @Result_On      DATETIME ,  
    @PrevResult_On     DATETIME ,  
    @UserName      VARCHAR(50) ,  
    @Result      VARCHAR(50) ,  
    @vchUDPDescDefaultQProdGrps    VARCHAR(25),  
    @PL_Desc      VARCHAR(50)  
  
  
-----------------------------------------------------------------------------------------------------------------------  
-- UDP field names  
-----------------------------------------------------------------------------------------------------------------------  
SELECT   
  @vchUDPDescDefaultQProdGrps = 'DefaultQProdGrps'  
  
  
--------------------------------------------------------------------------------------------------------------  
-- Parse the Report Parameters  
--------------------------------------------------------------------------------------------------------------  
INSERT INTO #PL_IDs ( RCDID ,  
      PL_ID )  
EXEC SPCMN_ReportCollectionParsing  
 @PRMCollectionString = @in_LineID, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',' ,  
    @PRMDataType01 = 'INT'  
  
INSERT INTO #Variables ( RCDID ,  
       VarID )  
EXEC SPCMN_ReportCollectionParsing  
 @PRMCollectionString = @in_VarID, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',' ,  
    @PRMDataType01 = 'INT'  
  
-------------------------------------------------------------------------------------------------------------------  
-- GET table Id for PU_Groups  
-------------------------------------------------------------------------------------------------------------------   
SELECT @intTableId = TableId  
FROM dbo.Tables WITH (NOLOCK)   
WHERE TableName = 'PU_Groups'  
-------------------------------------------------------------------------------------------------------------------   
-- GET table field Id for DefaultQProdGrps  
-------------------------------------------------------------------------------------------------------------------   
SELECT @intTableFieldId = Table_Field_Id  
FROM dbo.Table_Fields WITH (NOLOCK)  
WHERE Table_Field_Desc = @vchUDPDescDefaultQProdGrps  
  
---------------------------------------------------------------------------------------------------------------  
-- SELECT * FROM #PL_IDs  
---------------------------------------------------------------------------------------------------------------  
-- Business Rule for the Report :  
-- a. If Line Selected and No Variables Selected then get all Variables from the @vchUDPDescDefaultQProdGrps   
--    PU Groups configured in the UDP  
-- b. If No Line Selected and Variables Selected then just show the Variables list Selected  
-- c. If No Line Selected and No Variables Selected then get all Variables from the @vchUDPDescDefaultQProdGrps   
--    PU Groups configured in the UDP for All the Lines  
---------------------------------------------------------------------------------------------------------------  
  
IF EXISTS (SELECT * FROM #PL_IDs)  
BEGIN  
---------------------------------------------------------------------------------------------------------------  
-- a. If Line Selected and No Variables Selected then get all Variables from the @vchUDPDescDefaultQProdGrps   
--    PU Groups configured in the UDP  
---------------------------------------------------------------------------------------------------------------  
  IF NOT EXISTS(SELECT * FROM #Variables)  
  BEGIN  
   
   INSERT INTO #Variables (  
         VarId)  
   SELECT      DISTINCT   v.Var_Id  
            FROM dbo.Variables  v       WITH(NOLOCK)  
   JOIN dbo.Prod_Units pu      WITH(NOLOCK)   
             ON pu.PU_Id = v.PU_Id  
   JOIN #PL_Ids      pl       ON pl.PL_Id = pu.PL_Id  
            JOIN dbo.PU_Groups PUG      WITH(NOLOCK)   
             ON pug.PUG_Id = v.PUG_Id  
   JOIN dbo.Table_Fields_Values tfv  WITH (NOLOCK)  
             ON tfv.KeyId = pug.PUG_Id  
            WHERE  tfv.TableId = @intTableId  
    AND tfv.Table_Field_Id = @intTableFieldId  
    AND tfv.Value = 'Yes'  
  
  END  
END  
ELSE  
BEGIN  
---------------------------------------------------------------------------------------------------------------  
-- c. If No Line Selected and No Variables Selected then get all Variables from the @vchUDPDescDefaultQProdGrps   
--    PU Groups configured in the UDP for All the Lines  
---------------------------------------------------------------------------------------------------------------  
   IF NOT EXISTS(SELECT * FROM #Variables)  
  BEGIN  
  
   INSERT INTO #Variables (  
         VarId)  
   SELECT      DISTINCT   v.Var_Id  
            FROM dbo.Variables  v       WITH(NOLOCK)  
   JOIN dbo.Prod_Units pu      WITH(NOLOCK)   
             ON pu.PU_Id = v.PU_Id  
            JOIN dbo.PU_Groups PUG      WITH(NOLOCK)   
             ON pug.PUG_Id = v.PUG_Id  
   JOIN dbo.Table_Fields_Values tfv  WITH (NOLOCK)  
             ON tfv.KeyId = pug.PUG_Id  
            WHERE  tfv.TableId = @intTableId  
    AND tfv.Table_Field_Id = @intTableFieldId  
    AND tfv.Value = 'Yes'  
    
  END  
END  
  
UPDATE #Variables  
      SET Var_Desc = v.Var_Desc,  
       PU_Id    = v.PU_Id  
FROM        #Variables vids  
JOIN        dbo.Variables   v  WITH(NOLOCK)  
           ON  v.Var_Id = vids.VarId  
  
-- SELECT * FROM #Variables  
---------------------------------------------------------------------------------------------------------------  
--    Get lookup Tests  
---------------------------------------------------------------------------------------------------------------  
  
INSERT INTO #LookUp_Tests (  Test_Id  ,  
        Var_Id  ,  
        Result_On ,  
        Entry_On ,  
        Comment_Id ,  
        Entry_By ,  
        Result   )  
SELECT        Test_Id  ,  
        Var_Id  ,  
        Result_On ,  
        Entry_On ,  
        Comment_Id ,  
        Entry_By ,  
        Result  
FROM        dbo.Tests t  WITH(NOLOCK)  
JOIN        #Variables v  ON   v.VarId  =  t.Var_Id  
WHERE   
        t.Result_On >= @In_StartTime   
        AND t.Result_On < @In_EndTime  
  
---------------------------------------------------------------------------------------------------------------  
--    Get Variable Historical Tests  
---------------------------------------------------------------------------------------------------------------  
  
INSERT INTO  #Tests  (  EntryOn  ,   
        ResultOn ,  
        Username ,   
        Result  ,   
        VarDesc  ,   
        LineDesc ,  
        Comment_Id  )  
SELECT        th.Entry_On ,   
        t.Result_On ,   
        u.UserName ,   
        th.Result ,   
        tv.Var_Desc ,  
        pl.PL_Desc ,  
        t.Comment_Id   
FROM        dbo.Test_History th  WITH(NOLOCK)  
JOIN        #LookUp_Tests t   ON   th.Test_Id = t.Test_Id  
JOIN        #Variables tv    ON   tv.VarID    = t.Var_ID  
JOIN        dbo.Prod_Units pu  WITH(NOLOCK)   
              ON   tv.PU_ID  = pu.PU_ID  
JOIN        dbo.Prod_Lines pl   WITH(NOLOCK)  
              ON   pl.PL_ID  = pu.PL_ID  
JOIN        dbo.Users u    WITH(NOLOCK)  
              ON   th.Entry_By = u.User_ID  
WHERE   
        t.Result_On >= @In_StartTime   
        AND t.Result_On < @In_EndTime  
        AND UPPER(u.username) <> 'STUBBER'  
  
---------------------------------------------------------------------------------------------------------------  
--    UPDATE From Comments table  
---------------------------------------------------------------------------------------------------------------  
  
UPDATE   #Tests  
 SET CommentDesc = C.Comment_Text  
FROM   #Tests t  
JOIN   dbo.Comments C  WITH(NOLOCK)  
       ON C.Comment_Id = T.Comment_Id  
  
---------------------------------------------------------------------------------------------------------------  
-- FINAL Result Set  
---------------------------------------------------------------------------------------------------------------  
  
SELECT   
    EntryOn  ,  
    ResultOn  ,  
    Username  ,  
    Result   ,  
    VarDesc  ,  
    LineDesc  ,  
    CommentDesc   
FROM   #Tests   
ORDER BY   VarDesc  ,  
    EntryOn  
  
---------------------------------------------------------------------------------------------------------------  
-- DROP TABLES  
---------------------------------------------------------------------------------------------------------------  
  
DROP TABLE #Tests  
DROP TABLE #Variables  
DROP TABLE #PL_IDs  
DROP TABLE #PUGDescList  
DROP TABLE #LookUp_Tests  
DROP TABLE #Temp_Dates  
  
---------------------------------------------------------------------------------------------------------------  
  
  
  
  
  

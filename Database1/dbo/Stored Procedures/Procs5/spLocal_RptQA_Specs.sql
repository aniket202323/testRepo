-- 2009-01-13 Galanzini Pablo: Not show test_freq=0 and Specs nulls?  
--        (Arido Software)          
-- 2008-09-02 Galanzini Pablo: Get rid of the Local_PG_strRptDefaultPUGDescList parameter, now get the Default PU Groups  
--          from the 'PU_Groups' UDP.  
-- 2008-08-29 Galanzini Pablo: If Product is selected then override the Production Starts table and get the Specs for   
--          the selected product.  
--          Dont check for Test Freq = 0 anymore.  
--          Master_Unit is not used to look for the Production Line  
-- 2008-08-26 Galanzini Pablo: Added capabilities to work with either : displays built from custon option data types  
--         or from Variable Display web page that populates SheetName parameter  
-- 2008-03-04 FRio : Modified for where there is no data to display, for not sending empty recordsets  
-- 2007-06-13 Modified to get variables from either Display Names or PUG_Desc for those   
-- sites that does not have a specific diplay for a given ser of variables  
-------------------------------------------------------------------------------------------  
-- FRio : 25-Sep-2006 RE-WRITTEN for Function to UNITS project.  
-------------------------------------------------------------------------------------------  
  
CREATE PROCEDURE dbo.spLocal_RptQA_Specs  
--DECLARE  
    @RptName               NVARCHAR(500),  
    @strRptStartDate     DATETIME  
AS  
-------------------------------------------------------------------------------------------  
-- Test Values  
-- exec dbo.spLocal_RptQA_Specs 'aQA_Specs20090204_LineDINK102','2009-01-01 06:00:00 AM'  
-- SELECT report_name,* FROM Report_Definitions WHERE report_name like '%Spec%'  
-- set @strRptStartDate    = '2009-02-13 06:00:00 AM'  
--set @RptName    = 'QA_Specs20090213_TestFreq'  
--exec spLocal_RptQA_Specs 'QA_Specs20090213_TestFreq','2009-02-13 07:00AM'  
-------------------------------------------------------------------------------------------  
  
DECLARE   
     @ProdIDList      NVARCHAR(300) ,  
     @DataType_Desc     NVARCHAR(300) ,  
     @PLIDList      NVARCHAR(300) ,  
     @Sheet_Name      NVARCHAR(300) ,  
     @i        INT    ,  
     @intTableId               INT    ,  
     @intTableFieldId          INT    ,  
     @vchUDPDescDefaultQProdGrps  NVARCHAR(25) ,  
     @Plant       NVARCHAR(200) ,  
     @INTerval      INT    ,  
     @Offset       INT    ,  
     @ProdId       INT     ,  
     @ProdDesc      NVARCHAR(300) ,  
     @ProdCode      NVARCHAR(50)  ,  
     @ProdRECNo      INT     ,  
     @PLId       INT    ,  
     @PLDesc       NVARCHAR(100) ,  
     @PLRECNo      INT  
  
--=================================================================================================  
PRINT ' - Retrive parameter values FROM report definition '  
--=================================================================================================  
  
IF Len(@RptName) > 0   
BEGIN  
    EXEC spCmn_GetReportParameterValue @RptName, 'Local_PG_strLinesById1', Null, @PLIDList OUTPUT  
 EXEC spCmn_GetReportParameterValue @RptName, 'Local_PG_strOptionsName1', Null, @DataType_Desc OUTPUT  
 EXEC spCmn_GetReportParameterValue @RptName, 'Products', Null, @ProdIDList OUTPUT  
 EXEC spCmn_GetReportParameterValue @RptName, 'SheetName', Null, @Sheet_Name OUTPUT  
END  
ELSE  
BEGIN  
 SELECT   
            @PLIDList                           = '38'             ,  
      @DataType_Desc      = 'OffLine Quality',  
   @ProdIDList       = ''      ,  
   @strRptStartDate      = '2007-06-2 6:00AM',  
   @Sheet_Name       = ''  
 END  
  
---------------------------------------------------------------------------------------------------  
PRINT ' - Create temporary tables '  
---------------------------------------------------------------------------------------------------  
CREATE TABLE #PLIDList    (  
       RCDID       INT,         
       PL_ID       INT,  
       PL_Desc      NVARCHAR(200),  
       Sheet_Desc     NVARCHAR(300),  
       Interval     INT,  
       Offset      INT)  
---------------------------------------------------------------------------------------------------  
CREATE TABLE #ProdIDList   (  
       RCDID       INT,        
       Prod_id       INT,  
       Prod_Code     NVARCHAR(50),  
       Prod_Desc     NVARCHAR(200))  
---------------------------------------------------------------------------------------------------  
CREATE TABLE #Var_Specs (  
       PL_Id      INT,  
       Var_Id       INT,  
       PU_id       INT,  
       Prod_id      INT,  
       Var_Desc      NVARCHAR(255),   
       Eng_Units      NVARCHAR(50),   
       Spec_Id      INT,  
       L_Reject      VARCHAR(25),   
       L_Warning      VARCHAR(25),   
       L_User       VARCHAR(25),   
       Target       VARCHAR(25),   
       U_User       VARCHAR(25),   
       U_Warning      VARCHAR(25),   
       U_reject      VARCHAR(25),   
       Test_Freq      VARCHAR(25),   
       Sampling_INTerval    INT,   
       Sampling_Offset    INT,  
       String       VARCHAR(255),  
       Col_INTerval     VARCHAR(1),  
       Col_Offset      VARCHAR(1),  
       UD2_Spec_Id     INT,  
       Var_Order      INT)  
  
  
--=================================================================================================  
PRINT ' - Initialize temporary tables'  
---------------------------------------------------------------------------------------------------  
-- Done to minimize recompiles  
--=================================================================================================  
SET @i = (SELECT  Count(*)  FROM  #Var_Specs)  
SET @i = (SELECT  Count(*)  FROM  #PLIDList)  
  
-----------------------------------------------------------------------------------------------------------  
-- GET SITE  
-----------------------------------------------------------------------------------------------------------  
SELECT @Plant =  COALESCE(Value, 'Site Name')  
 FROM  dbo.Site_Parameters   
 WHERE  Parm_Id = 12  
  
-----------------------------------------------------------------------------------------------------------  
-- Bussines Rule to get the Variables :  
-----------------------------------------------------------------------------------------------------------  
-- a. If No Line Selected and No Display Selected then show NO DATA  
-- b. If No Line Selected and Display Selected then :  
--    b.1.  If Product is Selected then Show the Specification for that Product for the Variables  
--       on the Selected Display.  
--    b.2.  Else for the Variables in the Selected Display, and for the PU_Id those variables belong  
--       to use the TimeStamp to get the All products been made at that Timestamp for that PU_Id   
--       and Show the Specification for that Product.  
-- c. If Line is Selected and No Display Seleted then build the Display Name = @DataType_Desc + Line_Desc   
--   with that Display Name :  
--    c.1.  If Product is Selected then Show the Specification for that Product for the Variables  
--       on the Selected Display.  
--    c.2.  Else use the TimeStamp to get the Product the line was running, and show the Specification  
--       for that Variables.  
-- d. If Line is Selected and Display Selected then :  
--    Do Item b.  
-----------------------------------------------------------------------------------------------------------  
  
IF LEN(IsNull(@PLIdList, '')) > 0   
 AND @PLIdList <> '!NULL'    
BEGIN  
 -- Retrieve Line/s Selected  
 INSERT INTO #PLIDList(RCDID, PL_Id)  
  EXEC SPCMN_ReportCollectionParsing  
  @PRMCollectionString = @PLIDList, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
  @PRMDataType01 = 'INT'  
      
 IF LEN(IsNull(@DataType_Desc, '')) > 0  
  BEGIN  
   UPDATE #PLIDList  
    SET PL_Desc = PL.PL_Desc,  
     Sheet_Desc = @DataType_Desc + ' ' + PL.PL_Desc  
   FROM #PLIDList PLID  
   JOIN Prod_Lines PL ON PLID.PL_ID = PL.PL_ID  
  END  
 ELSE  
  BEGIN  
   UPDATE #PLIDList  
    SET PL_Desc = PL.PL_Desc,  
     Sheet_Desc = @Sheet_Name  
    FROM #PLIDList PLID  
    JOIN Prod_Lines PL ON PLID.PL_ID = PL.PL_ID  
  END   
  
 UPDATE #PLIDList   
   SET Interval  =  s.Interval,   
    Offset   =  s.Offset  
 FROM dbo.Sheets s WITH(NOLOCK)  
 JOIN #PLIDList PL  ON PL.Sheet_Desc  = s.Sheet_Desc   
    JOIN dbo.Sheet_Type st WITH(NOLOCK)  ON  s.Sheet_type = st.Sheet_Type_id   
   
END  
ELSE  
BEGIN  
  
 -- For tests  
-- select @PLIdList, @DataType_Desc, @Sheet_Name   
  
 -- Test for No Line No Data  
 IF (LEN(IsNull(@PLIdList, '')) = 0  
--  AND LEN(IsNull(@DataType_Desc, '')) = 0   
  AND LEN(IsNull(@Sheet_Name, '')) = 0)  
  BEGIN  
   INSERT INTO #PLIDList   
      ( PL_Id  ,   
       PL_Desc  )  
    VALUES  ( -999  ,  
       'No Line' )     
  END     
 ELSE  
  BEGIN  
  
  
  
   -- No lines selected, select all lines valid  
--   INSERT INTO #PLIDList( PL_Id)  
--   SELECT PL.PL_ID  
--    FROM Prod_Lines PL   
--    WHERE PL.pl_desc not like '<PL Deleted>'  
  
    -- For Test for one line  
--    AND PL.pl_desc LIKE 'LPPackLine03'   
--OR PL.pl_desc LIKE 'LPPackLine04'  
  
  
   IF LEN(IsNull(@DataType_Desc, '')) > 0  
    BEGIN  
  
     -- Find lines for DataType_Desc   
     INSERT #PLIDList(   
         PL_Id,   
         PL_Desc,   
         Sheet_Desc)  
     SELECT DISTINCT   
         PL.PL_id,   
         PL.PL_desc,  
         @Sheet_Name  
      FROM dbo.Sheets S   
      JOIN dbo.Sheet_Variables SV  WITH(NOLOCK)   
              ON SV.Sheet_ID =  S.Sheet_ID  
      JOIN dbo.Variables V   WITH(NOLOCK)   
              ON SV.Var_id  =  V.Var_id  
      JOIN dbo.Prod_Units PU    WITH(NOLOCK)   
              ON PU.pu_id = V.pu_id  
      JOIN dbo.Prod_Lines PL    WITH(NOLOCK)   
              ON PL.pl_id = PU.pl_id  
      WHERE S.Sheet_Desc like @DataType_Desc + ' ' + PL.PL_Desc  
  
/*  
     UPDATE #PLIDList  
      SET PL_Desc = PL.PL_Desc,  
       Sheet_Desc = @DataType_Desc + ' ' + PL.PL_Desc  
     FROM #PLIDList PLID  
     JOIN Prod_Lines PL ON PLID.PL_ID = PL.PL_ID  
*/  
  
    END  
   ELSE  
    BEGIN  
  
     -- Find lines for Sheet_Name  
     INSERT #PLIDList(   
         PL_Id,   
         PL_Desc,   
         Sheet_Desc)  
     SELECT DISTINCT   
         PL.PL_id,   
         PL.PL_desc,  
         @Sheet_Name  
      FROM dbo.Sheets S   
      JOIN dbo.Sheet_Variables SV  WITH(NOLOCK)   
              ON SV.Sheet_ID =  S.Sheet_ID  
      JOIN dbo.Variables V   WITH(NOLOCK)   
              ON SV.Var_id  =  V.Var_id  
      JOIN dbo.Prod_Units PU    WITH(NOLOCK)   
              ON PU.pu_id = V.pu_id  
      JOIN dbo.Prod_Lines PL    WITH(NOLOCK)   
              ON PL.pl_id = PU.pl_id  
      WHERE S.Sheet_Desc like @Sheet_Name  
  
/*  
     UPDATE #PLIDList  
      SET PL_Desc = PL.PL_Desc,  
       Sheet_Desc = @Sheet_Name  
     FROM #PLIDList PLID  
     JOIN Prod_Lines PL ON PLID.PL_ID = PL.PL_ID  
*/  
  
    END   
  
   UPDATE #PLIDList   
    SET Interval  =  s.Interval,   
     Offset   =  s.Offset  
   FROM dbo.Sheets s    WITH(NOLOCK)  
   JOIN #PLIDList PL       ON PL.Sheet_Desc = s.Sheet_Desc   
   JOIN dbo.Sheet_Type st  WITH(NOLOCK)  ON s.Sheet_type = st.Sheet_Type_id   
  END  
END  
  
-- For tests  
--select @DataType_Desc DataType_Desc,@Sheet_Name Sheet_Name,@RptName RptName  
--select @DataType_Desc DataType_Desc,@Sheet_Name Sheet_Name,@RptName RptName, * from #PLIDList  
  
-----------------------------------------------------------------------------------------------------------  
-- GET PRODUCTS  
-----------------------------------------------------------------------------------------------------------  
IF LEN(IsNull(@ProdIdList, '')) > 0   
 AND @ProdIdList <> '!NULL'    
 AND RTRIM(LTRIM(@ProdIdList)) <> '0'  
BEGIN  
  
   -- For Tests  
--   select @ProdIdList ProdIdList  
  
   INSERT INTO #ProdIDList(RCDID, Prod_Id)  
    EXEC SPCMN_ReportCollectionParsing  
    @PRMCollectionString = @ProdIDList, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
    @PRMDataType01 = 'INT'  
  
   UPDATE #ProdIDList  
    SET Prod_Desc = P.Prod_Desc,  
     Prod_Code = P.Prod_Code  
   FROM #ProdIDList Prd  
   JOIN Products P ON P.Prod_Id = Prd.Prod_ID     
  
END  
ELSE  
BEGIN   
      
   INSERT INTO #ProdIDList(Prod_Id ,  
         Prod_Code,           Prod_Desc )  
   SELECT DISTINCT     
         ps.prod_id ,  
         p.Prod_Code ,   
         p.Prod_Desc  
     FROM Production_Starts ps   
     JOIN Products p   ON   ps.Prod_Id  =  p.Prod_Id   
     JOIN dbo.Prod_Units  pu WITH(NOLOCK)  
           ON   ps.PU_id  = pu.PU_Id  
     JOIN #PLIDList PL   ON   pl.PL_Id  = pu.PL_Id  
     WHERE @strRptStartDate >= ps.Start_Time AND   
      (@strRptStartDate  < ps.End_Time OR ps.End_Time IS NULL)  
      AND p.Prod_Desc <> 'No Grade'  
      AND ps.Prod_Id > 1  
  
END  
  
-----------------------------------------------------------------------------------------------------------  
--        SET info for Production Gropu  
-----------------------------------------------------------------------------------------------------------  
SELECT @vchUDPDescDefaultQProdGrps = 'DefaultQProdGrps'  
  
-----------------------------------------------------------------------------------------------------------  
--        GET table Id for PU_Groups  
-----------------------------------------------------------------------------------------------------------  
SELECT @intTableId = TableId  
 FROM dbo.Tables        WITH (NOLOCK)          
 WHERE TableName = 'PU_Groups'  
------------------------------------------------------------------------------------------------------------          
--        GET table field Id for DefaultQProdGrps  
------------------------------------------------------------------------------------------------------------  
SELECT        @intTableFieldId = Table_Field_Id  
 FROM        dbo.Table_Fields        WITH (NOLOCK)  
    WHERE        Table_Field_Desc = @vchUDPDescDefaultQProdGrps  
  
  
-- For test  
--Select '#PLIDList -> ',* from #PLIDList  
--Select '#ProdIDList -> ',* from #ProdIDList order by prod_id  
---------------------------------------------------------------------------------------------------  
  
---------------------------------------------------------------------------------------------------  
  
INSERT INTO #Var_Specs (  
       PL_Id    ,  
       Var_Id    ,         
       Pu_Id    ,   
       Prod_id   ,     
       Var_Desc   ,   
       Spec_id   ,  
       Sampling_INTerval ,   
       Sampling_Offset ,  
       Eng_Units   ,  
       Col_INTerval  ,  
       Col_Offset   ,  
       Var_Order )   
  
SELECT         
       PL.PL_Id   ,  
       V.Var_Id   ,  
       V.Pu_id   ,  
       P.Prod_id   ,  
       V.Var_Desc   ,   
       V.Spec_Id      ,  
       Sampling_INTerval ,   
       Sampling_Offset ,  
       V.Eng_Units  ,  
       'G' as Col_INTerval,  
       'G' AS Col_Offset ,  
       SV.Var_Order  
FROM       dbo.Variables V   
       JOIN dbo.Sheet_Variables SV  WITH(NOLOCK) ON  SV.Var_ID  =  V.Var_ID   
       JOIN dbo.Sheets S     WITH(NOLOCK) ON  S.Sheet_ID  =  SV.sheet_ID   
       JOIN #PLIDList PL         ON  S.Sheet_Desc =  PL.Sheet_Desc  
      ,#ProdIDList P     
-- For tests  
--select 'Test '+ @RptName, '#Var_Specs after insert #1--> ',* from #Var_Specs  
  
         
INSERT INTO #Var_Specs (  
      PL_Id    ,  
      Var_Id    ,         
      Pu_Id    ,       
      Var_Desc   ,   
      Spec_Id    ,  
      Eng_Units   ,  
      Sampling_INTerval ,   
      Sampling_Offset )  
SELECT        
      PL.PL_Id   ,  
      V.Var_Id   ,  
      V.Pu_id    ,  
      V.Var_Desc   ,   
      V.Spec_Id   ,  
      V.Eng_Units   ,  
      Sampling_INTerval ,   
      Sampling_Offset   
FROM      dbo.Variables      V  WITH(NOLOCK)  
      JOIN dbo.Prod_Units      pu  WITH (NOLOCK)          
              ON  V.PU_Id = Pu.pU_ID  
      JOIN #PLIDList PL     ON   PL.PL_Id =  pu.PL_Id  
      JOIN dbo.PU_Groups    pg  WITH (NOLOCK)  
              ON  pu.PU_Id = pg.PU_Id  
      JOIN dbo.Table_Fields_Values tfv  WITH (NOLOCK)  
              ON  tfv.KeyId = pg.PUG_Id  
WHERE             
      tfv.TableId = @intTableId  
      AND tfv.Table_Field_Id = @intTableFieldId  
      AND tfv.Value = 'Yes'  
      AND pg.PU_Id > 0  
      AND NOT EXISTS (SELECT * FROM dbo.Sheets WHERE Sheet_Desc = PL.Sheet_Desc)  
  
-- For tests  --select 'Test '+ @RptName, '#Var_Specs after insert #2 --> ',* from #Var_Specs  
  
-----------------------------------------------------------------------------------------------------------  
  
UPDATE #Var_Specs   
    SET     L_Reject   = VS.L_Reject ,   
       L_Warning   = VS.L_Warning ,   
       L_User    = VS.L_User  ,   
       Target    = VS.Target  ,   
       U_User    = VS.U_User  ,   
       U_Warning   = VS.U_Warning ,   
       U_reject   = VS.U_reject ,   
       Test_Freq   = VS.Test_Freq ,         
       String    = ALY.String        
FROM       #Var_Specs v  
       JOIN dbo.Var_Specs VS    WITH(NOLOCK)   
              ON  VS.Var_ID  =  V.Var_ID   
              AND v.Prod_Id = vs.Prod_id  
       JOIN dbo.Specifications SP  WITH(NOLOCK) ON  SP.Spec_id  =  v.Spec_id         
       LEFT JOIN (SELECT Var_ID,'VC' AS String   
             FROM Variables WHERE Extended_Info LIKE '%VC=Y%') ALY   
                ON ALY.Var_ID = V.Var_ID   
WHERE   
      VS.Effective_Date <=  @strRptStartDate   
      AND (VS.Expiration_date >= @strRptStartDate   
          OR vs.Expiration_date IS NULL)         
--      AND vs.Test_Freq <> 0   
      AND SP.Spec_Desc NOT LIKE '%Test Complete%'  
  
-- Note: VC = Variable Control  
  
-- 'G' Green 'R' Red  
IF @Interval > 0   
   UPDATE #Var_Specs   
           SET Col_INTerval = (Case WHEN Sampling_INTerval % @INTerval = 0 THEN 'G' ELSE 'R' END)  
              
IF @Offset > 0   
   UPDATE #Var_Specs   
           SET Col_OffSet = (Case WHEN Sampling_Offset % @Offset = 0 THEN 'G' ELSE 'R' END)  
  
-- Get the User_Defined2 specificatiON to change the target  
-- Fix error here  
UPDATE #Var_Specs  
        SET UD2_Spec_Id = V.User_Defined2  
FROM dbo.Variables V WITH(NOLOCK)  
   JOIN #Var_Specs VS ON V.Var_Id = VS.Var_Id  
WHERE V.User_Defined2 IS Not NULL  
-- Add for Galanzini.p  
  AND ISNUMERIC(V.User_Defined2) = 1  
  
  
UPDATE #Var_Specs   
        SET Target = A_S.L_Warning + '/' + A_S.U_Warning   
FROM #Var_Specs VS  
  JOIN dbo.Active_Specs A_S    WITH(NOLOCK)  ON   A_S.Spec_Id = VS.UD2_Spec_Id  
  JOIN dbo.PU_Characteristics puc  WITH(NOLOCK)  ON   puc.char_id = A_S.Char_id   
                  AND puc.pu_id = VS.pu_id   
                  AND puc.Prod_id = VS.Prod_Id  
WHERE   A_S.Effective_Date <=  @strRptStartDate   
   AND (A_S.Expiration_date >= @strRptStartDate   
          OR A_S.Expiration_date IS NULL)   
  
-- For tests  
--select '#Var_Specs before Output --> ',* from #Var_Specs   
  
--SELECT COUNT(*) FROM #Var_Specs  
--SELECT 'BORRA ', VS.Test_Freq , VS.L_Reject, VS.L_Warning ,VS.L_User , VS.U_User ,VS.U_Warning ,VS.U_reject ,*  
-- FROM #Var_Specs VS     
  
-- galanzini.p (aridosoft)  
-- Delete Variables with test_freq is null or <1 and not have Specs  
DELETE FROM #Var_Specs    
WHERE   
 (L_Reject IS NULL AND L_Warning IS NULL AND L_User IS NULL   
 AND U_User IS NULL AND U_Warning IS NULL AND U_reject IS NULL)  
 AND (  Test_Freq IS NULL  
   OR ( Test_Freq IS NOT NULL   
     AND ISNUMERIC(Test_Freq) = 1  
     AND Test_Freq < 1))   
  
-----------------------------------------------------------------------------------------------  
--          FINAL OUTPUT            --  
-----------------------------------------------------------------------------------------------  
  
SELECT     @ProdId    =  0  ,  
     @ProdRECNo    =  0  ,  
     @PLId     =  0  ,  
     @PLRECNo    =  0  
  
  
IF NOT EXISTS (SELECT * FROM #ProdIDList)  
BEGIN  
   SELECT @PLDesc = PL_Desc FROM #PLIDList    
  
   SELECT     @Plant       Plant,  
        @PLDesc       Line,  
        @strRptStartDate     StartDate,  
        ''        ProdCode,  
        'No Product'     ProdDesc,  
        Sheet_Desc      Display,  
        'No Interval'      Interval   
    FROM #PLIDList PL  
   
   INSERT INTO #Var_Specs (Var_Desc) VALUES ('NO DATA')  
    
    SELECT      VS.Var_Desc    ,   
                VS.Eng_Units   ,   
                VS.L_Reject    ,   
                VS.L_Warning   ,   
                VS.L_User    ,   
                VS.Target    ,   
                VS.U_User    ,   
                VS.U_Warning   ,   
                VS.U_reject    ,   
                VS.Test_Freq   ,   
                Sampling_INTerval  ,  
                Sampling_Offset   ,  
                ' '    Comments,   
                Col_INTerval   ,  
                Col_Offset   
    FROM      #Var_Specs VS     
  
END  
  
ELSE   
BEGIN  
  
 WHILE @ProdRECNo < (SELECT COUNT(*) FROM #ProdIDList)  
  
 BEGIN  
  
  SELECT @ProdId = MIN (Prod_ID) FROM #ProdIDList WHERE Prod_ID > @ProdId  
  SELECT @ProdDesc = Prod_Desc, @ProdCode = Prod_Code FROM #ProdIDList WHERE Prod_ID = @ProdId   
  
  
  WHILE @PLRECNo < (SELECT COUNT(*) FROM #PLIDList)  
   
  BEGIN  
   SELECT @PLId = MIN (Pl_ID) FROM #PLIDList WHERE PL_ID > @PLId  
   SELECT @PLDesc = PL_Desc FROM #PLIDList WHERE PL_ID = @PLId   
  
   -- TEST  
--   SELECT 'Product Output', @ProdId ProdId, @ProdDesc ProdDesc, @ProdCode ProdCode, @PLId PLId, @PLDesc PLDesc  
  
   SELECT     @Plant               Plant,  
        @PLDesc               Line,  
        @strRptStartDate             StartDate,  
        ISNULL(@ProdCode,'No ProdCode')         ProdCode,  
        ISNULL(@ProdDesc,'No Product')         ProdDesc,  
        Sheet_Desc              Display,  
        'Every ' + CONVERT(VARCHAR,Interval) +   
        ' minutes, starting at ' +   
        RIGHT(CONVERT(VARCHAR,DATEADD(mi,Offset,'1900-1-1 00:00AM')),7) Interval   
    FROM #PLIDList PL  
    WHERE PL_Id = @PLId        
  
   SELECT      VS.Var_Desc    ,   
               ISNULL(VS.Eng_Units,'')   Eng_Units,   
               ISNULL(VS.L_Reject,'')   L_Reject,   
               ISNULL(VS.L_Warning,'')   L_Warning,   
               ISNULL(VS.L_User,'')   L_User,   
               ISNULL(VS.Target,'')   Target,   
               ISNULL(VS.U_User,'')   U_User,   
               ISNULL(VS.U_Warning,'')   U_Warning,   
               ISNULL(VS.U_reject,'')   U_reject,   
               ISNULL(VS.Test_Freq,'')   Test_Freq,   
               VS.Sampling_INTerval   ,  
               VS.Sampling_Offset    ,  
               ' '        Comments,   
               VS.Col_INTerval     ,  
               VS.Col_Offset   
    FROM      #Var_Specs VS     
    WHERE     VS.Prod_Id  =  @ProdId  
          AND VS.PL_ID =  @PLId  
          -- galanzini.p (aridosoft)  
          AND ((VS.Test_Freq IS NOT NULL  
          AND ISNUMERIC(VS.Test_Freq) = 1  
          AND VS.Test_Freq > 0)  
          OR VS.L_Reject IS NOT NULL   
          OR VS.L_Warning IS NOT NULL  
          OR VS.L_User IS NOT NULL  
          OR VS.U_User IS NOT NULL  
          OR VS.U_Warning IS NOT NULL  
          OR VS.U_reject IS NOT NULL)  
    ORDER BY     Var_Order  
  
    -- for test  
/*  
    SELECT VS.Prod_Id, @ProdId, VS.PL_ID, @PLId, VS.Target   
     FROM #Var_Specs VS  
     where VS.Target IS NOT NULL AND VS.PL_ID = @PLId  
*/  
    SET @PLRECNo = @PLRECNo + 1  
  
  END   
     
  SET @ProdRECNo = @ProdRECNo + 1  
  
 END  
END  
---------------------------------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------------------------------  
-- For Test in test_freq  
/*  
SELECT '#Var_Specs',VS.Test_Freq,VS.L_Reject,VS.L_Warning , VS.L_User ,VS.Target ,VS.U_User ,VS.U_Warning ,VS.U_reject,*  
 FROM #Var_Specs VS  
WHERE (VS.Test_Freq IS NOT NULL AND ISNUMERIC(VS.Test_Freq) = 1 AND VS.Test_Freq = 0)   
AND (VS.L_Reject IS NOT NULL AND VS.L_Warning IS NOT NULL AND VS.L_User IS NOT NULL  
AND VS.U_User IS NOT NULL AND VS.U_Warning IS NOT NULL AND VS.U_reject IS NOT NULL)  
*/  
  
DROP TABLE #Var_Specs  
DROP TABLE #ProdIDList  
DROP TABLE #PLIDList  
---------------------------------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------------------------------  
  
RETURN  
  
  

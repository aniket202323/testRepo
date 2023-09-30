CREATE PROCEDURE dbo.spSDK_QueryInputSourceEvents
 	 @LineMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @InputMask 	  	  	 nvarchar(50) 	 = NULL,
 	 @EventMask 	  	  	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	  	  	 INT 	  	  	  	  	 = NULL,
 	 @PrimaryMask 	  	 nvarchar(50) 	 = NULL,
 	 @AlternateMask 	 nvarchar(50) 	 = NULL
AS
Declare @Now DateTime
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @InputMask = REPLACE(COALESCE(@InputMask, '*'), '*', '%')
SELECT 	 @InputMask = REPLACE(REPLACE(@InputMask, '?', '_'), '[', '[[]')
SELECT 	 @EventMask = REPLACE(COALESCE(@EventMask, '*'), '*', '%')
SELECT 	 @EventMask = REPLACe(REPLACE(@EventMask, '?', '_'), '[', '[[]')
IF @PrimaryMask Is Not Null
 	 BEGIN
 	  	 SELECT @PrimaryMask = REPLACE(COALESCE(@PrimaryMask, '*'), '*', '%')
 	  	 SELECT @PrimaryMask = REPLACE(REPLACE(@PrimaryMask, '?', '_'), '[', '[[]')
 	 END
IF @ALternateMask 	 Is Not Null
 	 BEGIN
 	  	 SELECT @AlternateMask = REPLACE(COALESCE(@AlternateMask, '*'), '*', '%')
 	  	 SELECT @AlternateMask = REPLACE(REPLACE(@AlternateMask, '?', '_'), '[', '[[]')
 	 END
DECLARE @Units TABLE (PU_Id INT)
--CREATE TABLE @Units (PU_Id INT)
INSERT INTO @Units
 	 SELECT PU_Id
 	  	 FROM Prod_Units
 	  	 WHERE PU_Desc LIKE @UnitMask
--SELECT * FROM @Units
DECLARE @CurrentProducts TABLE (Prod_Id INT)
--CREATE TABLE @CurrentProducts (Prod_Id INT)
INSERT INTO @CurrentProducts
 	 SELECT Prod_Id
  FROM Production_Starts 
  WHERE PU_Id in (SELECT PU_Id FROM @Units) 
 	 AND (Start_Time <= @Now AND (End_time > @Now OR End_time is NULL))
 	 AND Prod_Id <> 1
--SELECT * FROM @CurrentProducts
DECLARE @PrimarySpecs TABLE (Spec_Id INT, Prop_Id INT)
--CREATE TABLE @PrimarySpecs (Spec_Id INT, Prop_Id INT)
INSERT INTO @PrimarySpecs
 	 SELECT Spec_Id, Prop_Id
 	  	 FROM Specifications
 	  	 WHERE Spec_Desc LIKE @PrimaryMask
--SELECT * FROM @PrimarySpecs
DECLARE @AlternateSpecs TABLE (Spec_Id INT, Prop_Id INT)
--CREATE TABLE @AlternateSpecs (Spec_Id INT, Prop_Id INT)
INSERT INTO @AlternateSpecs
 	 SELECT Spec_Id, Prop_Id
 	  	 FROM Specifications
 	  	 WHERE Spec_Desc LIKE @AlternateMask
--SELECT * FROM @AlternateSpecs
DECLARE @PrimaryPUChars TABLE (Char_Id INT)
--CREATE TABLE @PrimaryPUChars (Char_Id INT)
INSERT INTO @PrimaryPUChars
 	 SELECT Char_Id
 	  	 FROM PU_Characteristics 
 	  	 WHERE PU_Id IN (SELECT PU_Id From @Units)
 	  	 AND Prop_Id IN (SELECT Prop_Id From @PrimarySpecs)
 	  	 AND Prod_Id IN (SELECT Prod_Id From @CurrentProducts)
--SELECT * FROM @PrimaryPUChars
DECLARE @AlternatePUChars TABLE (Char_Id INT)
--CREATE TABLE @AlternatePUChars (Char_Id INT)
INSERT INTO @AlternatePUChars
 	 SELECT Char_Id
 	  	 FROM PU_Characteristics 
 	  	 WHERE PU_Id IN (SELECT PU_Id From @Units)
 	  	 AND Prop_Id IN (SELECT Prop_Id From @AlternateSpecs)
 	  	 AND Prod_Id IN (SELECT Prod_Id From @CurrentProducts)
--SELECT * FROM @AlternatePUChars
DECLARE @PrimaryProdCodes TABLE (Prod_Code nvarchar(25))
--CREATE TABLE @PrimaryProdCodes (Prod_Code nvarchar(25))
INSERT INTO @PrimaryProdCodes
 	 SELECT Target
 	  	 FROM Active_Specs
    WHERE Spec_Id IN (SELECT Spec_Id FROM @PrimarySpecs) AND Char_Id IN (SELECT Char_Id FROM @PrimaryPUChars)
    AND (Effective_Date < @Now AND (Expiration_Date is NULL OR Expiration_Date > @Now))
--SELECT * FROM @PrimaryProdCodes
DECLARE @AlternateProdCodes TABLE (Prod_Code nvarchar(25))
--CREATE TABLE @AlternateProdCodes (Prod_Code nvarchar(25))
INSERT INTO @AlternateProdCodes
 	 SELECT Target
 	  	 FROM Active_Specs
    WHERE Spec_Id IN (SELECT Spec_Id FROM @AlternateSpecs) AND Char_Id IN (SELECT Char_Id FROM @AlternatePUChars)
    AND (Effective_Date < @Now AND (Expiration_Date is NULL OR Expiration_Date > @Now))
--SELECT * FROM @AlternateProdCodes
--CREATE TABLE @Output 
DECLARE @Output TABLE
 	 (ProductionEventId INT, 
 	 DepartmentName nvarchar(50), 
 	 LineName nvarchar(50), 
 	 UnitName nvarchar(50), 
 	 EventName nvarchar(25), 
 	 EventType nvarchar(50), 
 	 EventStatus nvarchar(50), 
 	 TestingStatus nvarchar(50), 
 	 OriginalProduct nvarchar(25), 
 	 AppliedProduct nvarchar(25), 
 	 ProcessOrder nvarchar(50), 
 	 StartTime DATETIME, 
 	 EndTime DATETIME, 
 	 InitialDimensionX REAL, 
 	 InitialDimensionY REAL, 
 	 InitialDimensionZ REAL, 
 	 InitialDimensionA REAL, 
 	 FinalDimensionX REAL, 
 	 FinalDimensionY REAL, 
 	 FinalDimensionZ REAL, 
 	 FinalDimensionA REAL, 
 	 CommentId INT, 
 	 ExtendedInfo nvarchar(255),
 	 SignatureId 	 INT
 	 )
---CREATE 	 TABLE 	 @EventList (
DECLARE @EventList TABLE(
 	 Event_Id 	  	  	  	 INT,
 	 PU_Id 	  	  	  	  	 INT,
 	 Event_Status 	  	 INT,
 	 Timestamp 	  	  	 DATETIME,
 	 Applied_Product 	 INT,
 	 Event_Num 	  	  	 nvarchar(25),
 	 Comment_Id 	  	  	 INT,
 	 Extended_Info 	  	 nvarchar(255),
 	 SignatureId 	  	  	 INT
)
INSERT INTO @EventList (Event_Id, PU_Id, Event_Status, Timestamp, 
 	  	  	  	  	  	  	  	 Applied_Product, Event_Num, Comment_Id, Extended_Info,SignatureId)
 	 SELECT 	 DISTINCT 
 	  	  	  	 e.Event_Id,
 	  	  	  	 e.PU_Id,
 	  	  	  	 e.Event_Status,
 	  	  	  	 e.Timestamp,
 	  	  	  	 e.Applied_Product,
 	  	  	  	 e.Event_Num,
 	  	  	  	 e.Comment_Id,
 	  	  	  	 e.Extended_Info,
 	  	  	  	 e.Signature_Id
 	  	 FROM 	  	  	 Prod_Lines ipl
 	  	 INNER JOIN 	 Prod_Units ipu  	  	  	  	  	  	 ON 	  	 ipl.PL_Id = ipu.PL_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipu.PU_Desc LIKE @UnitMask
 	  	 LEFT JOIN 	 User_Security ipls 	  	  	  	  	 ON  	 ipl.Group_Id = ipls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipls.User_Id = @UserId
 	  	 LEFT JOIN 	 User_Security ipus 	  	  	  	  	 ON 	  	 ipu.Group_Id = ipus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipus.User_Id = @UserId
 	  	 INNER JOIN 	 PrdExec_Inputs pei  	  	  	  	  	 ON 	  	 ipu.PU_Id = pei.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND  	 pei.Input_Name LIKE @InputMask 
 	  	 INNER JOIN 	 PrdExec_Input_Sources peis 	  	  	 ON  	 pei.PEI_Id = PEIS.PEI_Id
 	  	 INNER JOIN 	 PrdExec_Input_Source_Data peisd 	 ON  	 peis.PEIS_Id = peisd.PEIS_Id
 	  	 INNER JOIN 	 Events e 	  	  	  	  	  	  	  	  	 ON 	  	 e.PU_Id = peis.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 e.Event_Status = peisd.Valid_Status
 	  	 INNER JOIN 	 Prod_Units pu  	  	  	  	  	  	  	 ON pu.pu_id = e.pu_id
 	  	 INNER JOIN 	 Prod_Lines pl 	  	  	  	  	  	  	 ON pl.pl_id = pu.pl_id
 	  	 WHERE 	 ipl.PL_Desc LIKE @LineMask
 	  	 AND 	 e.Event_Num LIKE @EventMask
 	  	 AND 	 COALESCE(ipus.Access_Level, COALESCE(ipls.Access_Level, 3)) >= 2
--Mask For Name Has Been Specified
INSERT INTO @Output (ProductionEventId, DepartmentName, LineName, UnitName, EventName, EventType, EventStatus, TestingStatus, 
 	  	  	  	  	  	 OriginalProduct, AppliedProduct, ProcessOrder, StartTime, EndTime, InitialDimensionX, InitialDimensionY, 
 	  	  	  	  	  	 InitialDimensionZ, InitialDimensionA, FinalDimensionX, FinalDimensionY, FinalDimensionZ, FinalDimensionA, 
 	  	  	  	  	  	 CommentId, ExtendedInfo,SignatureId)
SELECT DISTINCT 
 	  	  	 e.Event_Id,
 	  	  	 d.Dept_Desc,
 	  	  	 pl.PL_Desc,
 	  	  	 pu.PU_Desc, 
 	  	  	 e.Event_Num, 
 	  	  	 es.Event_Subtype_Desc,
 	  	  	 ps.ProdStatus_Desc, 
 	  	  	 'Unknown',
 	  	  	 p1.Prod_Code, 
 	  	  	 p2.Prod_Code, 
 	  	  	 po.Process_Order,
 	  	  	 dbo.fnCmn_GetEventStartTime(e.Event_Id) , 
 	  	  	 e.Timestamp, 
 	  	  	 ed.Initial_Dimension_X, 
 	  	  	 ed.Initial_Dimension_Y, 
 	  	  	 ed.Initial_Dimension_Z,
 	  	  	 ed.Initial_Dimension_A,
 	  	  	 ed.Final_Dimension_X, 
 	  	  	 ed.Final_Dimension_Y, 
 	  	  	 ed.Final_Dimension_Z,
 	  	  	 ed.Final_Dimension_A,
 	  	  	 e.Comment_Id,
 	  	  	 e.Extended_Info,
 	  	  	 e.SignatureId
 	 FROM 	  	  	 @EventList e
 	 JOIN 	  	  	 Event_Configuration ec 	  	  	  	 ON 	  	 e.PU_Id = ec.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec.ET_Id = 1
 	 JOIN 	  	  	 Event_SubTypes es 	  	  	  	  	  	 ON 	  	 ec.Event_SubType_Id = es.Event_SubType_Id 	 
 	 JOIN 	  	  	 Production_Status ps 	  	  	  	  	 ON  	 ps.ProdStatus_Id = e.Event_Status
 	 JOIN  	  	  	 Production_Starts s 	  	  	  	  	 ON 	  	 s.PU_Id = e.pu_id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 s.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (s.End_Time > e.TimeStamp OR s.End_Time IS NULL)
 	 JOIN  	  	  	 Products p1  	  	  	  	  	  	  	 ON  	 p1.Prod_Id = s.Prod_Id
 	 LEFT JOIN  	 Products p2  	  	  	  	  	  	  	 ON  	 p2.Prod_Id = e.Applied_Product 
 	 JOIN  	  	  	 Prod_Units pu  	  	  	  	  	  	  	 ON  	 pu.pu_id = e.pu_id
 	 JOIN  	  	  	 Prod_Lines pl  	  	  	  	  	  	  	 ON  	 pl.pl_id = pu.pl_id 	 
 	 JOIN  	  	  	 Departments d 	  	  	  	  	  	  	 ON  	 pl.Dept_Id = d.Dept_Id
 	 LEFT JOIN 	 User_Security pls 	  	  	  	  	  	 ON  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	  	  	  	  	 ON  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId
 	 LEFT JOIN 	 Production_Plan_Starts pos  	  	 ON  	 pos.PU_Id = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pos.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (pos.End_Time > e.TimeStamp OR pos.End_Time IS NULL)
 	 LEFT JOIN  	 Production_Plan po  	  	  	  	  	 ON 	  	 po.PP_Id = pos.PP_Id 
 	 LEFT JOIN 	 Event_Details ed  	  	  	  	  	  	 ON  	 ed.Event_Id = e.Event_Id
 	 WHERE 	 e.Event_Num LIKE @EventMask
 	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
--SELECT EventName, OriginalProduct, AppliedProduct, * FROM @Output
--SELECT COUNT(*) AS 'ORIGINAL PRODUCT COUNT' FROM @Output WHERE OriginalProduct IS NOT NULL
--SELECT COUNT(*) AS 'APPLIED PRODUCT COUNT' FROM @Output WHERE AppliedProduct IS NOT NULL
-- SELECT * FROM @Output
--  	 WHERE AppliedProduct NOT IN (SELECT Prod_Code FROM @PrimaryProdCodes)
--  	 AND AppliedProduct NOT IN (SELECT Prod_Code FROM @AlternateProdCodes)
--  	 AND AppliedProduct IS NOT NULL
IF @PrimaryMask 	 Is Not Null or @AlternateMask Is Not Null
 	 BEGIN
 	  	 DELETE FROM @Output
 	  	  	 WHERE AppliedProduct NOT IN (SELECT Prod_Code FROM @PrimaryProdCodes)
 	  	  	 AND AppliedProduct NOT IN (SELECT Prod_Code FROM @AlternateProdCodes)
 	  	  	 AND AppliedProduct IS NOT NULL
 	 END
-- SELECT * FROM @Output
--  	 WHERE OriginalProduct NOT IN (SELECT Prod_Code FROM @PrimaryProdCodes)
--  	 AND OriginalProduct NOT IN (SELECT Prod_Code FROM @AlternateProdCodes)
--  	 AND AppliedProduct IS NULL
IF @PrimaryMask 	 Is Not Null or @AlternateMask Is Not Null
 	 BEGIN
 	  	 DELETE FROM @Output
 	  	  	 WHERE OriginalProduct NOT IN (SELECT Prod_Code FROM @PrimaryProdCodes)
 	  	  	 AND OriginalProduct NOT IN (SELECT Prod_Code FROM @AlternateProdCodes)
 	  	  	 AND AppliedProduct IS NULL
 	 END
SELECT ProductionEventId, DepartmentName, LineName, UnitName, 	 EventName, EventType, EventStatus, TestingStatus, 
 	  	  	  OriginalProduct, AppliedProduct, ProcessOrder, StartTime, EndTime, InitialDimensionX, InitialDimensionY, 
 	  	  	  InitialDimensionZ, InitialDimensionA, FinalDimensionX, FinalDimensionY, FinalDimensionZ, FinalDimensionA, 
 	  	  	  CommentId, ExtendedInfo,SignatureId
 	 FROM @Output
 	 ORDER BY EndTime ASC
--DROP TABLE @Units
--DROP TABLE @CurrentProducts
--DROP TABLE @PrimarySpecs
--DROP TABLE @AlternateSpecs
--DROP TABLE @PrimaryPUChars
--DROP TABLE @AlternatePUChars
--DROP TABLE @PrimaryProdCodes
--DROP TABLE @AlternateProdCodes
--DROP TABLE @Output

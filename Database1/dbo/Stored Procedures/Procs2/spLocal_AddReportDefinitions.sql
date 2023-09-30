/*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-26  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Version 1  
--  
-- 2002-07-23 Vince King  
--  
--   This stored procedure takes a Report_Type_Id and checks to make sure that all Report Type Parameters are  
--  are assigned to all Report Definitions.  If the parameter is not assigned to a Report Definition, it is   
--  inserted into the Report_Definition_Parameters table with the Default Value used in the   
--  Report_Type_Parameters table.  
--  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE  PROCEDURE dbo.spLocal_AddReportDefinitions  
 @ReportTypeId   Integer  -- Report_Type_Id used to add parameters to Report_Definition.  
  
AS  
  
SET NOCOUNT ON  
  
-----------------------------------------------------------------------------------------  
-- Create temporary tables.  
-----------------------------------------------------------------------------------------  
  
 DECLARE @RTParameters table (Report_Type_Id Integer, RTP_Id Integer,DefaultValue VarChar(7000))  
 DECLARE @ReportDefs table  (ReportId Integer, ReportTypeId Integer)  
 DECLARE @RDParameters table  (RTP_Id Integer, Report_Id Integer, Value Integer)  
 DECLARE @RDParmsAdded table  (RPName VarChar(100), RDDesc VarChar(100), RPValue VarChar(100))  
  
----------------------------------------------------------------------------------------  
-- Declare procedure variables.  
----------------------------------------------------------------------------------------  
  
DECLARE  @@RTPId   Integer,  
  @@ReportId  Integer,  
  @@DefaultValue  VarChar(7000),  
  @RPName   VarChar(100),  
  @RDDesc   VarChar(100)  
  
-----------------------------------------------------------------------------------------  
-- Insert the report type parameters into a temp table.  
-----------------------------------------------------------------------------------------  
  
INSERT INTO @RTParameters (Report_Type_Id, RTP_Id, DefaultValue)  
 SELECT  Report_Type_Id, RTP_Id, Default_Value  
 FROM  [dbo].Report_Type_Parameters  
 WHERE Report_Type_Id = @ReportTypeId  
  
-----------------------------------------------------------------------------------------  
-- Get the Report Definitions and insert into a temp table.  
-----------------------------------------------------------------------------------------  
  
INSERT INTO @ReportDefs (ReportId, ReportTypeId)  
 SELECT Report_Id, Report_Type_Id  
 FROM [dbo].Report_Definitions  
 WHERE  Report_Type_Id = @ReportTypeId  
  
-----------------------------------------------------------------------------------------  
-- Read the Report Definitions, check to see if the Report Type Parameter exists.  
-- If it does not exist, add it to the report definition.  
-----------------------------------------------------------------------------------------  
  
DECLARE RTParametersCursor INSENSITIVE CURSOR FOR  
 (SELECT rtp.RTP_Id, rd.ReportId, DefaultValue  
  FROM @RTParameters rtp  
   JOIN @ReportDefs rd ON rtp.Report_Type_Id = rd.ReportTypeId)  
 FOR READ ONLY  
OPEN RTParametersCursor  
FETCH NEXT FROM RTParametersCursor INTO @@RTPId, @@ReportId, @@DefaultValue  
WHILE @@Fetch_Status = 0  
BEGIN  
  
 IF (SELECT COUNT(RTP_Id)   
  FROM [dbo].Report_Definition_Parameters  
  WHERE RTP_Id = @@RTPId  
   AND Report_Id = @@ReportId) = 0  
 BEGIN  
  INSERT INTO [dbo].Report_Definition_Parameters (RTP_Id, Report_Id, Value)  
   SELECT @@RTPId, @@ReportId, @@DefaultValue  
  SELECT @RPName = (SELECT RP_Name FROM [dbo].Report_Type_Parameters rtp  
       JOIN [dbo].Report_Parameters rp ON rtp.RP_Id = rp.RP_Id  
       WHERE RTP_Id = @@RTPId)  
  SELECT @RDDesc = (SELECT Report_Name FROM [dbo].Report_Definitions WHERE Report_Id = @@ReportId)  
  INSERT INTO @RDParmsAdded (RPName, RDDesc, RPValue) VALUES (@RPName, @RDDesc, @@DefaultValue)  
 END  
  
 FETCH NEXT FROM RTParametersCursor INTO @@RTPId, @@ReportId, @@DefaultValue  
END  
CLOSE RTParametersCursor  
DEALLOCATE RTParametersCursor  
  
-----------------------------------------------------------------------------------------  
-- Report any additions.  
-----------------------------------------------------------------------------------------  
  
SELECT RPName, RDDesc, RPValue FROM @RDParmsAdded  
  
SET NOCOUNT OFF  
  

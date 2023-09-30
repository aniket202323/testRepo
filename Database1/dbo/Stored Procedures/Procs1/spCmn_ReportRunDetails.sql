-------------------------------------------------------------------------------
-- Desc:
-- This stored procedure retuns report run information
--
-- Edit History:
-- AW 02-Jun-2003 MSI Development 	 
--
-- Example:
/*
-- can use wild cards on @Template and @Definition
SET nocount on
Exec spCmn_ReportRunDetails 
 	 @Template 	  	 = 'QuaEventBased', 
 	 @Definition 	  	 = 'QuaPM3LaboresultatenSC-Yesterday',
 	 @Engine 	  	  	 = NULL,
 	 @Service 	  	  	 = NULL
SET nocount off
*/
-------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spCmn_ReportRunDetails
 	  	  	 @Template 	  	 VARCHAR(100) = NULL, 
 	  	  	 @Definition 	  	 VARCHAR(100) = NULL,
 	  	  	 @Engine 	  	  	 VARCHAR(100) = NULL,
 	  	  	 @Service 	  	  	 VARCHAR(100) = NULL
AS
 	  	  	 
DECLARE 	 @RunId 	  	  	 INT,
 	  	  	 @ReportId 	  	 INT
SELECT 	 @Template 	 = 	 REPLACE(COALESCE(@Template, '%'), '*', '%'),
 	  	  	 @Definition = 	 REPLACE(COALESCE(@Definition, '%'), '*', '%'),
 	  	  	 @Engine  	  	 =  	 REPLACE(COALESCE(@Engine, '%'), '*', '%'),
 	  	  	 @Service  	 = 	 REPLACE(COALESCE(@Service, '%'), '*', '%')
SELECT 	 @Template 	 = 	 REPLACE(@Template, '?', '_'),
 	  	  	 @Definition =  	 REPLACE(@Definition, '?', '_'),
 	  	  	 @Engine  	  	 =  	 REPLACE(@Engine, '?', '_'),
 	  	  	 @Service  	 =  	 REPLACE(@Service, '?', '_')
SELECT 	 TOP 1
 	  	  	 @RunId = rr.Run_Id,
 	  	  	 @ReportId = rr.Report_Id
 	 FROM 	 Report_Types rt
 	 JOIN 	 Report_Definitions rd 	 ON 	  	 rt.Report_Type_Id = rd.Report_Type_Id
 	 JOIN 	 Report_Runs rr 	  	  	  	 ON  	 rr.Report_Id = rd.Report_Id
 	 JOIN 	 Report_Engines re 	  	  	 ON 	  	 rr.Engine_Id = re.Engine_Id
 	 WHERE 	 rt.Description LIKE @Template
 	 AND 	 rd.Report_Name LIKE @Definition
 	 AND 	 re.Engine_Name LIKE @Engine
 	 AND 	 re.Service_Name LIKE @Service
 	 ORDER BY rr.Start_Time DESC
SELECT 	 Template = rt.Description, 
 	  	  	 Definition = rd.Report_Name, 
 	  	  	 FileName = rd.File_Name, 
 	  	  	 Engine = re.Engine_Name,
 	  	  	 Service = re.Service_Name,
 	  	  	 rr.Start_Time, 
 	  	  	 rr.End_Time, 
 	  	  	 rr.Status, 
 	  	  	 rr.Error_Id
 	 FROM 	 Report_Types rt
 	 JOIN 	 Report_Definitions rd 	 ON 	  	 rt.Report_Type_Id = rd.Report_Type_Id
 	 JOIN 	 Report_Runs rr 	  	  	  	 ON  	 rr.Report_Id = rd.Report_Id
 	 JOIN 	 Report_Engines re 	  	  	 ON 	  	 rr.Engine_Id = re.Engine_Id
 	 WHERE 	 rr.Run_Id = @RunId
SELECT 	 RP_Name,
 	  	  	 Value
 	 FROM 	 Report_Parameters rp
 	 JOIN 	 Report_Type_Parameters rtp 	  	  	 ON 	 rp.RP_Id = rtp.RP_Id
 	 JOIN 	 Report_Definition_Parameters rdp 	 ON rtp.RTP_Id = rdp.RTP_Id
 	 WHERE 	 Report_Id = @ReportId
SELECT 	 rea.Time, 
 	  	  	 rea.Message
 	 FROM 	 Report_Engine_Activity rea
 	 JOIN 	 Report_Runs rr 	  	  	  	  	 ON  	 rr.Engine_Id = rea.Engine_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 rea.Time BETWEEN rr.Start_Time AND COALESCE(rr.End_Time, GETDATE())
 	 JOIN 	 Report_Definitions rd 	  	 ON 	  	 rr.Report_Id = rd.Report_Id
 	 JOIN 	 Report_Types rt 	  	  	  	 ON 	  	 rt.Report_Type_Id = rd.Report_Type_Id
 	 WHERE 	 rr.Run_Id = @RunId
 	 ORDER BY rea.REA_Id
RETURN

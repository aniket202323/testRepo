CREATE PROCEDURE dbo.spRS_AdminAddReportDefinition
 	 @Report_Id    	  	 INT,
 	 @Report_Type_Id 	  	 INT,
 	 @Class 	  	  	  	 INT = NULL,
 	 @Priority 	  	  	 INT = NULL,
 	 @Report_Name 	  	 VARCHAR(255) = NULL,
 	 @File_Name 	  	  	 VARCHAR(255) = NULL,
 	 @Security_Group_Id 	 INT = NULL,
 	 @AutoRefresh 	  	 INT = 0,
 	 @Image_Ext 	  	  	 VARCHAR(20) = NULL,
 	 @Native_Ext 	  	  	 VARCHAR(20) = NULL, 
 	 @OwnerId 	  	  	 INT
 AS
DECLARE @EXISTS INT
--------------------------------
-- CREATE NEW REPORT DEFINITION
--------------------------------
IF @Report_Id IS NULL
  BEGIN
 	 INSERT INTO REPORT_DEFINITIONS(Report_Id,  Class,  Priority,  Report_Type_Id,  Report_Name,  File_Name,  Security_Group_Id,  AutoRefresh, TimeStamp, Image_Ext, Native_Ext, OwnerId)
 	  	  	  	  	  	    VALUES(@Report_Id, @Class, @Priority, @Report_Type_Id, @Report_Name, @File_Name, @Security_Group_Id, @AutoRefresh, GetDate(), @Image_Ext, @Native_Ext, @OwnerId)
 	 SELECT @EXISTS = Scope_Identity()
  END
--------------------------------
-- UPDATE EXISTING DEFINITION
--------------------------------
ELSE
  BEGIN
 	 SELECT @EXISTS = @Report_Id
 	 UPDATE REPORT_DEFINITIONS SET
 	  	 Class 	  	  	  	 = @Class,
 	  	 Priority 	  	  	 = @Priority,
 	  	 Report_Name 	  	  	 = @Report_Name,
 	  	 File_Name 	  	  	 = @File_Name,
 	  	 Security_Group_Id 	 = @Security_Group_Id, 	  	 
 	  	 AutoRefresh 	  	  	 = @AutoRefresh,
 	  	 TimeStamp 	  	  	 = GetDate(),
 	  	 Image_Ext 	  	  	 = @Image_Ext,
 	  	 Native_Ext 	  	  	 = @Native_Ext,
 	  	 OwnerId 	  	  	  	 = @OwnerId
 	 WHERE Report_Id = @Report_Id
  END
-- Update The ReportName Parameter
Exec spRS_AddReportDefParam @Exists, 'ReportName', @Report_Name
SELECT * FROM REPORT_DEFINITIONS WHERE REPORT_ID = @EXISTS

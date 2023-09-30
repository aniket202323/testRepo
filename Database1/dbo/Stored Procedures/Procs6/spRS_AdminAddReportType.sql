--------------------------------------------
-- This Stored Procedure should only be 
-- used by the report server administrator
--------------------------------------------
CREATE PROCEDURE dbo.spRS_AdminAddReportType
 	 @ReportTypeId  	  	 INT,
 	 @Version  	  	  	 INT,
 	 @Description  	  	 VARCHAR(255), 
 	 @TemplatePath  	  	 VARCHAR(255),
 	 @ClassName  	  	  	 VARCHAR(255),
 	 @NativeExt  	  	  	 VARCHAR(20),
 	 @ImageExt  	  	  	 VARCHAR(20),
 	 @DetailDesc  	  	 VARCHAR(255),
 	 @SPName  	  	  	 VARCHAR(255),
 	 @MinVersion 	  	  	 VARCHAR(10), 
    @TemplateFileName 	 VARCHAR(255),
 	 @TemplateDate 	  	 DATETIME,
 	 @Security_Group_Id 	 INT,
 	 @Send_Parameters  	 INT,
 	 @OwnerId 	  	  	 INT,
 	 @ForceRunMode 	  	 INT
 AS
----------------------------
-- Create A New Report Type
----------------------------
IF @ReportTypeId = 0
  BEGIN
 	 IF (@TemplateFileName Is Null) or (len(@TemplateFileName) = 0)
 	  	 BEGIN
 	  	  	 INSERT INTO Report_Types(Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, Detail_Desc, SPName, MinVersion, Template_File_Name, Date_Saved, Security_Group_Id, Send_Parameters, OwnerId, ForceRunMode)
 	  	  	 VALUES 	  	  	  	    (@Description, @TemplatePath, @ClassName, @NativeExt, @ImageExt, @Version, @DetailDesc, @SPName, @MinVersion, @TemplateFileName, @TemplateDate, @Security_Group_Id, @Send_Parameters, @OwnerId, @ForceRunMode)
 	  	     SELECT @ReportTypeId = Scope_Identity() 
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 INSERT INTO Report_Types(Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, Detail_Desc, SPName, MinVersion, Template_File_Name, Date_Saved, Security_Group_Id, Send_Parameters, OwnerId, ForceRunMode)
 	  	  	 VALUES 	  	  	  	    (@Description, @TemplatePath, @ClassName, @NativeExt, @ImageExt, @Version, @DetailDesc, @SPName, @MinVersion, @TemplateFileName, @TemplateDate, @Security_Group_Id, @Send_Parameters, @OwnerId, @ForceRunMode)
 	  	     SELECT @ReportTypeId = Scope_Identity() 
 	  	 END 	 
  END
-------------------------------
-- Update Existing Report Type
-------------------------------
ELSE
  BEGIN
 	 IF (@TemplateFileName Is Null) or (len(@TemplateFileName) = 0)
 	     BEGIN
 	  	  	 UPDATE  	 Report_Types
 	  	  	 SET 	  	 Description = @Description,
 	  	  	  	  	 Template_Path = @TemplatePath,
 	  	  	  	  	 Class_Name = @ClassName,
 	  	  	  	  	 Native_Ext = @NativeExt,
 	  	  	  	  	 Image_Ext = @ImageExt,
 	  	  	  	  	 Version = @Version,
 	  	  	  	  	 Detail_Desc = @DetailDesc,
 	  	  	  	  	 SPName = @SPName,
 	  	  	  	  	 MinVersion = @MinVersion, 
 	  	  	  	  	 Template_File_Name = NULL,
 	  	  	  	  	 Date_Saved = NULL,
 	  	  	  	  	 Security_Group_Id = @Security_Group_Id,
 	  	  	  	  	 Template_File = NULL,
 	  	  	  	  	 Send_Parameters = @Send_Parameters, 
 	  	  	  	  	 OwnerId = @OwnerId,
 	  	  	  	  	 ForceRunMode = @ForceRunMode
 	  	  	 WHERE 	 Report_Type_Id = @ReportTypeId
 	     END
 	 ELSE
 	     BEGIN
 	  	  	 UPDATE  	 Report_Types
 	  	  	 SET 	  	 Description = @Description,
 	  	  	  	  	 Template_Path = @TemplatePath,
 	  	  	  	  	 Class_Name = @ClassName,
 	  	  	  	  	 Native_Ext = @NativeExt,
 	  	  	  	  	 Image_Ext = @ImageExt,
 	  	  	  	  	 Version = @Version,
 	  	  	  	  	 Detail_Desc = @DetailDesc,
 	  	  	  	  	 SPName = @SPName,
 	  	  	  	  	 MinVersion = @MinVersion, 
 	  	  	  	  	 Template_File_Name = @TemplateFileName,
 	  	  	  	  	 Date_Saved = @TemplateDate,
 	  	  	  	  	 Security_Group_Id = @Security_Group_Id,
 	  	  	  	  	 Send_Parameters = @Send_Parameters,
 	  	  	  	  	 OwnerId = @OwnerId,
 	  	  	  	  	 ForceRunMode = @ForceRunMode
 	  	  	 WHERE 	 Report_Type_Id = @ReportTypeId
 	     END
  END
--------------------------
-- Return The Report Type
--------------------------
SELECT  	 Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, Detail_Desc, SPName, Report_Type_Id, Date_Saved, OwnerId, ForceRunMode
FROM  	 Report_Types 
WHERE 	 Report_Type_Id = @ReportTypeId

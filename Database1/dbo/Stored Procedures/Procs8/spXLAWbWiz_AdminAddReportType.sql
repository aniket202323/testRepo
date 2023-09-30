--------------------------------------------
-- This Stored Procedure should only be 
-- used by the report server administrator
--------------------------------------------
CREATE PROCEDURE dbo.spXLAWbWiz_AdminAddReportType
 	   @Report_Type_Id       Int
 	 , @Version              Int
 	 , @Description  	         Varchar(255) 
        , @Template_File_Name   Varchar(255)
 	 , @Template_Path        Varchar(255)
 	 , @Class_Name  	         Varchar(255)
 	 , @Native_Ext           Varchar(20)
 	 , @ImageExt             Varchar(20)
 	 , @Detail_Desc          Varchar(255)
 	 , @SPName               Varchar(255)
 	 , @MinVersion           Varchar(10)
        , @Date_Saved           DateTime
        , @Date_Tested_Locally  DateTime
 	 , @Date_Tested_Remotely DateTime
 	 , @Is_AddIn             Bit
 AS
----------------------------
-- Create A New Report Type
----------------------------
IF @Report_Type_Id = 0
  BEGIN
    INSERT INTO Report_Types(Description, Template_File_Name, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, Detail_Desc, SPName, MinVersion, Date_Saved, Date_Tested_Locally, Date_Tested_Remotely, Is_AddIn)
                      VALUES(@Description, @Template_File_Name, @Template_Path, @Class_Name, @Native_Ext, @ImageExt, @Version, @Detail_Desc, @SPName, @MinVersion, @Date_Saved, @Date_Tested_Locally, @Date_Tested_Remotely, @Is_AddIn)
    SELECT @Report_Type_Id = Scope_Identity() 
  END
ELSE -- Update Existing Report Type
  BEGIN
    UPDATE Report_Types
       SET Description          = @Description
         , Template_File_Name   = @Template_File_Name
         , Template_Path        = @Template_Path
         , Class_Name           = @Class_Name
         , Native_Ext           = @Native_Ext
         , Image_Ext            = @ImageExt
         , Version              = @Version
         , Detail_Desc          = @Detail_Desc
         , SPName               = @SPName
         , MinVersion           = @MinVersion
         , Date_Saved            = @Date_Saved
         , Date_Tested_Locally  = @Date_Tested_Locally  
         , Date_Tested_Remotely = @Date_Tested_Remotely  
         , Is_AddIn             = @Is_AddIn
    WHERE Report_Type_Id = @Report_Type_Id
  END
--EndIf
--------------------------
-- Return The Report Type
--------------------------
SELECT Description, Template_File_Name, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, MinVersion, Detail_Desc, SPName, Report_Type_Id
     , Date_Saved, Date_Tested_Locally, Date_Tested_Remotely, Is_AddIn
  FROM Report_Types 
 WHERE Report_Type_Id = @Report_Type_Id

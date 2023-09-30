CREATE PROCEDURE dbo.spRS_IEPutReportTypes
 	   @Report_Type_Id 	  	  INT 	  	  	  	  	 --Not used
 	 , @Description 	  	  	  VARCHAR(255) 	  	 --Our "Practical Key"
 	 , @Template_Path 	  	  VARCHAR(255)
 	 , @Class_Name 	  	  	  VARCHAR(255)
 	 , @Native_Ext 	  	  	  VARCHAR(20)
 	 , @Image_Ext 	  	  	  VARCHAR(20)
 	 , @Version 	  	  	  	  INT
 	 , @Detail_Desc 	  	  	  VARCHAR(255)
 	 , @MinVersion 	  	  	  VARCHAR(10)
 	 , @SPName 	  	  	  	  VARCHAR(255)
 	 , @Report_Type_Id_Target INT 	 OUTPUT
AS
/*  
 	 8-15-02 SPModified MSI/DS
 	 Provided support for 2 additional input parameters (MinVersion & SPName)
 	 For use with IMPORT of report packages
    MSI-MT 8-14-2000(Modified to include Constraint Check 1-9-2001)
*/
DECLARE @lStatus 	  	 int
DECLARE @lDescrExists 	 Bit
SELECT @lStatus = -9191 	  	 --Initialized
SELECT @Report_Type_Id_Target = -9191
if @Report_Type_Id = 0 OR @Report_Type_Id Is NULL
    BEGIN
 	  	 Select @lStatus = -2000
 	  	 goto END_OF_PROC
    END
/* Check For Existence of our "Practical Key"
   [dbo.Report_Types.Description must be unique. It has no other constraints]
*/
If EXISTS(SELECT RT.Report_Type_Id  FROM Report_Types RT  WHERE RT.Description = @Description)
SELECT @lDescrExists = 1 Else SELECT @lDescrExists = 0
--------------------------
-- Insert New Report Type
--------------------------
If @lDescrExists = 0 	  	  	  	 --No unique Description; do normal insert
    BEGIN
 	  	 INSERT INTO Report_Types
 	  	       (  Description,  Template_Path,  Class_Name,  Native_Ext,  Image_Ext,  Version,  Detail_Desc,  MinVersion,  SPName)
 	  	 Values( @Description, @Template_Path, @Class_Name, @Native_Ext, @Image_Ext, @Version, @Detail_Desc, @MinVersion, @SPName)
 	 
 	  	 If @@Error <> 0  
 	  	  	 Select @lStatus = @@Error 
 	  	 Else
 	  	  	 SELECT @lStatus = 20
 	 
 	  	 Select @Report_Type_Id_Target = Scope_Identity()
 	 
 	  	 If @@Error <> 0 
 	  	  	 Select @lStatus = @@Error
    END
--------------------------
-- Update Existing Type
--------------------------
Else If @lDescrExists = 1 	  	  	 --Yes Description exists; do update
    BEGIN
 	  	 --Get primaryKey from Target row
 	  	 SELECT  	 @Report_Type_Id_Target = RT.Report_Type_Id  
 	  	 FROM  	 Report_Types RT  
 	  	 WHERE  	 RT.Description = @Description
 	  	 
 	  	 UPDATE 	 Report_Types
 	  	 SET 	  	 Template_Path = @Template_Path,
 	  	  	  	 Class_Name = @Class_Name,
 	  	  	  	 Native_Ext = @Native_Ext,
 	  	  	  	 Image_Ext = @Image_Ext,
 	  	  	  	 Version = @Version,
 	  	  	  	 Detail_Desc = @Detail_Desc,
 	  	  	  	 MinVersion = @MinVersion,
 	  	  	  	 SPName = @SPName
 	  	 WHERE 	 Description = @Description
 	  	 
 	  	 If @@Error <> 0 
 	  	  	 Select @lStatus = @@Error 
 	  	 Else 
 	  	  	 SELECT @lStatus = 10
    END
END_OF_PROC:
Return (@lStatus)

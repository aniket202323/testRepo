CREATE PROCEDURE dbo.spRS_GetReportTypes
@ReportTypeId int = Null,
@Description varchar(255) = Null
AS
Declare @Exists int
Select @Exists = 0
If @ReportTypeId Is Null
  Begin
    If @Description Is Null
      Begin
        --Select * 
 	  	 Select Report_Type_Id, Version, Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Detail_Desc, SPName, MinVersion, Template_File_Name, Date_Saved, Date_Tested_Locally, Date_Tested_Remotely, Is_Addin, Security_Group_Id, Send_Parameters, OwnerId, ForceRunMode
        From Report_Types
      End
    Else
      Begin
        Select @Exists = Report_Type_Id
        From Report_Types
        Where Description = @Description
 	 return @Exists
      End
  End
Else
--  Select * 
  Select Report_Type_Id, Version, Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Detail_Desc, SPName, MinVersion, Template_File_Name, Date_Saved, Date_Tested_Locally, Date_Tested_Remotely, Is_Addin, Security_Group_Id, Send_Parameters, OwnerId, ForceRunMode
  From Report_Types
  Where Report_Type_Id = @ReportTypeId

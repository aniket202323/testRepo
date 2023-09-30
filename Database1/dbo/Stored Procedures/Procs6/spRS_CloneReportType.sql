CREATE PROCEDURE [dbo].[spRS_CloneReportType] 
@Report_Type_Id int,
@Description varchar(255)
AS
Declare @New_Report_Type_Id int
Declare @Exists int
Select @Exists = Report_Type_Id from report_types Where Description = @Description
If @Exists Is Not Null
  Begin
    Select -1 'New_Report_Type_Id'
    Return 0
  End
Insert Into Report_types(Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, Detail_Desc, SPName, MinVersion, Template_File_Name, Template_File, Date_Saved, Date_Tested_Locally, Date_Tested_Remotely, Is_Addin, Security_Group_Id, Send_Parameters, ForceRunMode)
Select @Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Version, Detail_Desc, SPName, MinVersion, Template_File_Name, Template_File, Date_Saved, Date_Tested_Locally, Date_Tested_Remotely, Is_Addin, Security_Group_Id, Send_Parameters, ForceRunMode
  From Report_Types 
  Where Report_Type_Id = @Report_Type_Id
  Select @New_Report_Type_id = Scope_Identity()
  Select @New_Report_Type_id 'New_Report_Type_Id'
Insert into Report_Type_Parameters(Report_Type_Id, RP_Id, Default_Value, optional)
Select @New_Report_Type_Id, RP_Id, Default_Value, optional
  From Report_Type_Parameters
  Where Report_type_Id = @Report_Type_Id
--Webpages
Insert into Report_Type_Webpages(Report_Type_Id, RWP_Id, Page_Order)
Select @New_Report_Type_Id, RWP_Id, Page_Order
  From Report_Type_Webpages
  Where Report_Type_Id = @Report_Type_Id
--Dependencies
Insert Into Report_Type_Dependencies(Report_Type_Id, RDT_Id, Value)
Select @New_Report_Type_Id, RDT_Id, Value
  From Report_Type_Dependencies
  Where Report_Type_Id = @Report_Type_Id

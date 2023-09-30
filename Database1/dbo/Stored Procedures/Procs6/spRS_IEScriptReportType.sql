Create Procedure [dbo].[spRS_IEScriptReportType]
 	 @Report_Type_Id int
AS
------------------------------------
-- Local Variables
------------------------------------
Declare @Description varchar(255)
Declare @MyId int
Create Table #t(
 	 Id int NOT NULL IDENTITY (1, 1),
 	 Data varchar(8000)
)
-- Report Type Description
Select @Description = Description From Report_Types Where Report_Type_Id = @Report_Type_Id
Insert Into #t(Data) Select 'Set NoCount On'
Insert Into #t(Data) Select 'Declare @New_Type_Id int'
Insert Into #t(Data) Select 'Declare @FileLocation varchar(255)'
Insert Into #t(Data) Select 'Declare @AdoConnectStr varchar(255)'
Insert Into #t(Data) Select 'Declare @WebLocation varchar(255)'
Insert Into #t(Data) Select 'Declare @ServerFileLocation varchar(255)'
Insert Into #t(Data) Select 'Select @FileLocation = Default_Value From Report_Parameters Where RP_Id = 35'
Insert Into #t(Data) Select 'Select @AdoConnectStr = Default_Value From Report_Parameters Where RP_Id = 36'
Insert Into #t(Data) Select 'Select @WebLocation = Default_Value From Report_Parameters Where RP_Id = 42'
Insert Into #t(Data) Select 'Select @ServerFileLocation = Default_Value From Report_Parameters Where RP_Id = 43'
---------------------------------------
-- Get Report Parameters
---------------------------------------
/*
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Verifying Required Parameters'
Insert Into #t(Data) Select '------------------------------------'
Declare ParameterCursor INSENSITIVE CURSOR
  For (
 	    Select RP_Id from report_type_Parameters where Report_Type_Id = @Report_Type_Id
      )
  For Read Only
  Open ParameterCursor  
BeginLoopParameters:
  Fetch Next From ParameterCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin 
--      select @MyId
 	   Insert Into #t(Data)
 	   exec spRS_IEScriptReportParameter @MyId
      Goto BeginLoopParameters
    End 
  Else 
    goto EndLoopParameters
EndLoopParameters:
Close ParameterCursor
Deallocate ParameterCursor
*/
---------------------------------------
-- Get Report Webpages
---------------------------------------
/*
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Verifying Required Web Pages'
Insert Into #t(Data) Select '------------------------------------'
Declare WebPageCursor INSENSITIVE CURSOR
  For (
 	    Select RWP_Id from report_type_WebPages where Report_Type_Id = @Report_Type_Id
      )
  For Read Only
  Open WebPageCursor  
BeginLoopWebPages:
  Fetch Next From WebPageCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin 
--      select @MyId
 	   Insert Into #t(Data)
 	   exec spRS_IEScriptReportWebPage @MyId
      Goto BeginLoopWebPages
    End 
  Else 
    goto EndLoopWebPages
EndLoopWebPages:
Close WebPageCursor
Deallocate WebPageCursor
*/
---------------------------------------
-- Insert/Update Report Type
---------------------------------------
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Insert/Update Report Type'
Insert Into #t(Data) Select '------------------------------------'
If @Report_Type_Id < 0
 	 Begin
 	  	 Insert Into #t(Data) Values('Select @New_Type_Id = ' + convert(varchar(5), @Report_Type_Id))
 	  	 Insert Into #t(Data) Values('Set Identity_Insert Report_Types On')
 	  	 Insert Into #t(Data)
 	  	 Select 'If (Select Count(Report_Type_Id) From Report_Types Where Report_Type_Id = ' + convert(varchar(3), Report_Type_Id) + ') = 0 ' +
 	  	 'BEGIN ' + 
 	  	 'Insert Into Report_Types (Report_Type_Id, Version, Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Detail_Desc, SPName, MinVersion, Security_Group_Id, Send_Parameters) Values(' +
 	  	  	 CONVERT(VARCHAR(5), @Report_Type_Id) + ', ' +
 	  	  	 CASE WHEN Version IS NULL THEN ' 1' ELSE CONVERT(VARCHAR(255), Version ) END + ',' +
 	  	  	 '''' + Description + '''' + ',' +
 	  	     '''' + Template_Path + '''' + ', ' + 
 	  	     '''' + Class_Name + '''' + ', ' + 
 	  	     '''' + Native_Ext + '''' + ', ' +
 	  	     '''' + Image_Ext + ''''  + ', ' +
 	  	  	 CASE WHEN Detail_Desc IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Detail_Desc + '''') END + ',' +
 	  	  	 CASE WHEN SPName IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + SPName + '''') END + ',' +
 	  	  	 CASE WHEN MinVersion IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + MinVersion + '''') END + ',' +
 	  	  	 CASE WHEN Security_Group_Id IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Security_Group_Id + '''') END + ',' +
 	  	  	 CASE WHEN Send_Parameters IS NULL THEN ' 0' ELSE CONVERT(VARCHAR(255), Send_Parameters ) END + 
 	  	     ') END ELSE BEGIN '  +
 	  	  	 'UPDATE Report_Types SET ' + 
 	  	  	 'VERSION = ' +  	  	  	 CASE WHEN Version IS NULL THEN ' 1' ELSE CONVERT(VARCHAR(255), Version ) END + ',' +
 	  	  	 'DESCRIPTION = ' +  	  	 '''' + Description + '''' + ',' +
 	  	  	 'TEMPLATE_PATH = ' +    '''' + Template_Path + '''' + ', ' + 
 	  	  	 'CLASS_NAME = ' +     	 '''' + Class_Name + '''' + ', ' + 
 	  	  	 'NATIVE_EXT = ' +     	 '''' + Native_Ext + '''' + ', ' +
 	  	  	 'IMAGE_EXT = ' +     	 '''' + Image_Ext + ''''  + ', ' +
 	  	  	 'DETAIL_DESC = ' +  	  	 CASE WHEN Detail_Desc IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Detail_Desc + '''') END + ',' +
 	  	  	 'SPNAME = ' +  	  	  	 CASE WHEN SPName IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + SPName + '''') END + ',' +
 	  	  	 'MINVERSION = ' +  	  	 CASE WHEN MinVersion IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + MinVersion + '''') END + ',' +
 	  	  	 'SECURITY_GROUP_ID = ' + CASE WHEN Security_Group_Id IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Security_Group_Id + '''') END + ',' +
 	  	  	 'SEND_PARAMETERS = ' +  	 CASE WHEN Send_Parameters IS NULL THEN ' 0' ELSE CONVERT(VARCHAR(255), Send_Parameters ) END + 
 	  	  	 ' WHERE Report_Type_Id = ' + CONVERT(VARCHAR(3), Report_Type_Id) +
 	  	  	 ' END '
 	  	     From Report_Types RT
 	  	  	 Where RT.Report_Type_Id = @Report_Type_Id
 	  	  	 Insert Into #t(Data) Values('Set Identity_Insert Report_Types Off')
 	 End
Else
 	 Begin
 	  	 Insert Into #t(Data)
 	  	 Select 'If (Select Count(Report_Type_Id) From Report_Types Where Description = ' + '''' + @Description + '''' + ') = 0 ' +
 	  	 'BEGIN ' + 
 	  	 'Insert Into Report_Types (Version, Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Detail_Desc, SPName, MinVersion, Security_Group_Id, Send_Parameters) Values(' +
 	  	  	 CASE WHEN Version IS NULL THEN ' 1' ELSE CONVERT(VARCHAR(255), Version ) END + ',' +
 	  	  	 '''' + Description + '''' + ',' +
 	  	     '''' + Template_Path + '''' + ', ' + 
 	  	     '''' + Class_Name + '''' + ', ' + 
 	  	     '''' + Native_Ext + '''' + ', ' +
 	  	     '''' + Image_Ext + ''''  + ', ' +
 	  	  	 CASE WHEN Detail_Desc IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Detail_Desc + '''') END + ',' +
 	  	  	 CASE WHEN SPName IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + SPName + '''') END + ',' +
 	  	  	 CASE WHEN MinVersion IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + MinVersion + '''') END + ',' +
 	  	  	 CASE WHEN Security_Group_Id IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Security_Group_Id + '''') END + ',' +
 	  	  	 CASE WHEN Send_Parameters IS NULL THEN ' 0' ELSE CONVERT(VARCHAR(255), Send_Parameters ) END + 
 	  	     ') ' + 
 	  	  	 ' Select @New_Type_Id = Scope_Identity() ' + 
 	  	  	 'END ELSE BEGIN '  +
 	  	  	 'UPDATE Report_Types SET ' + 
 	  	  	 'VERSION = ' +  	  	  	 CASE WHEN Version IS NULL THEN ' 1' ELSE CONVERT(VARCHAR(255), Version ) END + ',' +
 	  	  	 'DESCRIPTION = ' +  	  	 '''' + Description + '''' + ',' +
 	  	  	 'TEMPLATE_PATH = ' +    '''' + Template_Path + '''' + ', ' + 
 	  	  	 'CLASS_NAME = ' +     	 '''' + Class_Name + '''' + ', ' + 
 	  	  	 'NATIVE_EXT = ' +     	 '''' + Native_Ext + '''' + ', ' +
 	  	  	 'IMAGE_EXT = ' +     	 '''' + Image_Ext + ''''  + ', ' +
 	  	  	 'DETAIL_DESC = ' +  	  	 CASE WHEN Detail_Desc IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Detail_Desc + '''') END + ',' +
 	  	  	 'SPNAME = ' +  	  	  	 CASE WHEN SPName IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + SPName + '''') END + ',' +
 	  	  	 'MINVERSION = ' +  	  	 CASE WHEN MinVersion IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + MinVersion + '''') END + ',' +
 	  	  	 'SECURITY_GROUP_ID = ' + CASE WHEN Security_Group_Id IS NULL THEN ' NULL' ELSE CONVERT(VARCHAR(255), + '''' + Security_Group_Id + '''') END + ',' +
 	  	  	 'SEND_PARAMETERS = ' +  	 CASE WHEN Send_Parameters IS NULL THEN ' 0' ELSE CONVERT(VARCHAR(255), Send_Parameters ) END + 
 	  	  	 ' WHERE Description = ' + '''' + @Description + '''' + 
 	  	  	 ' Select @New_Type_Id = Report_Type_Id From Report_Types Where Description = ' + '''' + @Description + '''' +
 	  	  	 ' END '
 	  	     From Report_Types RT
 	  	  	 Where RT.Report_Type_Id = @Report_Type_Id
 	  	  	 --Insert Into #t(Data) Values('Select @New_Type_Id = Scope_Identity()')
 	 End
---------------------------------------
-- Add/Update Report Type Parameters
---------------------------------------
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Add/Update Report Type Parameters'
Insert Into #t(Data) Select '------------------------------------'
Declare @RP_Name varchar(50)
Declare @Optional Int
Declare @Default_Value varchar(7000)
Declare @SQL varchar(8000)
Insert Into #t(Data) Values('Declare @o int')
Declare RTPCursor INSENSITIVE CURSOR
  For (
 	  	 Select rp.rp_name, rtp.Optional, rtp.Default_Value 
 	  	 From report_type_parameters rtp
 	  	 Join report_parameters rp on rtp.rp_id = rp.rp_id
 	  	 Where rtp.report_type_id = @Report_Type_Id
      )
  For Read Only
  Open RTPCursor  
BeginLoopRTP:
  Fetch Next From RTPCursor Into @RP_Name, @Optional, @Default_Value
  If (@@Fetch_Status = 0)
    Begin 
 	   Select @SQL = 'Exec spRS_AddReportTypeParameter @New_Type_Id, ' + 
 	  	  	  	  	 '''' +  	 @RP_Name + '''' + ', ' +
 	  	  	  	  	 CASE WHEN @Default_Value IS NULL THEN ' NULL' ELSE '''' + @Default_Value + '''' END + ', ' +
 	  	  	  	  	 convert(varchar(2), @Optional)  + ', @o output'
 	  	   Insert Into #t(Data) Values(@SQL)
      Goto BeginLoopRTP
    End 
  Else 
    goto EndLoopRTP
EndLoopRTP:
Close RTPCursor
Deallocate RTPCursor
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Updating Report Type Default Values...'
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select 'Exec spRS_AddReportTypeParameter @New_Type_Id, ' + '''' + 'FileLocation' + '''' + ', @FileLocation, 0, @o output'
Insert Into #t(Data) Select 'Exec spRS_AddReportTypeParameter @New_Type_Id, ' + '''' + 'AdoConnectStr' + '''' + ', @AdoConnectStr, 0, @o output'
Insert Into #t(Data) Select 'Exec spRS_AddReportTypeParameter @New_Type_Id, ' + '''' + 'WebLocation' + '''' + ', @WebLocation, 0, @o output'
Insert Into #t(Data) Select 'Exec spRS_AddReportTypeParameter @New_Type_Id, ' + '''' + 'ServerFileLocation' + '''' + ', @ServerFileLocation, 0, @o output'
Insert Into #t(Data) Select 'Exec spRS_AddReportTypeParameter @New_Type_Id, ' + '''' + 'Owner' + '''' + ', ' + '''' + '''' + ', 0, @o output'
---------------------------------------
-- Add/Update Report Type Webpages
---------------------------------------
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Add/Update Report Type Webpages'
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Values('Delete From Report_Type_Webpages Where Report_Type_Id = @New_Type_Id')
Insert Into #t(Data) 
 	 Select 'Exec spRS_IEAddReportTypeWebPageByName @New_Type_Id, ' + '''' + Convert(VarChar(50), rwp.File_Name) + '''' + ', ' + Convert(varchar(5), rtw.Page_Order)
    From Report_Type_Webpages RTW
 	 Join Report_WebPages RWP on RTW.RWP_Id = RWP.RWP_Id
 	 Where Report_Type_Id = @Report_Type_Id
 	 Order By rtw.Page_Order
---------------------------------------
-- Add/Update Report Type Dependencies
---------------------------------------
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Add/Update Report Type Dependencies'
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Values('Delete From Report_Type_Dependencies Where Report_Type_Id = @New_Type_Id')
Insert Into #t(Data) 
Select 'Insert Into Report_Type_Dependencies(Report_Type_Id, RDT_Id, Value) Values(' +
 	 '@New_Type_Id , ' + 
 	 Convert(Varchar(5), RDT_Id) + ', ' + 
 	 '''' + Convert(Varchar(255), Value) + '''' + ')' 
 	 From Report_Type_Dependencies
 	 Where Report_Type_Id = @Report_Type_Id
--Check If This Is Version Stamped Before Install on target machine
Select Data From #t Order By Id
Drop Table #t

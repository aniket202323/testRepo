CREATE PROCEDURE dbo.spWALM_GetAllRSContent
@Id Int = Null,
@IdType Int = Null
AS
-------------------------
-- Temporary Links Table
-------------------------
CREATE TABLE #Temp_Table(
 	 [Id] Int,
 	 IdType Int,
 	 [Name] nvarchar(255),
 	 URL varchar(7000),
 	 IconName nvarchar(255)
)
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-------------------
-- Dashboard Links
-------------------
DECLARE @DashboardLink nvarchar(255)
DECLARE @WebServerName nvarchar(255)
Declare @RSAddress nvarchar(255)
declare @USEHttps nvarchar(255)
declare @protocol nvarchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
SELECT @WebServerName = Value FROM Site_Parameters WHERE Parm_Id = 27
SELECT @RSAddress = Value FROM Site_Parameters WHERE Parm_Id = 10
IF @RSAddress Is Not Null
  BEGIN
    SELECT @DashboardLink = @protocol + @WebServerName + '/ProficyDashboard/MSWebPart.aspx?' 
 	   Insert Into #Temp_Table
 	  	   Select Dashboard_Report_Id, 15, Dashboard_Report_Name, @DashboardLink + 'ReportId=' + CONVERT(nvarchar(10), Dashboard_Report_ID), 'rd_small_dash.gif'
   	  	 FROM dashboard_reports
 	    	 WHERE Dashboard_Report_Ad_Hoc_Flag = 0
   	 Insert Into #Temp_Table
 	    	 Select Dashboard_Template_Id, 16, Prompt_String, @DashboardLink + 'TemplateId=' + CONVERT(nvarchar(10), Dashboard_Template_ID), 'rt_small_dashboard.gif'
 	    	 From dashboard_Templates DT
 	    	 Join Language_Data LD on Convert(nvarchar(10), LD.Prompt_Number) = DT.Dashboard_Template_Name and LD.Language_ID = @LangId
 	    	 Where Prompt_String Is Not Null
  END
-- Report Types
Insert into #Temp_Table
 	 Select Report_Type_Id, 5, [Description],
         @protocol + @RSAddress + '/Viewer/RSFrontDoor.asp?ReportTypeId=' + convert(nvarchar(10), Report_Type_Id),
        Case
 	   	  	    	 When rt.Class_Name = 'Excel.Application' Then 'rt_small_excel.gif'
 	  	    	   	 When rt.Class_Name = 'Access.Application' Then 'rt_small_access.gif'
 	  	  	  	  	 When rt.Class_Name = 'Active Server Page' Then 'rt_small_asp.gif'
 	  	  	  	  	 When rt.Class_Name = 'Active Server Application' Then 'rt_small_aspx.gif' 	  	 
 	  	  	  	 End
  From Report_Types rt
--select * from report_types
-- Report Definitions
Insert into #Temp_Table
Select Report_Id, 7, Report_Name,
@protocol + @RSAddress + '/Viewer/RSFrontDoor.asp?ReportId=' + convert(nvarchar(10), Report_Id),
Case
 	 When rt.Class_Name = 'Excel.Application' Then 'rd_small_excel.gif'
 	 When rt.Class_Name = 'Access.Application' Then 'rd_small_access.gif'
 	 When rt.Class_Name = 'Active Server Page' Then 'rd_small_asp.gif'
 	 When rt.Class_Name = 'Active Server Application' Then 'rd_small_aspx.gif' 	  	  	  	 
End
From Report_Definitions rd
Join Report_Types rt On rd.Report_Type_Id = rt.Report_Type_Id
Select *
From #Temp_Table
Where (@Id Is Null Or [Id] = @Id)
And (@IdType Is Null Or IdType = @IdType)
Drop Table #Temp_Table

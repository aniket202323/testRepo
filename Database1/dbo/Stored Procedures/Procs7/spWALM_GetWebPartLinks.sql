CREATE PROCEDURE dbo.spWALM_GetWebPartLinks
@UserId Int = Null,
@Id Int = Null,
@IdType Int = Null,
@NameFilter nVarChar(1000) = Null
AS
If @NameFilter Is Not Null
 	 Set @NameFilter = '%' + @NameFilter + '%'
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
 	  	  	 And (@NameFilter Is Null Or @NameFilter = '' Or Dashboard_Report_Name Like @NameFilter)
 	  	  	 And (Dashboard_Report_Security_Group_Id Is Null Or Dashboard_Report_Security_Group_Id In (Select Group_Id FROM User_Security Where User_Id = @UserId))
   	 Insert Into #Temp_Table
 	    	 Select Dashboard_Template_Id, 16, Prompt_String, @DashboardLink + 'TemplateId=' + CONVERT(nvarchar(10), Dashboard_Template_ID), 'rt_small_dashboard.gif'
 	    	 From dashboard_Templates DT
 	    	 Join Language_Data LD on Convert(nvarchar(10), LD.Prompt_Number) = DT.Dashboard_Template_Name and LD.Language_ID = @LangId
 	    	 Where Prompt_String Is Not Null
 	  	  	 And (@NameFilter Is Null Or @NameFilter = '' Or Prompt_String Like @NameFilter)
  END
Select *
From #Temp_Table
Where (@Id Is Null Or [Id] = @Id)
And (@IdType Is Null Or IdType = @IdType)
Order By IconName, [Name]
Drop Table #Temp_Table

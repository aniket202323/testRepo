CREATE PROCEDURE dbo.spRS_AdminGetReportServerLinks
@Link_Id Int = Null,
@Lang_Id Int = 0 -- Default English
AS
--********************************************/
-------------------------
-- Temporary Links Table
-------------------------
Declare @Temp_Table TABLE(
 	 Link_Id int,
    Link_Type_Id int,
 	 Link_Name varchar(1000),
 	 URL varchar(5000)
)
-------------------
-- Dashboard Links
-------------------
DECLARE @DashboardLink VARCHAR(255)
DECLARE @RSValue VARCHAR(255)
declare @USEHttps VARCHAR(255)
declare @protocol varchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
SELECT @RSValue = Value FROM Site_Parameters WHERE Parm_Id = 27
IF @RSValue Is Not Null
  BEGIN
 	 SELECT @DashboardLink =  @protocol + @RSValue + '/ProficyDashboard/MSWebPart.aspx?' 
 	 -- Reports are type 3
 	 Insert Into @Temp_Table (Link_Id, Link_Type_Id, Link_Name, URL)
 	  	 Select -10000 + -Dashboard_Report_ID, 3, Dashboard_Report_Name, @DashboardLink + 'ReportId=' + CONVERT(VARCHAR(5), Dashboard_Report_ID)
 	  	 FROM dashboard_reports
 	  	 WHERE Dashboard_Report_Ad_Hoc_Flag = 0
 	 -- Templates are type 4
 	 Insert Into @Temp_Table (Link_Id, Link_Type_Id, Link_Name, URL)
 	  	 Select -20000 + -Dashboard_Template_ID, 4, isnull(prompt_string, Dashboard_Template_Name), @DashboardLink + 'TemplateId=' + CONVERT(VARCHAR(5), Dashboard_Template_ID)
 	  	 FROM Dashboard_Templates DT
  	    	  Left Join Language_Data LD on LD.Language_ID = @Lang_Id 
 	  	  	 and Convert(varchar(10), LD.Prompt_Number) = DT.Dashboard_Template_Name 
 	 
 	 Delete from @Temp_Table Where Link_Name = 'Logout' or Link_Name = 'Logout Button'
  END
Update O 
     Set O.Link_Name = P.Prompt_String
     From Language_Data p 
     Join @Temp_Table O on Convert(varchar(10), O.Link_Name) = P.Prompt_Number and IsNumeric(o.Link_Name) = 1 
 	  where p.language_Id=0
If @Link_Id Is Null
 	 -- Get All Links
 	 Insert Into @Temp_Table (Link_Id, Link_Type_Id, Link_Name, URL)
 	  	 Select Link_Id, Link_Type_Id, Link_Name, URL 
 	  	 From Report_Server_Links
 	  	 Where Link_Id < 0
Else
 	 -- Get One Link
 	 Insert Into @Temp_Table (Link_Id, Link_Type_Id, Link_Name, URL)
 	  	 Select Link_Id, Link_Type_Id, Link_Name, URL 
 	  	 From Report_Server_Links
 	  	 Where Link_Id = @Link_Id
----------------------------
-- Select Out Of Temp Table
----------------------------
Select distinct Link_Id, Link_Type_Id, Link_Name, URL 
From @Temp_Table

/*
exec spRS_AddReportTreeNode 1,15,'Performance Distribution test',5,NULL,NULL,'http://HC-VM2K8ENT/ProficyDashboard/MSWebPart.aspx?ReportId=115',@p8 output
*/
CREATE PROCEDURE dbo.spDBR_UpdateUserTree
@User_Id 	 int,
@Child_Node_Id  int,
@Report_Def_Id 	 int
 AS
Declare @Report_Tree_Template_Id     	 int
Declare @Parent_Node_Id  	  	 int
Declare @Node_Name 	  	  	 varchar(50)
Declare @New_Row 	  	  	 int
Declare @RtnVal 	  	  	  	 int
Declare @URL varchar(255)
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
SELECT @URL = @protocol + @RSValue + '/ProficyDashboard/MSWebPart.aspx?ReportId=' + CONVERT(VARCHAR(5), @Report_Def_Id)
-- Get the User Template Id
Select @Report_Tree_Template_Id = Report_Tree_Template_Id
  From Report_Tree_Users
  Where User_Id = @User_Id
-- Get the Parent Node Id from the child node
Select @Parent_Node_Id = Parent_Node_Id
  From Report_Tree_Nodes
  where Node_Id = @Child_Node_Id
-- Get the report definition
Select @Node_Name = Dashboard_Report_Name 
  from dashboard_reports
  where Dashboard_Report_id = @Report_Def_id and Dashboard_Report_Ad_Hoc_Flag=0
if @Node_Name is not null
begin
 	 -- Here we don't set the @Report_Def_id, just to be consistent with Report Server Administrator
 	 Exec @RtnVal = spRS_AddReportTreeNode @Report_Tree_Template_Id, 15, @Node_Name, @Parent_Node_Id, null ,null, @URL, @New_Row
 	 If @RtnVal = 1  --'success'
 	   Return (0)
 	 Else
 	   Return (1)
end 
else
 return (1)

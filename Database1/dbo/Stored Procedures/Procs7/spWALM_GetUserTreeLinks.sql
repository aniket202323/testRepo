CREATE PROCEDURE dbo.spWALM_GetUserTreeLinks
@UserId int = null,
@TreeId int = null,
@NameFilter nVarChar(1000) = Null
AS
DECLARE @TemplateId   INT
DECLARE @TemplateName nVarChar(50)
DECLARE @ServerName   nvarchar(255)
DECLARE @FrontDoorLink nvarchar(25)
declare @USEHttps nvarchar(255)
declare @protocol nvarchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
If @NameFilter Is Not Null
 	 Set @NameFilter = '%' + @NameFilter + '%'
------------------------------------
-- Get Base Server URL
------------------------------------
Select @ServerName = @protocol + Value + '/' From Site_Parameters where Parm_Id = 10
Select @FrontDoorLink = 'Viewer/RSFrontDoor.asp?'
-------------------------------
-- Get Report_Tree_Template_Id
-------------------------------
SELECT @TemplateId = Report_Tree_Template_Id 
FROM   Report_Tree_Users 
WHERE  [User_Id] = @UserId
-------------------------
-- Get The Template Name
-------------------------
SELECT @TemplateName = Report_Tree_Template_Name
FROM   Report_Tree_Templates rtt
WHERE  Report_Tree_Template_Id = @TemplateId
Create Table #Temp_Table(
 	 TreeId Int, --The id of a tree node
 	 [Id] int,
 	 IdType Int, -- determines the type of the Id column
 	 ParentId Int,
 	 [Name] nvarchar(50),
 	 URL varchar(7000), 
 	 IconName nvarchar(255),
 	 Report_Type_Id Int,
 	 Report_Def_Id Int
)
-------------------------
-- Get Report Tree Nodes
-------------------------
Insert Into #Temp_Table
select
 	 rtn.Node_Id 'TreeId',
 	 Case
 	  	 When rtn.Node_Id_Type In (9, 15, 16) Then rtn.Node_Id
 	  	 Else 	 Coalesce(rtn.Report_Type_Id, rtn.Report_Def_Id)
 	 End 'Id',
 	 rtn.Node_Id_Type,
 	 rtn.Parent_Node_Id 'ParentId',
 	 rtn.Node_Name 'Name',
 	 rtn.URL 'URL',
 	 Case 	 
 	  	 When rtn.Node_Id_Type = 1 then 'folder-close.gif'
 	  	 When rtn.Node_Id_Type = 2 then 'folder-close.gif'
 	  	 When rtn.Node_Id_Type = 3 then 'folder-open.gif'
 	  	 When rtn.Node_Id_Type = 4 then 'scheduled.gif'
 	  	 When rtn.Node_Id_Type = 5 then
 	  	  	 Case
 	  	  	  	 When rt.Class_Name = 'Excel.Application' Then 'rt_small_excel.gif'
 	  	  	  	 When rt.Class_Name = 'Access.Application' Then 'rt_small_access.gif'
 	  	  	  	 When rt.Class_Name = 'Active Server Page' Then 'rt_small_asp.gif'
 	  	  	  	 When rt.Class_Name = 'Active Server Application' Then 'rt_small_aspx.gif' 	  	  	  	 
 	  	  	 End
 	  	 -- Case 6 should not be used anymore
 	  	 When rtn.Node_Id_Type = 6 then 'rt_small_asp.gif'
 	  	 When rtn.Node_Id_Type = 7 then
 	  	  	 Case
 	  	  	  	 When rt.Class_Name = 'Excel.Application' Then 'rd_small_excel.gif'
 	  	  	  	 When rt.Class_Name = 'Access.Application' Then 'rd_small_access.gif'
 	  	  	  	 When rt.Class_Name = 'Active Server Page' Then 'rd_small_asp.gif'
 	  	  	  	 When rt.Class_Name = 'Active Server Application' Then 'rd_small_aspx.gif' 	  	  	  	 
 	  	  	 End
 	  	 When rtn.Node_Id_Type = 8 then 'newwindow_small.gif'
 	  	 When rtn.Node_Id_Type = 9 then 'samewindow_small.gif'
 	  	 When rtn.Node_Id_Type = 10 then 'rtprop.gif'
 	  	 When rtn.Node_Id_Type = 11 then 'remotecreate.gif'
 	  	 When rtn.Node_Id_Type = 12 then 'remotereport.gif'
 	  	 When rtn.Node_Id_Type = 13 then 'sme.gif'
 	  	 When rtn.Node_Id_Type = 14 then 'smserver.gif'
 	  	 When rtn.Node_Id_Type = 15 then 'rd_small_dash.gif'
 	  	 When rtn.Node_Id_Type = 16 then 'rt_small_dashboard.gif'
 	  	 When rtn.Node_Id_Type = 17 then 'rt_small_aspx.gif' 	 
 	 End 'IconImageName',
 	 Coalesce(rtn.Report_Type_Id, rd.Report_Type_Id),
 	 rtn.Report_def_Id
FROM Report_Tree_Nodes rtn
Left Join report_definitions rd on rtn.report_def_id = rd.report_id
Left Join Report_Types RT on (RTN.Report_Type_Id = RT.Report_Type_Id OR RT.Report_Type_Id = RD.Report_Type_Id)
Where (@TemplateId Is Null Or rtn.report_tree_template_id = @TemplateId)
And (@TreeId Is Null Or rtn.Node_Id = @TreeId)
And (rd.Security_Group_Id Is Null Or rd.Security_Group_Id In (Select Group_Id FROM User_Security Where User_Id = @UserId))
And (@NameFilter Is Null Or @NameFilter = '' Or rtn.Node_Name Like @NameFilter Or rtn.Node_Id_Type In (1,2,3))
Order By rtn.Node_Level asc, rtn.Node_Order asc
--Delete unused folders TODO
--Report types
Update #Temp_Table
Set URL = @ServerName + @FrontDoorLink + 'ReportTypeId=' + convert(nvarchar(10), [Id])
Where Report_Type_Id Is Not Null
--Report definitions
Update #Temp_Table
Set URL = @ServerName + @FrontDoorLink + 'ReportId=' + convert(nvarchar(10), [Id])
Where Report_Def_Id Is Not Null
Update #Temp_Table Set URL = Replace(URL, '../../', @ServerName)
Update #Temp_Table Set URL = Replace(URL, '../', @ServerName)
Select *
From #Temp_Table
Drop Table #Temp_Table

CREATE PROCEDURE dbo.spRS_GetUserTree
@UserId int
AS
--***********************************************/
DECLARE @TemplateId   INT
DECLARE @TemplateName VARCHAR(50)
DECLARE @SecurityGroupId int
Create Table #MyUserGroups(Group_Id int)
Insert Into #MyUserGroups(Group_Id)(SELECT Group_Id FROM User_Security Where User_Id = @UserId)
Insert Into #MyUserGroups(Group_Id)
(select Group_Id from  User_Role_Security urs
join User_Security us on urs.Role_User_Id=us.User_Id where urs.User_Id=@UserId)
------------------------------------
-- Get The Users Security Group Id
-- If the user does not belong to a group then put him in admin
------------------------------------
select @SecurityGroupId = Min(Group_Id )
from user_security 
Where User_Id = @UserId
If @SecurityGroupId Is Null
  Select @SecurityGroupId = 1
-------------------------------
-- Get Report_Tree_Template_Id
-------------------------------
SELECT @TemplateId = null
SELECT @TemplateId = Report_Tree_Template_Id 
FROM   Report_Tree_Users 
WHERE  User_Id = @UserId
-------------------------
-- Get The Template Name
-------------------------
SELECT @TemplateName = Report_Tree_Template_Name
FROM   Report_Tree_Templates
WHERE  Report_Tree_Template_Id = @TemplateId
Create Table #Temp_Table(
 	 Node_Id int,
 	 Report_Tree_Template_Id int,
 	 Node_Id_Type int,
 	 Parent_Node_Id int,
 	 Report_Def_Id int,
 	 Report_Type_Id int,
 	 Node_Order int,
 	 Node_Level int,
 	 Node_Name varchar(50),
 	 URL varchar(7000), 
 	 Report_Name varchar(255), 
 	 Type_Id int,
 	 Class_Name varchar(255),
 	 ForceRunMode tinyint,
 	 SendParameters tinyint,
 	 Detail_Desc varchar(255)
)
-------------------------
-- Get Report Tree Nodes
-------------------------
Insert Into #Temp_Table
select
 	 rtn.Node_Id,
 	 rtn.Report_Tree_Template_Id,
 	 rtn.Node_Id_Type,
 	 rtn.Parent_Node_Id,
 	 rtn.Report_Def_Id,
 	 rtn.Report_Type_Id,
 	 rtn.Node_Order,
 	 rtn.Node_Level,
 	 rtn.Node_Name,
 	 rtn.URL,
 	 rd.report_name, 
 	 rd.Report_Type_Id,
 	 rt.Class_Name,
 	 Case
 	  	 When RTN.ForceRunMode Is Null Then RT.ForceRunMode
 	  	 Else RTN.ForceRunMode
 	 End,
 	 Case 
 	  	 When RTN.SendParameters Is Null Then RT.Send_Parameters
 	  	 Else RTN.SendParameters
 	 End,
 	 CASE WHEN rd.report_name IS NULL THEN rt.Detail_Desc ELSE rd.report_name END
 	 --NULL --  For the time being placing NULL, this compramises NLS,need to look at it to have NLS support.
FROM     Report_Tree_Nodes rtn
Left     JOIN report_definitions rd on report_def_id = report_id
Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id OR RT.Report_Type_Id = RD.Report_Type_Id
Where    rtn.report_tree_template_id = @TemplateId
Order By rtn.Node_Level asc, rtn.Node_Order asc
------------------------------------------------------------------
-- Get Rid Of Nodes That Have Greater Security Than The User Does
------------------------------------------------------------------
Declare @MyNodeId int
Declare @MyReportTypeId int
Declare @MyReportDefId int
Declare @DeleteString varchar(7000)
Declare @MySecurityGroupId int
Select @DeleteString = 'Delete From #Temp_Table Where Node_Id In (0'
Declare MyCursor INSENSITIVE CURSOR
  For (
 	  	 Select Node_Id, Report_Type_Id, Report_Def_Id
 	  	 From #Temp_Table
      )
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @MyNodeId, @MyReportTypeId, @MyReportDefId
  If (@@Fetch_Status = 0)
    Begin
 	  	 ----------------------------
 	  	 -- Check Report Definitions
 	  	 ----------------------------
 	  	 If @MyReportDefId Is Not Null
 	  	  	 Begin
 	  	  	  	 Select @MySecurityGroupId = Security_Group_Id  from report_definitions Where Report_Id = @MyReportDefId
 	  	  	  	 If @MySecurityGroupId Is Not Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If @MySecurityGroupId Not In (Select Group_Id From #MyUserGroups)
 	  	  	  	  	  	  	  	 Select @DeleteString = @DeleteString + ',' + convert(varchar(5), @MyNodeId)
 	  	  	  	  	 End
 	  	  	 End
 	  	 ----------------------------
 	  	 -- Check Report Types
 	  	 ----------------------------
 	  	 If @MyReportTypeId Is Not Null
 	  	  	 Begin
 	  	  	  	 Select @MySecurityGroupId = Security_Group_Id  from report_Types Where Report_Type_Id = @MyReportTypeId
 	  	  	  	 If @MySecurityGroupId Is Not Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If @MySecurityGroupId Not In (Select Group_Id From #MyUserGroups)
 	  	  	  	  	  	  	 Select @DeleteString = @DeleteString + ',' + convert(varchar(5), @MyNodeId)
 	  	  	  	  	 End
 	  	  	 End
            Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd
myEnd:
Close MyCursor
Deallocate MyCursor
----------------------------------------------
-- Execute Delete String Against #Temp_Table
----------------------------------------------
Select @DeleteString = @DeleteString + ')'
EXEC(@DeleteString)
SELECT @TemplateName 'Template_Name', #Temp_Table.* From #Temp_Table order by Node_Level asc, Node_Order asc
Drop Table #Temp_Table
Drop Table #MyUserGroups

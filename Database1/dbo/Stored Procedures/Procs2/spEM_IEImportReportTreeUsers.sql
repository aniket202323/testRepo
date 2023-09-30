CREATE PROCEDURE dbo.spEM_IEImportReportTreeUsers
@Report_Tree_Template_Name 	 nvarchar(50),
@Username 	  	  	  	  	 nvarchar(50) = null,
@sUser_Rights 	  	  	  	 nVarChar(1) = null,
@sView_Setting 	  	  	  	 nVarChar(1) = null,
@sUserId 	  	  	  	  	 VarChar(5)
AS
--------------------------------------
-- Local Variables
--------------------------------------
Declare @UserId int, @UserToAdd int, @ReportTreeTemplateId Int, @User_Rights int, @View_Setting int
--------------------------------------
-- Clean Arguments 
--------------------------------------
Select @Report_Tree_Template_Name = LTrim(RTrim(@Report_Tree_Template_Name))
Select @Username = IsNull(RTrim(LTrim(@Username)), '')
Select @sUser_Rights = IsNull(RTrim(LTrim(@sUser_Rights)), '0')
Select @sView_Setting = IsNull(RTrim(LTrim(@sView_Setting)), '0')
--------------------------------------
-- Initialize Variables
--------------------------------------
Select @UserId = Convert(int, @sUserId)
Select @User_Rights = Convert(int, @sUser_Rights)
Select @View_Setting = Convert(int, @sView_Setting)
--------------------------------------
-- Find the username on Target System
--------------------------------------
Select @UserToAdd = User_Id From Users Where Username = @Username
If (@UserToAdd Is Null)
  Begin
 	 Select 'Failed - Username Not Found'
 	 Return(-100)
  End
--------------------------------------
-- Find or Create Template Tree
--------------------------------------
Print 'Searching For Tree Named: ' + @Report_Tree_Template_Name
select @ReportTreeTemplateId = Report_Tree_Template_Id 
from report_tree_templates 
where Report_Tree_Template_Name = @Report_Tree_Template_Name
If @ReportTreeTemplateId Is Null
  Begin
 	 Insert Into Report_Tree_Templates(Report_Tree_Template_Name)
 	 Values(@Report_Tree_Template_Name)
 	 Select @ReportTreeTemplateId = SCOPE_IDENTITY() 
 	 Print 'Created Tree With Id = ' + convert(varchar(5), @ReportTreeTemplateId)
  End
Else
  Begin
 	 Print 'Tree Found With Id = ' + convert(varchar(5), @ReportTreeTemplateId)
  End
Declare @Found int
Select @Found = Count(*) from report_tree_users
Where User_Id = @UserToAdd
If @Found > 0
  Begin
 	 Select 'Failed - Username Assigned To Different Tree'
 	 Return(-100)
  End
Insert into Report_Tree_Users(Report_Tree_Template_Id, User_Id, User_Rights, View_Setting)
Values(@ReportTreeTemplateId, @UserToAdd, @User_Rights, @View_Setting)

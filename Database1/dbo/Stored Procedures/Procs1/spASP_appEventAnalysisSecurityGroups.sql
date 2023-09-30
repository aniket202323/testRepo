create procedure [dbo].[spASP_appEventAnalysisSecurityGroups]
--declare 
@UserId int
AS
/***************************
-- For Testing
--***************************
Select @UserId = 1
--***************************/
Select Distinct Id = sg.Group_Id, Description = sg.Group_Desc 
  from user_security us
  Join security_groups sg on sg.group_id = us.group_id
  Where us.user_id = @UserId and
        us.access_level >= 4 

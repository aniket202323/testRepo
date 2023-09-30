
CREATE PROCEDURE dbo.spSecurity_GetAssignedGroupsMappedRole
@paramType    nVarChar(10) = null,				/*		param type						 */
@RoleId int  			  = null			   /*		role id							 */	


AS

 IF(@paramType =1)
    BEGIN

	SELECT distinct agd.group_id as groupId, p.scope, p.id, a.id as assignmentId,ard.role_id as roleId FROM security.Assignments a  
	left join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id 
	left join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
	left join [security].[Role_Details] rd on rd.role_id = ard.role_id 
	left join [security].[Permissions] p on p.id = rd.permission_id
	where  ard.role_id= @RoleId

	
end

IF(@paramType =2)
    BEGIN

	SELECT distinct agd.group_id as groupId, p.scope, p.id, a.id as assignmentId,ard.role_id as roleId FROM security.Assignments a  
	left join [security].[Assignment_Group_Details] agd on agd.assignment_id = a.id 
	left join [security].[Assignment_Role_Details] ard on ard.assignment_id = a.id 
	left join [security].[Role_Details] rd on rd.role_id = ard.role_id 
	left join [security].[Permissions] p on p.id = rd.permission_id
	where  ard.role_id <> @RoleId
	
end




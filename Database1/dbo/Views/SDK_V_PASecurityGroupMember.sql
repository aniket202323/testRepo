CREATE view SDK_V_PASecurityGroupMember
as
select
User_Security.Security_Id as Id,
Security_Groups.Group_Desc as SecurityGroup,
Users.Username as Username,
User_Security.Access_Level as AccessLevel,
User_Security.User_Id as UserId,
User_Security.Group_Id as SecurityGroupId
FROM user_security
 join users on user_security.user_id = Users.user_id
 join security_groups on user_security.group_id = security_groups.group_id

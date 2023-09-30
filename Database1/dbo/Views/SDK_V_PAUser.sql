CREATE view SDK_V_PAUser
as
select
Users.User_Id as Id,
Users.WindowsUserInfo as WindowsUserInfo,
Users.Username as Username,
Users.User_Desc as Description,
Users.System as SystemUser,
Users.Active as IsActive,
users.Is_Role as IsRole,
users.Mixed_Mode_Login as MixedModeLogin,
users.Role_Based_Security as RoleBasedSecurity,
users.SSOUserId as SSOUserId,
users.View_Id as ViewId
FROM Users

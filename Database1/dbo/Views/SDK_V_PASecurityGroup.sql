CREATE view SDK_V_PASecurityGroup
as
select
Security_Groups.Group_Id as Id,
Security_Groups.Group_Desc as SecurityGroup,
Security_Groups.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Security_Groups.External_Link as ExternalInfo
FROM Security_Groups
LEFT JOIN Comments Comments on Comments.Comment_Id=security_groups.Comment_Id

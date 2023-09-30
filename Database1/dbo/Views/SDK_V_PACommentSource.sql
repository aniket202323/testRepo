CREATE view SDK_V_PACommentSource
as
select
Comment_Source.CS_Id as Id,
Comment_Source.CS_Desc as CommentSource
FROM Comment_Source

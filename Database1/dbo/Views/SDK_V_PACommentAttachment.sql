CREATE view SDK_V_PACommentAttachment
as
select
comment_attachments.Att_Id as Id,
comment_attachments.Comment_Id as CommentId,
comment_attachments.Att_FileName as AttachFileName,
comment_attachments.Modified_on as ModifiedOn,
comment_attachments.Mime_Type as MIMEType,
comment_attachments.File_Content as FileContent
FROM comment_attachments

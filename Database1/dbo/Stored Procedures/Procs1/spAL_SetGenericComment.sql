Create Procedure dbo.spAL_SetGenericComment
@Id int,
@Comment nvarchar(255)
AS
update comments set comment = @comment 
  where comment_id = @Id

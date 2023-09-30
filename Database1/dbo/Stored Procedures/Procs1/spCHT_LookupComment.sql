Create Procedure dbo.spCHT_LookupComment
  @id int
AS
 declare @Comment nvarchar(255)
 SELECT comment
    FROM comments
    WHERE comment_id =  @id
/*
Create Procedure dbo.spCHT_LookupComment
  @id int
AS
 declare @Comment nvarchar(255)
 SELECT @comment = convert(nvarchar(255),comment)
    FROM comments
    WHERE comment_id =7  -- @id
 if @comment is null 
       select  ' '
 else
      select @comment
*/

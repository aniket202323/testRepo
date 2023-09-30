Create Procedure dbo.spAL_LookupComment
  @id int,
  @comment nvarchar(255) OUTPUT 
AS
 SELECT @comment = convert(nvarchar(255),comment)
    FROM comments
    WHERE comment_id = @id
 if @comment is null 
   begin
      select @comment = ' '
   end
  return(100)

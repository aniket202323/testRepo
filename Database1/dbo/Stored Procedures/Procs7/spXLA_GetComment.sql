CREATE PROCEDURE dbo.spXLA_GetComment
@StartCommentId int,
@ChainedComment varchar(4000) output
 AS
declare @CommentData table (commentorder datetime, comment varchar(4000))
declare @TopOfChainId int
declare @Sep varchar(10)
set @Sep = '~'
set @ChainedComment = null
select @TopOfChainId = TopOfChain_Id from Comments where Comment_Id = @StartCommentId
if (@TopOfChainId is null)
  begin
    insert into @CommentData (commentorder, comment)
    select Coalesce(Entry_On, Modified_On), Convert(varchar(4000), Coalesce(Comment_Text,Comment))
      from Comments
      where Comment_Id = @StartCommentId
  end
else
  begin
    insert into @CommentData (commentorder, comment)
    select Coalesce(Entry_On, Modified_On), Convert(varchar(4000), Coalesce(Comment_Text,Comment))
      from Comments
      where TopOfChain_Id = @TopOfChainId
  end
select @ChainedComment = Coalesce(@ChainedComment + @Sep, '') + dbo.spXLA_fnParseComment(Comment)
  from @CommentData
 	 order by commentorder desc

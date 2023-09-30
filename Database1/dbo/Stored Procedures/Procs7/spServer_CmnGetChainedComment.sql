CREATE PROCEDURE dbo.spServer_CmnGetChainedComment
@StartCommentId int,
@ChainedComment nVarChar(4000) output
 AS
declare @CommentData table (commentorder datetime, comment nVarChar(4000))
declare @TopOfChainId int
declare @Sep nVarChar(10)
set @Sep = '~'
set @ChainedComment = null
select @TopOfChainId = TopOfChain_Id from Comments where Comment_Id = @StartCommentId
if (@TopOfChainId is null)
  begin
    insert into @CommentData (commentorder, comment)
    select Coalesce(Entry_On, Modified_On), Convert(nVarChar(4000), Coalesce(Comment_Text,Comment))
      from Comments
      where Comment_Id = @StartCommentId
  end
else
  begin
    insert into @CommentData (commentorder, comment)
    select Coalesce(Entry_On, Modified_On), Convert(nVarChar(4000), Coalesce(Comment_Text,Comment))
      from Comments
      where TopOfChain_Id = @TopOfChainId
  end
select @ChainedComment = Coalesce(@ChainedComment + @Sep, '') + dbo.fnServer_CmnParseComment(Comment)
  from @CommentData
 	 order by commentorder desc

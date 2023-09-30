Create Procedure dbo.spRSQ_RemoveQuery 
@QueryType int,
@PUId int,
@QueryName nvarchar(255)
AS
Declare @Id int
Declare @Comment int
Select @Id = NULL
Select @Id = Query_Id, @Comment = Comment_Id 
  From Saved_Queries
  Where Query_Type = @QueryType and
        PU_Id = @PUId and
        Query_Name = @QueryName
If @Id Is Not Null
  Begin
    If @Comment Is Not Null
      Update Comments Set ShouldDelete = 1, Comment = '', Comment_Text = '' Where Comment_Id = @Comment
    Delete From Saved_Queries Where Query_Id = @Id
  End

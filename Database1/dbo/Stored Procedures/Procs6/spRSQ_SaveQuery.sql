Create Procedure dbo.spRSQ_SaveQuery 
@QueryType int,
@PUId int,
@QueryName nvarchar(255),
@User_Id int,
@Comment_Id int,
@QueryString varchar(5000)
AS
Declare @Id int,
        @ModifiedTime datetime
Select @Id = NULL
Select @Id = Query_Id 
  From Saved_Queries
  Where Query_Type = @QueryType and
        PU_Id = @PUId and
        Query_Name = @QueryName
Select @ModifiedTime = dbo.fnServer_CmnGetDate(getutcdate())
If @Id Is Null
  Insert Into Saved_Queries(Query_Type, PU_Id, Query_Name, TimeStamp, User_Id, Comment_Id, Query_String)
    Values (@QueryType, @PUId, @QueryName, @ModifiedTime, @User_Id, @Comment_Id, @QueryString) 
Else
  Update Saved_Queries
    Set Query_Type = @QueryType,
        PU_Id = @PUId, 
        Query_Name = @QueryName,
        TimeStamp = @ModifiedTime,
        User_Id = @User_Id, 
        Comment_Id = @Comment_Id,
        Query_String = @QueryString  
  Where Query_Id = @Id

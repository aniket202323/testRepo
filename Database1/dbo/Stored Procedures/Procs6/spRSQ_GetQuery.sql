Create Procedure dbo.spRSQ_GetQuery 
@QueryType int,
@PUId int,
@QueryName nvarchar(255),
@QueryString varchar(5000) OUTPUT
AS
Declare @Id int
Declare @Query varchar(5000)
Select @Id = NULL
Select @Id = Query_Id, @Query = Query_String 
  From Saved_Queries
  Where Query_Type = @QueryType and
        PU_Id = @PUId and
        Query_Name = @QueryName
If @Id Is Not Null
  Select @QueryString = @Query
Else
  Select @QueryString = null

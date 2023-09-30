Create Procedure dbo.spRSQ_CheckQuery 
@QueryType int,
@PUId int,
@QueryName nvarchar(255),
@Valid int OUTPUT
AS
Declare @Id int
Select @Id = NULL
Select @Id = Query_Id 
  From Saved_Queries
  Where Query_Type = @QueryType and
        PU_Id = @PUId and
        Query_Name = @QueryName
If @Id Is Null
  Select @Valid = 1
Else
  Select @Valid = 0 

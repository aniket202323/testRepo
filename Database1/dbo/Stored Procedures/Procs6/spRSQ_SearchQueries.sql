Create Procedure dbo.spRSQ_SearchQueries 
@QueryType int,
@PUId int,
@QueryName nvarchar(255)
AS
If @QueryName Is Not Null
  Select sq.*, u.Username, pu.Pu_Desc From Saved_Queries sq
    Join Prod_Units pu On pu.PU_Id = sq.PU_Id
    Join Users u on u.User_Id = sq.User_Id 
    Where sq.PU_Id = @PUId and
          Query_Type = @QueryType and
          Query_Name Like '%' + ltrim(rtrim(@QueryName)) + '%'
  Order By Query_Name, TimeStamp
Else
  Select sq.*, u.Username, pu.Pu_Desc From Saved_Queries sq
    Join Prod_Units pu On pu.PU_Id = sq.PU_Id
    Join Users u on u.User_Id = sq.User_Id 
    Where sq.PU_Id = @PUId and
          Query_Type = @QueryType
  Order By Query_Name, TimeStamp

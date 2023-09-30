Create Procedure dbo.spXLAGetSpecifications
@ID integer, 
@Desc varchar(50), 
@qtype integer = 0,
@SearchString varchar(50) = NULL
AS
  if @Desc Is Not Null
    select * from specifications where spec_desc = @Desc
  else
    if @qtype = 0
      if @SearchString Is Null
        select spec_id, spec_desc from specifications where prop_id = @ID order by spec_desc
      else
        select spec_id, spec_desc from specifications where prop_id = @ID and spec_desc like '%'  + ltrim(rtrim(@SearchString)) + '%' order by spec_desc
    else if @qtype = 1
      select * from specifications WITH(index(PK___6__12)) where spec_id = @ID

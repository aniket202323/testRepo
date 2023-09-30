Create Procedure dbo.spGBAGetSpecifications @ID integer, @Desc nVarChar(50), @qtype integer = 0
 AS
  if @Desc Is Not Null
    select * from specifications where spec_desc = @Desc
  else
    if @qtype = 0
      select spec_id, spec_desc from specifications where prop_id = @ID order by spec_desc
    else if @qtype = 1
      select * from specifications WITH (index(PK___6__12)) where spec_id = @ID 
 	  	 order by spec_desc

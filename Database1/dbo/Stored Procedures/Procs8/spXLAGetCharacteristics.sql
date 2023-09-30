Create Procedure dbo.spXLAGetCharacteristics
@ID integer = 0,
@SearchString varchar(50) = NULL
AS 
if @SearchString Is Null 
  If @ID = 0
    Select C.*, PP.prop_desc from characteristics C 
      join product_properties PP on C.prop_id = PP.prop_id
      order by c.char_desc 
  else
    Select C.*, PP.prop_desc from characteristics C 
      join product_properties PP on C.prop_id = PP.prop_id
      where C.prop_id = @ID
      order by char_desc
else
  If @ID = 0
    Select C.*, PP.prop_desc from characteristics C 
      join product_properties PP on C.prop_id = PP.prop_id
      where char_desc like '%' + ltrim(rtrim(@SearchString)) + '%'
      order by c.char_desc 
  else
    Select C.*, PP.prop_desc from characteristics C 
      join product_properties PP on C.prop_id = PP.prop_id
      where C.prop_id = @ID and
            char_desc like '%' + ltrim(rtrim(@SearchString)) + '%'
      order by char_desc

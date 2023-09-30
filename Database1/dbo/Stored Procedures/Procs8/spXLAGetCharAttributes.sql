Create Procedure dbo.spXLAGetCharAttributes
@ID integer = 0
AS 
  SELECT  C.*, PP.prop_desc 
    FROM  characteristics C,  product_properties PP
   WHERE  C.prop_id = PP.prop_id 	 
     AND  C.char_id = @ID

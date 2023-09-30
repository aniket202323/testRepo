Create Procedure dbo.spXLAGetProperties
@SearchString varchar(50) = NULL 
AS 
  If @SearchString Is Null
    Select * From Product_Properties order by prop_desc
  Else
    Select * From Product_Properties where prop_desc like '%' +ltrim(rtrim(@SearchString)) + '%' order by prop_desc

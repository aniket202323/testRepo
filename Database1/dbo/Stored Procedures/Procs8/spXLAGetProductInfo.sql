Create Procedure dbo.spXLAGetProductInfo
@ProdID int,
@ProdCode varchar(50),  
@SearchString varchar(50) = NULL
AS
if @ProdCode is Not null 
  select * from products WITH (index(Products_By_Code)) where prod_code = @ProdCode
else if @ProdID is Not null 
  select * from products WITH (index(PK___7__12)) where prod_id = @ProdId 
else
  begin
    If @SearchString Is NULL    
      select * from products where prod_id <> 1 order by prod_code
    Else
      select * from products where prod_id <> 1 and prod_code like '%' + @SearchString + '%' order by prod_code
  end

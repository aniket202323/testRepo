Create Procedure dbo.spGBO_GetGradeInfo 
  @ProdID int     AS
  Select * From Products 
    Where Prod_Id = @ProdID

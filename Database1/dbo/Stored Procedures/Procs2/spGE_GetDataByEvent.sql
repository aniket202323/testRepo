CREATE PROCEDURE dbo.spGE_GetDataByEvent
  @Id int,
  @Type int,
  @Results nvarchar(100) Output
  AS
If @Type = 1  -- ProdCode 
  Select @Results = Prod_Code
    From Products 
    Where Prod_Id = @Id
Else If @Type = 2  -- OrderNumb
  Select @Results =  Coalesce(co.Plant_Order_Number,'<na>')
     	  	 From Customer_Order_Line_Items col
                Left Join Customer_Orders co on col.Order_Id = co.Order_Id
                Where col.Order_Line_Id =  @Id

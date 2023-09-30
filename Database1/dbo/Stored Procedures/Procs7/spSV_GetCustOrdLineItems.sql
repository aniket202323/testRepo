Create Procedure [dbo].[spSV_GetCustOrdLineItems]
@PP_Id int,
@All bit
AS
if @All = 0
  Select Distinct co.Plant_Order_Number, c.Customer_Code, p.Prod_Code,
       Dimension_X = Round(col.Dimension_X, 1), Dimension_Y = Round(col.Dimension_Y, 1), Dimension_Z = Round(col.Dimension_Z, 1), 
       Dimension_A = Round(col.Dimension_A, 1), col.Order_Line_Id
  From Production_Plan pp
  Join Production_Setup ps on ps.PP_Id = pp.PP_Id
  Left outer Join Production_Setup_Detail psd on psd.PP_Setup_id = ps.PP_Setup_Id 
  Join Customer_Order_Line_Items col on col.Order_Line_Id = psd.Order_Line_Id
  Join Products p on p.Prod_Id = col.Prod_id
  Join Customer_Orders co on co.Order_Id = col.Order_Id
  Join Customer c on c.Customer_ID = co.Customer_Id
  Where pp.PP_Id = @PP_Id
  And col.Prod_Id = psd.Prod_id
  Order By co.Plant_Order_Number, c.Customer_Code, p.Prod_Code
else
  Select Distinct co.Plant_Order_Number, c.Customer_Code, p.Prod_Code,
       Dimension_X = Round(col.Dimension_X, 1), Dimension_Y = Round(col.Dimension_Y, 1), Dimension_Z = Round(col.Dimension_Z, 1), 
       Dimension_A = Round(col.Dimension_A, 1), col.Order_Line_Id
  From Production_Plan pp
  Join Production_Setup ps on ps.PP_Id = pp.PP_Id
  Left outer Join Production_Setup_Detail psd on psd.PP_Setup_id = ps.PP_Setup_Id 
  Join Customer_Order_Line_Items col on col.Prod_Id = psd.Prod_Id
  Join Products p on p.Prod_Id = col.Prod_id
  Join Customer_Orders co on co.Order_Id = col.Order_Id
  Join Customer c on c.Customer_ID = co.Customer_Id
  Where pp.PP_Id = @PP_Id
  Order By co.Plant_Order_Number, c.Customer_Code, p.Prod_Code

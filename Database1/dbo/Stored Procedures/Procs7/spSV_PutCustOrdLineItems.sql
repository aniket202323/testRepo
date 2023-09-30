Create Procedure [dbo].[spSV_PutCustOrdLineItems]
@PP_Setup_Detail_Id int,
@Order_Line_Id int
AS
Update Production_Setup_Detail set Production_Setup_Detail.Order_Line_Id = @Order_Line_Id, Production_Setup_Detail.Target_Dimension_X = col.Dimension_X, 
  Production_Setup_Detail.Target_Dimension_Y = col.Dimension_Y, Production_Setup_Detail.Target_Dimension_Z = col.Dimension_Z, Production_Setup_Detail.Target_Dimension_A = col.Dimension_A
  From Production_Setup_Detail
  Join Customer_Order_Line_Items col on col.Order_Line_Id = @Order_Line_Id
  Where Production_Setup_Detail.PP_Setup_Detail_Id = @PP_Setup_Detail_Id
--Update Production_Setup_Detail set Order_Line_Id = @Order_Line_Id
--  Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id

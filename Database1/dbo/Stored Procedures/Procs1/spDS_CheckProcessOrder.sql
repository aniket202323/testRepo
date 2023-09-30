Create Procedure dbo.spDS_CheckProcessOrder
 @PPId int,
 @EventDetailId int,
 @ProdId int
AS
  If (@EventDetailId = 0)
    Begin
      Select Distinct CO.Order_Id, CO.Customer_Order_Number, OL.Line_Item_Number, OL.Order_Line_Id, OL.Ordered_Quantity, OL.Complete_Date,
             OL.Dimension_X, OL.Dimension_Y, OL.Dimension_Z, OL.Dimension_A, P.Prod_Code, PSD.Order_Line_Id, PSD.PP_Setup_Detail_Id,
             C.Customer_Name
       From Production_Setup_Detail PSD
       Join Production_Setup PS on PS.PP_Setup_Id = PSD.PP_Setup_Id
       Join Production_Plan PP on PP.PP_Id = PS.PP_Id
       Join Customer_Order_Line_Items OL on OL.Order_Line_Id = PSD.Order_Line_Id and OL.Prod_Id = @ProdId
       Join Customer_Orders CO on CO.Order_Id = OL.Order_Id
       Join Customer C on C.Customer_Id = CO.Customer_Id
       Join Products P on P.Prod_Id = OL.Prod_Id
        Where PP.PP_Id = @PPId
          Order by PSD.Order_Line_Id
    End
  Else
    Begin
      Select Distinct CO.Order_Id, CO.Customer_Order_Number, OL.Line_Item_Number, OL.Order_Line_Id, OL.Ordered_Quantity, OL.Complete_Date,
             OL.Dimension_X, OL.Dimension_Y, OL.Dimension_Z, OL.Dimension_A, P.Prod_Code, PSD.Order_Line_Id, PSD.PP_Setup_Detail_Id,
             C.Customer_Name
       From Production_Setup_Detail PSD
       Join Production_Setup PS on PS.PP_Setup_Id = PSD.PP_Setup_Id
       Join Production_Plan PP on PP.PP_Id = PS.PP_Id
       Join Customer_Order_Line_Items OL on OL.Order_Line_Id = PSD.Order_Line_Id and OL.Prod_Id = @ProdId
       Join Customer_Orders CO on CO.Order_Id = OL.Order_Id
       Join Customer C on C.Customer_Id = CO.Customer_Id
       Join Products P on P.Prod_Id = OL.Prod_Id
--       Join Event_Details ED on ED.Final_Dimension_X = OL.Dimension_X and ED.Final_Dimension_Y = OL.Dimension_Y and
--                                ED.Final_Dimension_Z = OL.Dimension_Z and ED.Final_Dimension_A = OL.Dimension_A
        Where PP.PP_Id = @PPId
          Order by PSD.Order_Line_Id
    End

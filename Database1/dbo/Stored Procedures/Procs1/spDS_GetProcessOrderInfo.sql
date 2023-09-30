Create Procedure dbo.spDS_GetProcessOrderInfo
 @PPSetupDetailId int
AS
      Select Distinct PP.Forecast_Start_Date, PP.Forecast_End_Date, PP.Forecast_Quantity, 
                      OL.Dimension_X, OL.Dimension_Y, OL.Dimension_Z, OL.Dimension_A, 
                      P.Prod_Code, OL.Order_Line_Id, OL.Order_Id
       From Production_Setup_Detail PSD
       Join Production_Setup PS on PS.PP_Setup_Id = PSD.PP_Setup_Id
       Join Production_Plan PP on PP.PP_Id = PS.PP_Id
       Join Customer_Order_Line_Items OL on OL.Order_Line_Id = PSD.Order_Line_Id
       Join Customer_Orders CO on CO.Order_Id = OL.Order_Id
       Join Products P on P.Prod_Id = PP.Prod_Id
        Where PSD.PP_Setup_Detail_Id = @PPSetupDetailId

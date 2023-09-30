Create Procedure dbo.spDS_RefreshDetailData
@ProcessOrderId int,
@PatternId int,
@ElementId int,
@OrderLineId int,
@RefreshType int
AS
--------------------------------------------------------
-- Process order information
--------------------------------------------------------
 If (@RefreshType = 0)
    Begin
       Select Process_Order, Forecast_Start_Date, Forecast_End_Date, Forecast_Quantity
         From Production_Plan
          Where PP_Id = @ProcessOrderId
    End
--------------------------------------------------------
-- Pattern information
--------------------------------------------------------
 If (@RefreshType = 1)
    Begin
       Select PS.Pattern_Code, PS.Forecast_Quantity as Setup_Forecast_Quantity, PPS.PP_Status_Desc
         From Production_Setup PS
           Join Production_Plan_Statuses PPS on PS.PP_Status_id = PPS.PP_Status_Id
          Where PP_Setup_Id = @PatternId
    End
--------------------------------------------------------
-- Element information
--------------------------------------------------------
 If (@RefreshType = 2)
    Begin
       Select PS.Element_Number, PPS.PP_Status_Desc as Element_Status
         From Production_Setup_Detail PS
           Join Production_Plan_Statuses PPS on PS.Element_Status = PPS.PP_Status_Id
          Where PS.PP_Setup_Detail_Id = @ElementId
    End
--------------------------------------------------------
-- Customer Order and shipping information
--------------------------------------------------------
 If (@RefreshType = 2 or @RefreshType = 3)
    Begin
       Select OD.Plant_Order_Number, OD.Forecast_Mfg_Date, OD.Forecast_Ship_Date, OD.Actual_Ship_Date, OD.Actual_Mfg_Date,
              PR3.Prod_Code as Ordered_Product, CU.Customer_Code, CU.Customer_Name, OD.Customer_Order_Number as Customer_Order_Number,
              OD.Order_Type, OD.Order_Status, OI.Complete_Date, OI.Ordered_Quantity, OI.Line_Item_Number
         From Customer_Order_Line_Items OI
           Left Outer Join Customer_Orders OD on OI.Order_Id = OD.Order_Id
           Left Outer Join Products PR3 on OI.Prod_Id = PR3.Prod_Id
           Left Outer Join Customer CU on OD.Customer_Id = CU.Customer_Id
          Where OI.Order_Line_Id = @OrderLineId
    End

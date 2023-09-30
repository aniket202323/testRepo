/* spDS_GetEventDetailData 2248023 */
Create Procedure dbo.spDS_GetEventDetailData
@EventId int
AS
 Declare  @EventSubTypeId int,
          @PUId int,
          @PP_Id int,
          @PP_Setup_Detail_Id int,
          @Has_Production_Plans int,
          @ProcessOrder nVarChar(100),
 	  	   @DetailId 	  	 Int
 Select @EventSubTypeId = NULL
 Select @PUId = NULL
 Select @PP_Id = NULL
 Select @PP_Setup_Detail_Id = NULL
 Select @Has_Production_Plans = 1
---------------------------------------------------------
-- Get Event info
--------------------------------------------------------
 Select @PUId = E.PU_Id, @EventSubTypeId = E.Event_SubType_Id, @PP_Id = ED.PP_Id, @PP_Setup_Detail_Id = ED.PP_Setup_Detail_Id
  From Events E
    Left Outer Join Event_Details ED on ED.Event_Id = E.Event_Id
   Where E.Event_Id= @EventId
---------------------------------------------------------
-- Determine if ANY rows in Production Plans table 
Select  @ProcessOrder = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'n/a'), @PP_Id = Coalesce(@PP_Id, ppp.PP_Id, ppp2.PP_Id)
   From Events e
   Left Outer Join Event_Details ed on ed.Event_Id = e.Event_id
   Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
   Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
   Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id       
  where e.event_id = @EventId
--If @ProcessOrder = 'n/a' Select @Has_Production_Plans = 0
--------------------------------------------------------
----------------------------------------------------------
-- Get the single Event SubType for the PUId if it could not be found on the ProductionEvent record
----------------------------------------------------------
 If(@EventSubTypeId Is Null)
  Select @EventSubTypeId = Min(ES.EVent_SubType_Id)
   From Event_SubTypes ES Inner Join Event_Configuration EC On ES.Event_SubType_Id = EC.Event_SubType_Id 
    Where ES.ET_Id = 1
     And EC.PU_Id = @PUId
--------------------------------------------------------
-- Details tab - all Event_Details columns
--------------------------------------------------------
  Select ED.Alternate_Event_Num, ED.Comment_Id, ED.Initial_Dimension_X, ED.Initial_Dimension_Y, ED.Initial_Dimension_Z,
         ED.Initial_Dimension_A, ED.Orientation_X, ED.Orientation_Y, ED.Orientation_Z, ED.Final_Dimension_X, ED.Final_Dimension_Y, 
         ED.Final_Dimension_Z, ED.Final_Dimension_A, ED.Shipment_Item_Id, ES.Dimension_X_Name as DimensionXName, ES.Dimension_Y_Name as DimensionYName, 
         ES.Dimension_Z_Name as DimensionZName, ES.Dimension_A_Name as DimensionAName, ES.Dimension_X_Eng_Units as DimensionXUnits,
         ES.Dimension_Y_Eng_Units as DimensionYUnits, ES.Dimension_Z_Eng_Units as DimensionZUnits, ES.Dimension_A_Eng_Units as DimensionAUnits,
         @Has_Production_Plans as HasProductionPlans
   From Event_Subtypes ES
   Left Outer Join Event_Details ED on ED.Event_Id = @EventId
   Where ES.Event_SubType_Id = @EventSubTypeId
--   From Event_Details ED Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = @EventSubTypeId
--    Where ED.Event_Id = @EventId
--------------------------------------------------------
-- Process order, pattern and element information
--------------------------------------------------------
 If(@PP_Setup_Detail_Id Is Null)
  Begin
 	 IF @PP_Id is null
 	     Select Process_Order = Null,PP_Id = Null, Forecast_Start_Date = Null, Forecast_End_Date = Null,
 	  	  	 Forecast_Quantity = Null, Product_Code = Null,
 	  	  	 PP_Setup_Id = Null, Pattern_Code = Null,
 	  	  	 Setup_Forecast_Quantity = Null, PP_Status_Desc = Null,PP_Setup_Detail_Id = Null,
 	           Element_Number = Null,Element_Status = Null
 	 ELSE
 	     Select PP.Process_Order as Process_Order, PP.PP_Id, PP.Forecast_Start_Date, PP.Forecast_End_Date, PP.Forecast_Quantity, PR.Prod_Code as Product_Code,
 	            Null as PP_Setup_Id, Null as Pattern_Code, Null as Setup_Forecast_Quantity, Null as PP_Status_Desc, Null as PP_Setup_Detail_Id,
 	            Null as Element_Number, Null as Element_Status
 	      From Production_Plan PP
 	        Left Outer Join Products PR on PP.Prod_Id = PR.Prod_Id
 	       Where PP.PP_Id = @PP_Id
  End
 Else
  Begin
    Select PP.Process_Order as Process_Order, PP.PP_Id, PP.Forecast_Start_Date, PP.Forecast_End_Date, PP.Forecast_Quantity, PR.Prod_Code as Product_Code,
           PS.PP_Setup_Id, PS.Pattern_Code, PS.Forecast_Quantity as Setup_Forecast_Quantity,  PPS.PP_Status_Desc, PD.PP_Setup_Detail_Id, 
           PD.Element_Number, PPS2.PP_Status_Desc as Element_Status
     From Event_Details ED 
                    Join Production_Setup_Detail PD on PD.PP_Setup_Detail_Id = @PP_Setup_Detail_Id
                    Join Production_Setup PS on PS.PP_Setup_Id = PD.PP_Setup_Id
                    Join Production_Plan PP On PP.PP_Id = PS.PP_Id
                    Left Outer Join Production_Plan_Statuses PPS on PS.PP_Status_Id = PPS.PP_Status_Id
                    Left Outer Join Production_Plan_Statuses PPS2 on PD.Element_Status = PPS2.PP_Status_Id
                    Left Outer Join Products PR on PP.Prod_Id = PR.Prod_Id
      Where ED.Event_Id = @EventId
  End
--------------------------------------------------------
-- Customer Order and shipping information
--------------------------------------------------------
  Select OD.Plant_Order_Number, OD.Forecast_Mfg_Date, OD.Forecast_Ship_Date, OD.Actual_Ship_Date, OD.Actual_Mfg_Date,
         PR3.Prod_Code as Ordered_Product, CU.Customer_Code, CU.Customer_Name, SH.Shipment_Number, 
         CU2.Customer_Name as Consignee_Name, SH.Carrier_Type, ED.Order_Id, SH.Shipment_Id, OD.Customer_Order_Number as Customer_Order_Number,
         OD.Order_Type, OD.Order_Status, OI.Complete_Date, OI.Ordered_Quantity, OI.Line_Item_Number, ED.Order_Line_Id,
         ED.PP_Id, ED.PP_Setup_Detail_Id
   FROM EVENTS e
 	 Left Join  Event_Details ED ON Ed.Event_Id = e.Event_id
 	 Left Outer Join Customer_Order_Line_Items OI on ED.Order_Line_Id = OI.Order_Line_Id 
 	 Left Outer Join Customer_Orders OD on OI.Order_Id = OD.Order_Id
 	 Left Outer Join Products PR3 on OI.Prod_Id = PR3.Prod_Id
 	 Left Outer Join Customer CU on OD.Customer_Id = CU.Customer_Id
 	 Left Outer Join Shipment_Line_Items SI On ED.Shipment_Item_Id = SI.Shipment_Item_Id
 	 Left Outer Join Shipment SH on SI.Shipment_Id = SH.Shipment_Id
 	 Left Outer Join Customer CU2 on OI.Consignee_ID = CU2.Customer_Id
    Where E.Event_Id = @EventId

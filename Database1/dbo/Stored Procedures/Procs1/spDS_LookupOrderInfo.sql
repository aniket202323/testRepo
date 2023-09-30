Create Procedure dbo.spDS_LookupOrderInfo
@EventId int
AS
 Declare      @PUId int,
              @EventProdId int, 
              @TimeStamp datetime,
              @OrderLineId int, 
              @ProdId int
 Select @PUId = NULL
 Select @EventProdId = NULL
 Select @TimeStamp = NULL
 Select @OrderLineId = NULL
 Select @ProdId = NULL
--------------------------------------------------------
-- Get Event info
--------------------------------------------------------
 Select @PUId = PU_Id, @TimeStamp = TimeStamp
  From Events
   Where Event_Id= @EventId
--------------------------------------------------------
-- Get Product info from Event_Details  (if set)
--------------------------------------------------------
 Select @EventProdId = Coalesce(E.Applied_Product, PS.Prod_Id), @OrderLineId = ED.Order_Line_Id
   From Event_Details ED
    Join Events E on E.Event_Id = ED.Event_Id
    Join Production_Starts PS On E.PU_Id = PS.Pu_Id
                   And  E.TimeStamp >= PS.Start_Time And (E.TimeStamp <= PS.End_Time Or PS.End_Time IS NULL)
    Where ED.Event_Id = @EventId
--------------------------------------------------------
-- Determine Product
--------------------------------------------------------
 Select @ProdId = Coalesce(@EventProdId, PS.Prod_Id)
   From Production_Starts PS 
    Where PS.PU_Id = @PUId And  @TimeStamp >= PS.Start_Time And (@TimeStamp <= PS.End_Time Or PS.End_Time IS NULL)
--------------------------------------------------------
-- Return Recordset
--------------------------------------------------------
 Select @PUId as PUId, @ProdId as Prod_Id, PP.PP_Id, PS.PP_Setup_Id, PD.PP_Setup_Detail_Id, EV.Order_Line_Id
   From Event_Details EV 
     Left Outer Join Production_Plan PP on PP.PP_Id = EV.PP_Id
     Left Outer Join Production_Setup PS on PS.PP_Id = PP.PP_Id
     Left Outer Join Production_Setup_Detail PD on PD.PP_Setup_Id = PS.PP_Setup_Id
    Where Event_Id = @EventId

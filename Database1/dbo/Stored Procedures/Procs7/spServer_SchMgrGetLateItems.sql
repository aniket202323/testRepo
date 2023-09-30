CREATE PROCEDURE dbo.spServer_SchMgrGetLateItems     
@PPId int,
@LateItems int OUTPUT
AS
Select @LateItems = NULL
Select @LateItems = (select count(*) from Production_Setup ps
        left outer join Production_Setup_Detail psd on psd.PP_setup_Id = ps.PP_Setup_Id
        left outer join Customer_Order_Line_Items coli on coli.Order_Line_Id = psd.Order_Line_Id
        left outer join customer_Orders co on co.Order_Id = coli.Order_Id
        where ps.PP_Id = @PPId
        and co.Forecast_Ship_Date < dbo.fnServer_CmnGetDate(GetUTCDate()))
If (@LateItems Is NULL)
  Select @LateItems = 0

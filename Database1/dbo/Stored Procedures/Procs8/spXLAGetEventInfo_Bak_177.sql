CREATE PROCEDURE dbo.[spXLAGetEventInfo_Bak_177]
 	   @ParamEventNum 	 varchar(50)
 	 , @ParamEventId 	  	 Int = NULL
 	 , @InTimeZone 	 varchar(200) = null
AS
-- MSI/MT 10-Apr-2000
DECLARE 	 @Event_Num 	  	 Varchar(50)
DECLARE 	 @Primary_Event_Num 	 Varchar(50)
DECLARE 	 @EventIdLocal 	  	 Integer
DECLARE @Start_Time 	  	 DateTime 	 --MT/4-23-2002
DECLARE 	 @TimeStamp 	  	 DateTime
DECLARE  	  @EventStatusTinyInt  	  Int
DECLARE @Event_Status 	  	 Varchar(50)
DECLARE 	 @Comment_Id 	  	 Integer
DECLARE 	 @Entered_On 	  	 DateTime
DECLARE 	 @Production_Unit 	 Varchar(50)
DECLARE 	 @Original_Product 	 Varchar(20)
DECLARE 	 @AppliedProdID 	  	 Integer
DECLARE @Applied_Product 	 Varchar(25)
DECLARE 	 @Alternate_Event_Num 	 Varchar(50)
DECLARE 	 @Event_Type 	  	 Varchar(25)
DECLARE 	 @Final_Dimension_X 	 Real
DECLARE 	 @Final_Dimension_Y 	 Real
DECLARE 	 @Final_Dimension_Z 	 Real
DECLARE 	 @Final_Dimension_A 	 Real
 	 --Begin Added MSi/mt/11-07-2001
DECLARE 	 @Initial_Dimension_X 	 Real
DECLARE 	 @Initial_Dimension_Y 	 Real
DECLARE 	 @Initial_Dimension_Z 	 Real
DECLARE 	 @Initial_Dimension_A 	 Real
DECLARE 	 @Orientation_X 	  	 Real
DECLARE 	 @Orientation_Y 	  	 Real
DECLARE 	 @Orientation_Z 	  	 Real
 	 --End Added MSi/mt/11-07-2001
DECLARE 	 @Customer_Order_Number 	 Varchar(50)
DECLARE 	 @Plant_Order_Number 	 Varchar(50)
DECLARE 	 @Shipment_Number        	 Varchar(50)
DECLARE @Extended_Info 	  	 Varchar(255)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
If @ParamEventId is NOT NULL 
    BEGIN 	 SELECT @ParamEventNum = ev.Event_Num FROM Events ev WHERE ev.Event_Id = @ParamEventId
    END
--EndIf
-- Get Basic Attributes From dbo.Events
SELECT @Primary_Event_Num  = ev.Event_Num
     , @Production_Unit    = pu.PU_Desc
     , @TimeStamp          = ev.TimeStamp
     , @EventStatusTinyInt = ev.Event_Status
     , @Comment_Id         = ev.Comment_Id
     , @Entered_On         = ev.Entry_On
     , @Original_Product   = p1.Prod_Code
     , @AppliedProdID      = ev.Applied_Product
     , @Event_Type         = 'Generic'
     , @EventIdLocal       = ev.Event_Id
     , @Start_Time         = COALESCE(ev.Start_Time, DATEADD(ss, -1, ev.TimeStamp))
     , @Extended_Info      = ev.Extended_Info
  FROM Events ev
         --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  JOIN production_starts ps ON ps.pu_id = ev.pu_id AND ps.start_time <= ev.timestamp AND (ps.end_time > ev.timestamp OR ps.end_time is null)
  JOIN products p1 ON p1.prod_id = ps.prod_id
  JOIN prod_units pu ON pu.pu_id = ev.pu_id
 WHERE ev.Event_Num = @ParamEventNum
-- Get Attributes From Other tables
SELECT @Applied_Product = Case  @AppliedProdID When Null Then Null Else p.Prod_Code End
FROM   Products p 
WHERE  p.Prod_Id = @AppliedProdID 
SELECT  @Event_Status = Case @EventStatusTinyInt When Null Then Null Else pt.ProdStatus_Desc End
FROM    Production_Status pt
WHERE   pt.ProdStatus_Id = @EventStatusTinyInt
 	 
SELECT    @Alternate_Event_Num 	 = ed.Alternate_Event_Num 	  	  	 
 	 , @Initial_Dimension_X 	 = ed.Initial_Dimension_X
 	 , @Initial_Dimension_Y 	 = ed.Initial_Dimension_Y
 	 , @Initial_Dimension_Z 	 = ed.Initial_Dimension_Z
 	 , @Initial_Dimension_A 	 = ed.Initial_Dimension_A
 	 , @Final_Dimension_X 	 = ed.Final_Dimension_X 	 
 	 , @Final_Dimension_Y 	 = ed.Final_Dimension_Y 	 
       	 , @Final_Dimension_Z 	 = ed.Final_Dimension_Z 	 
 	 , @Final_Dimension_A 	 = ed.Final_Dimension_A 	 
 	 , @Customer_Order_Number = co.Customer_Order_Number 	 
 	 , @Plant_Order_Number 	 = co.Plant_Order_Number 	 
       	 , @Shipment_Number 	 = s.Shipment_Number
        --Begin Added attributes; MSi/mt/11-07-2001
 	 , @Orientation_X  	 = ed.Orientation_X
 	 , @Orientation_Y  	 = ed.Orientation_Y
 	 , @Orientation_Z  	 = ed.Orientation_Z
 	 --End Added attributes; MSi/mt/11-07-2001
FROM    Event_Details ed 	 
LEFT OUTER JOIN   customer_orders co ON co.order_id = ed.order_id
LEFT OUTER JOIN   shipment_line_items sl ON sl.shipment_item_id = ed.shipment_item_id 	 
LEFT OUTER JOIN   shipment s ON s.shipment_id = sl.shipment_id 	  	 
WHERE 	 ed.event_id = @EventIdLocal
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
-- Retrieve All Attributes From Local Variables
SELECT    Primary_Event_Num  	 = @Primary_Event_Num
 	 , Event_Id  	  	 = @EventIdLocal
 	 , Production_Unit  	 = @Production_Unit
    , Start_Time        = dbo.fnServer_CmnConvertFromDbTime(@Start_Time,@InTimeZone)
 	 , TimeStamp  	  	 = dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,@InTimeZone)
    , Event_Status  	  	 = @Event_Status
 	 , Comment_Id  	  	 = @Comment_Id
 	 , Entered_On  	  	 = dbo.fnServer_CmnConvertFromDbTime(@Entered_On,@InTimeZone)
       	 , Original_Product  	 = @Original_Product
 	 , Applied_Product  	 = @Applied_Product 
 	 , Alternate_Event_Num  	 = @Alternate_Event_Num
       	 , Event_Type  	  	 = 'Generic'
 	 , Initial_Dimension_X  	 = @Initial_Dimension_X
 	 , Initial_Dimension_Y  	 = @Initial_Dimension_Y
 	 , Initial_Dimension_Z  	 = @Initial_Dimension_Z
 	 , Initial_Dimension_A  	 = @Initial_Dimension_A
 	 , Final_Dimension_X  	 = @Final_Dimension_X
 	 , Final_Dimension_Y  	 = @Final_Dimension_Y
       	 , Final_Dimension_Z  	 = @Final_Dimension_Z
 	 , Final_Dimension_A  	 = @Final_Dimension_A
 	 , Customer_Order_Number = @Customer_Order_Number
 	 , Plant_Order_Number  	 = @Plant_Order_Number
       	 , Shipment_Number  	 = @Shipment_Number                 
 	 --Begin Added 11-07-2001; MSi/mt
 	 , Orientation_X  	 = @Orientation_X
 	 , Orientation_Y  	 = @Orientation_Y
 	 , Orientation_Z  	 = @Orientation_Z
 	 --End Added 11-07-2001; MSi/mt
        , Extended_Info         = @Extended_Info

Create Procedure dbo.spXLAGetUnitEventInfo
 	   @PuID 	  	  	 Int
 	 , @ParamEventNum 	 Varchar(50)
 	 , @ParamEventId 	  	 Int = NULL
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
/* MSI/MT/26-Oct-2000
   --------------------- */
Declare 	 @Event_Num 	  	 Varchar(50)
Declare 	 @Primary_Event_Num 	 Varchar(50)
Declare 	 @EventIdLocal 	  	 Integer
Declare 	 @TimeStamp 	  	 DateTime
Declare 	 @EventStatusTinyInt 	 Int
Declare @Event_Status 	  	 Varchar(50)
Declare 	 @Comment_Id 	  	 Integer
Declare 	 @Entered_On 	  	 DateTime
Declare 	 @Production_Unit 	 Varchar(50)
Declare 	 @Original_Product 	 Varchar(20)
Declare 	 @AppliedProdID 	  	 Integer
Declare @Applied_Product 	 Varchar(25)
Declare 	 @Alternate_Event_Num 	 Varchar(50)
Declare 	 @Event_Type 	  	 Varchar(25)
Declare 	 @Final_Dimension_X 	 Real
Declare 	 @Final_Dimension_Y 	 Real
Declare 	 @Final_Dimension_Z 	 Real
Declare 	 @Final_Dimension_A 	 Real
Declare 	 @Customer_Order_Number 	 Varchar(50)
Declare 	 @Plant_Order_Number 	 Varchar(50)
Declare 	 @Shipment_Number        	 Varchar(50)
If @ParamEventId is NOT NULL 
    BEGIN  SELECT @ParamEventNum = ev.Event_Num FROM Events ev WHERE ev.Event_Id = @ParamEventId
    END
/* Get Basic Attributes From dbo.Events
   ------------------------------------ */
SELECT    @Primary_Event_Num 	 = ev.Event_Num
 	 , @Production_Unit 	 = pu.PU_Desc
 	 , @TimeStamp 	  	 = ev.TimeStamp
       	 , @EventStatusTinyInt 	 = ev.Event_Status
 	 , @Comment_Id 	  	 = ev.Comment_Id
 	 , @Entered_On 	  	 = ev.Entry_On
       	 , @Original_Product 	 = p1.Prod_Code
 	 , @AppliedProdID 	 = ev.Applied_Product
       	 , @Event_Type 	  	 = 'Generic'
 	 , @EventIdLocal 	  	 = ev.Event_Id
From    Events ev
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
JOIN    Production_Starts ps ON ps.Pu_Id = ev.Pu_Id 
AND     (ps.Start_Time <= ev.TimeStamp AND (ps.End_Time is null OR ps.End_Time > ev.TimeStamp))
JOIN    Products p1 ON p1.Prod_Id = ps.Prod_Id
JOIN    Prod_Units pu ON pu.Pu_Id = ev.Pu_Id AND pu.Pu_Id = @PuId
WHERE   ev.Event_Num = @ParamEventNum
/* Get Attributes From Other tables
   -------------------------------- */
Select @Applied_Product = Case  @AppliedProdID When Null Then Null Else p.Prod_Code End
From   Products p 
Where  p.Prod_Id = @AppliedProdID 
Select  @Event_Status = Case @EventStatusTinyInt When Null Then Null Else pt.ProdStatus_Desc End
From    Production_Status pt
Where   pt.ProdStatus_Id = @EventStatusTinyInt
 	 
SELECT    @Alternate_Event_Num 	 = ed.Alternate_Event_Num 	 
 	 , @Final_Dimension_X 	 = ed.Final_Dimension_X 	 
 	 , @Final_Dimension_Y 	 = ed.Final_Dimension_Y 	 
       	 , @Final_Dimension_Z 	 = ed.Final_Dimension_Z 	 
 	 , @Final_Dimension_A 	 = ed.Final_Dimension_A 	 
 	 , @Customer_Order_Number= co.Customer_Order_Number 	 
 	 , @Plant_Order_Number 	 = co.Plant_Order_Number 	 
       	 , @Shipment_Number 	 = s.Shipment_Number
From    Event_Details ed 	 
LEFT OUTER JOIN   Customer_Orders co ON co.Order_Id = ed.Order_Id
LEFT OUTER JOIN   Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id 	 
LEFT OUTER JOIN   Shipment s ON s.Shipment_Id = sl.Shipment_Id 	  	 
WHERE 	 ed.Event_Id = @EventIdLocal
/* Retrieve All Attributes From Local Variables
   -------------------------------------------- */
SELECT    Primary_Event_Num 	 = @Primary_Event_Num
 	 , Event_Id 	  	 = @EventIdLocal
 	 , Production_Unit 	 = @Production_Unit
 	 , TimeStamp 	  	 = @TimeStamp at time zone @DBTz at time zone @InTimeZone
       	 , Event_Status 	  	 = @Event_Status
 	 , Comment_Id 	  	 = @Comment_Id
 	 , Entered_On 	  	 = @Entered_On at time zone @DBTz at time zone @InTimeZone
       	 , Original_Product 	 = @Original_Product
 	 , Applied_Product 	 = @Applied_Product 
 	 , Alternate_Event_Num 	 = @Alternate_Event_Num
       	 , Event_Type 	  	 = 'Generic'
 	 , Final_Dimension_X 	 = @Final_Dimension_X
 	 , Final_Dimension_Y 	 = @Final_Dimension_Y
       	 , Final_Dimension_Z 	 = @Final_Dimension_Z
 	 , Customer_Order_Number 	 = @Customer_Order_Number
 	 , Plant_Order_Number 	 = @Plant_Order_Number
       	 , Shipment_Number 	 = @Shipment_Number                 

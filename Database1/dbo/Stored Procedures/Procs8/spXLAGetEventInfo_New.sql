-- DESCRIPTION: spXLAGetEventInfo_New is based on spXLAGetEventInfo_New. Changes include Pu_Id as parameter if Event_Id is
--              not specified.  This change eliminates problem with getting wrong event information due to duplication
--              in event_num across the system. MT/4-23-2002
--              Defect #24962:mt/1-13-2003:added more fields to recordset
CREATE PROCEDURE dbo.spXLAGetEventInfo_New
 	   @Event_Id 	 Int
 	 , @Pu_Id 	 Int
 	 , @Event_Num 	 Varchar(50)
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
DECLARE 	 @Primary_Event_Num 	 Varchar(50)
DECLARE @Start_Time 	  	 DateTime
DECLARE 	 @TimeStamp 	  	 DateTime
DECLARE 	 @EventStatusTinyInt 	 Int
DECLARE @Event_Status 	  	 Varchar(50)
DECLARE 	 @Comment_Id 	  	 Integer
DECLARE 	 @Entered_On 	  	 DateTime
DECLARE 	 @Production_Unit 	 Varchar(50)
DECLARE 	 @Original_Product 	 Varchar(25) --changed from 20 to 25 chars; Defect #24734:mt/12-31-2002
DECLARE 	 @AppliedProdID 	  	 Integer
DECLARE @Applied_Product 	 Varchar(25)
DECLARE 	 @Alternate_Event_Num 	 Varchar(50)
DECLARE 	 @Event_Type 	  	 Varchar(25)
DECLARE 	 @Final_Dimension_X 	 Real
DECLARE 	 @Final_Dimension_Y 	 Real
DECLARE 	 @Final_Dimension_Z 	 Real
DECLARE 	 @Final_Dimension_A 	 Real
DECLARE 	 @Initial_Dimension_X 	 Real
DECLARE 	 @Initial_Dimension_Y 	 Real
DECLARE 	 @Initial_Dimension_Z 	 Real
DECLARE 	 @Initial_Dimension_A 	 Real
DECLARE 	 @Orientation_X 	  	 Real
DECLARE 	 @Orientation_Y 	  	 Real
DECLARE 	 @Orientation_Z 	  	 Real
DECLARE 	 @Customer_Order_Number 	 Varchar(50)
DECLARE 	 @Plant_Order_Number 	 Varchar(50)
DECLARE 	 @Shipment_Number        	 Varchar(50)
DECLARE @Extended_Info 	  	 Varchar(255)
DECLARE @Event_Conformance      TinyInt
DECLARE @Testing_Prct_Complete  TinyInt
DECLARE @User_Id                Int
DECLARE @Second_User_Id         Int
DECLARE @Approver_User_Id       Int
DECLARE @User_Signoff_Id        Int
DECLARE @User_Reason_Id         Int
DECLARE @Approver_Reason_Id     Int
DECLARE @User                   Varchar(30)
DECLARE @Second_User            Varchar(30)
DECLARE @Approver_User          Varchar(30)
DECLARE @User_Signoff           Varchar(30)
DECLARE @User_Reason            Varchar(100)
DECLARE @Approver_Reason        Varchar(100)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
If @Event_Id is NULL 
  BEGIN 	 
    If @Pu_Id Is NOT NULL
      SELECT @Event_Id = e.Event_Id FROM Events e WHERE e.Event_Num = @Event_Num AND e.Pu_Id = @Pu_Id
    Else --@Pu_Id is Null (PrfXla.xla will try to prevent this)
      SELECT @Event_Id = e.Event_Id FROM Events e WHERE e.Event_Num = @Event_Num
    --EndIf
  END
--EndIf
-- Get Basic Attributes From dbo.Events
SELECT @Primary_Event_Num     = e.Event_Num
     , @Production_Unit       = pu.PU_Desc
     , @TimeStamp             = e.TimeStamp
     , @EventStatusTinyInt    = e.Event_Status
     , @Comment_Id            = e.Comment_Id
     , @Entered_On            = e.Entry_On
     , @Original_Product      = p1.Prod_Code
     , @AppliedProdID         = e.Applied_Product
     , @Event_Type            = 'Generic'
     , @Start_Time            = COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp))
     , @Extended_Info         = e.Extended_Info
     , @Event_Conformance     = e.Conformance
     , @Testing_Prct_Complete = e.Testing_Prct_Complete
     , @User_Id               = e.User_Id
     , @Second_User_Id        = e.Second_User_Id
     , @Approver_User_Id      = e.Approver_User_Id
     , @User_Signoff_Id       = e.User_Signoff_Id
     , @User_Reason_Id        = e.User_Reason_Id
     , @Approver_Reason_Id    = e.Approver_Reason_Id
  FROM Events e with(index(Events_PK_EventId))
         --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  JOIN production_starts ps ON ps.pu_id = e.pu_id AND ps.start_time <= e.timestamp AND (ps.end_time > e.timestamp OR ps.end_time is null)
  JOIN products p1 ON p1.prod_id = ps.prod_id
  JOIN prod_units pu ON pu.pu_id = e.pu_id
 WHERE e.Event_Id = @Event_Id
-- Get Attributes From Other tables
SELECT @Applied_Product = Case  @AppliedProdID When NULL Then NULL Else p.Prod_Code End
  FROM Products p 
 WHERE p.Prod_Id = @AppliedProdID 
SELECT @Event_Status = Case @EventStatusTinyInt When NULL Then NULL Else pt.ProdStatus_Desc End
  FROM Production_Status pt
 WHERE pt.ProdStatus_Id = @EventStatusTinyInt
 	 
SELECT @Alternate_Event_Num   = ed.Alternate_Event_Num 	  	  	 
     , @Initial_Dimension_X   = ed.Initial_Dimension_X
     , @Initial_Dimension_Y   = ed.Initial_Dimension_Y
     , @Initial_Dimension_Z   = ed.Initial_Dimension_Z
     , @Initial_Dimension_A   = ed.Initial_Dimension_A
     , @Final_Dimension_X     = ed.Final_Dimension_X 	 
     , @Final_Dimension_Y     = ed.Final_Dimension_Y 	 
     , @Final_Dimension_Z     = ed.Final_Dimension_Z 	 
     , @Final_Dimension_A     = ed.Final_Dimension_A 	 
     , @Customer_Order_Number = co.Customer_Order_Number 	 
     , @Plant_Order_Number    = co.Plant_Order_Number 	 
     , @Shipment_Number 	       = s.Shipment_Number
     , @Orientation_X  	       = ed.Orientation_X
     , @Orientation_Y  	       = ed.Orientation_Y
     , @Orientation_Z  	       = ed.Orientation_Z
 FROM Event_Details ed 	 
 LEFT OUTER JOIN customer_orders co ON co.order_id = ed.order_id
 LEFT OUTER JOIN shipment_line_items sl ON sl.shipment_item_id = ed.shipment_item_id 	 
 LEFT OUTER JOIN shipment s ON s.shipment_id = sl.shipment_id 	  	 
 WHERE ed.Event_Id = @Event_Id
--Get User-Related Attributes
SELECT @Approver_User = u.Username FROM Users u WHERE u.User_Id = @Approver_User_Id
SELECT @User_Signoff  = u2.Username FROM Users u2 WHERE u2.User_Id = @User_Signoff_Id
SELECT @User          = u3.Username FROM  Users u3 WHERE u3.User_Id = @User_Id
SELECT @Second_User   = u4.Username FROM  Users u4 WHERE u4.User_Id = @Second_User_Id
--Get Reason-Related Attributes
SELECT @User_Reason     = r.Event_Reason_Name FROM Event_Reasons r WHERE r.Event_Reason_Id = @User_Reason_Id
SELECT @Approver_Reason = r2.Event_Reason_Name FROM Event_Reasons r2 WHERE r2.Event_Reason_Id = @Approver_Reason_Id
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
-- Retrieve All Attributes From Local Variables
SELECT Primary_Event_Num     = @Primary_Event_Num
     , Event_Id              = @Event_Id
     , Production_Unit       = @Production_Unit
     , Start_Time            = @Start_Time at time zone @DBTz at time zone @InTimeZone
     , TimeStamp             = @TimeStamp at time zone @DBTz at time zone @InTimeZone
     , Event_Status          = @Event_Status
     , Comment_Id            = @Comment_Id
     , Entered_On            = @Entered_On at time zone @DBTz at time zone @InTimeZone
     , Original_Product      = @Original_Product
     , Applied_Product  	      = @Applied_Product 
     , Alternate_Event_Num   = @Alternate_Event_Num
     , Event_Type  	      = 'Generic'
     , Initial_Dimension_X   = @Initial_Dimension_X
     , Initial_Dimension_Y   = @Initial_Dimension_Y
     , Initial_Dimension_Z   = @Initial_Dimension_Z
     , Initial_Dimension_A   = @Initial_Dimension_A
     , Final_Dimension_X     = @Final_Dimension_X
     , Final_Dimension_Y     = @Final_Dimension_Y
     , Final_Dimension_Z     = @Final_Dimension_Z
     , Final_Dimension_A     = @Final_Dimension_A
     , Customer_Order_Number = @Customer_Order_Number
     , Plant_Order_Number    = @Plant_Order_Number
     , Shipment_Number       = @Shipment_Number                 
     , Orientation_X         = @Orientation_X
     , Orientation_Y         = @Orientation_Y
     , Orientation_Z         = @Orientation_Z
     , Extended_Info         = @Extended_Info
     , Event_Conformance     = @Event_Conformance
     , Testing_Prct_Complete = @Testing_Prct_Complete
     , Approver_User         = @Approver_User
     , User_Signoff          = @User_Signoff
     , Username              = @User
     , Second_User           = @Second_User
     , User_Reason           = @User_Reason
     , Approver_Reason       = @Approver_Reason

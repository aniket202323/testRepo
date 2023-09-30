           
CREATE  PROCEDURE [dbo].[spRIS_GetReceiverMaterialLots]
  @searchCriteria	NVARCHAR(255)	= NULL,
  @receiverId		INT				= NULL,
  @status			NVARCHAR(50)	= NULL
AS

/*---------------------------------------------------------------------------------------------------------------------
    This stored procedure returns receivers by receiver or product name
  
    Date         Ver/Build   Author              Story/Defect        Remarks
    Multiple	   001         Multiple                                Initial Development
    28-Aug-2020  002         Evgeniy Kim         DE139175            Only return RI events
    29-Sep-2020	 003		     Evgeniy Kim		     DE143111			       Completed receivers will work with a new status
																	                                   of 'Receiver Complete' now as well
    12-Jan-2021            Chandrasekhar P     DE151680          
---------------------------------------------------------------------------------------------------------------------
    NOTES: 
    1. [Event_Details].PP_Id is NULL for RI events, while OSP receiers will have a value
    
    QUESTIONS:
    1. 


---------------------------------------------------------------------------------------------------------------------*/
DECLARE @SQL NVARCHAR(MAX)='';
DEclare @ProdStatus Nvarchar(max)
DECLARE @output Table   
(
  source_Event_id INT,
  source_event_num NVARCHAR(50),
  source_Event_timestamp DATETIME,
  source_Event_unitId INT,
  source_Event_status NVARCHAR(50),
  source_event_status_id INT,
  target_event_id INT,
  target_event_number NVARCHAR(50),
  target_event_quantity FLOAT,
  target_event_unit_id INT,
  target_event_comment_id INT,
  target_Event_status NVARCHAR(50),
  target_event_status_id INT,
  target_Event_entry_on DATETIME,
  product_id INT,
  isSerialized BIT,
  event_subtype_desc NVARCHAR(50)
);

DECLARE @productCode NVARCHAR(255) = NULL;
-- Check if user has searched based on receiver number or product code    
IF(@receiverId IS NULL) 
BEGIN
  SELECT @receiverId = Event_Id
  FROM events
  WHERE Event_Num = @searchCriteria;
  SELECT @productCode = prod_code
  FROM products
  WHERE Prod_Code = @searchCriteria;
END

-- Return if invalid productId or receiverId        
IF(@searchCriteria IS NOT NULL AND @receiverId IS NULL AND @productCode IS NULL)          
BEGIN
  RETURN; -- should we return an error message here?           
END

DECLARE @productionStatus Table
(
  prod_status NVARCHAR(255)   
);

-- GET the condition for  'Open' and 'Complete' status  
IF(@status = N'open')   
BEGIN
  INSERT INTO @productionStatus
  SELECT prodStatus_Desc
  FROM production_status  
  WHERE (prodStatus_Desc) != N'complete' and (prodStatus_Desc) != N'receiver complete' and Count_For_Inventory = 0 and Count_For_Production = 0;
END    
ELSE IF (@status = N'complete')
BEGIN
  INSERT INTO @productionStatus
  SELECT prodStatus_Desc
  FROM production_status  
  WHERE prodStatus_Desc IN(N'complete',N'receiver complete')
  --= N'complete' OR (prodStatus_Desc) = N'receiver complete';
END 
ELSE
BEGIN
  INSERT INTO @productionStatus
  SELECT prodStatus_Desc 
  FROM production_status  ;
END

Select @ProdStatus = COALESCE(@ProdStatus+''',''','')+prod_status From @productionStatus;

SELECT @ProdStatus = ''''+@ProdStatus+''''

-- Get material Lots based on receiver Id or product code  
SELECT @SQL='
SELECT DISTINCT
  receiver.Event_Id,
  receiver.event_num,
  receiver.TimeStamp,
  receiver.PU_Id,
  receiverStatus.ProdStatus_Desc,
  receiverStatus.ProdStatus_Id,
  childMaterialLots.Event_Id,
  childMaterialLots.Event_Num,
  eventDetails.Initial_Dimension_X,
  childMaterialLots.PU_Id,
  childMaterialLots.comment_id,
  materialLotStatus.ProdStatus_Desc,
  materialLotStatus.ProdStatus_Id,
  childMaterialLots.Entry_On,
  Product.prod_Id,
  CASE WHEN serialized.isSerialized IS NULL THEN 0 ELSE serialized.isSerialized END,
  NULL

FROM  [dbo].[Events] receiver
JOIN	[dbo].[Event_Components] eventComponents
ON	  eventComponents.Source_Event_Id =  receiver.event_id
JOIN	[dbo].Production_Status receiverStatus
ON	  receiverStatus.ProdStatus_Id = receiver.Event_Status -- Retrieve receiver status   
JOIN	[dbo].[Events] childMaterialLots
ON	  eventComponents.Event_id = childMaterialLots.Event_Id
AND	  childMaterialLots.event_num = childMaterialLots.Lot_Identifier --Filter events created by work order service  
JOIN	[dbo].Event_Details eventDetails
ON	  eventDetails.Event_Id = childMaterialLots.Event_Id -- Fetch quantity of material lot    
JOIN	[dbo].[Production_Starts]  ps
ON	  childMaterialLots.PU_Id = ps.PU_Id -- Find out the product that was running at the child PE timestamp  
AND	  childMaterialLots.TimeStamp >= ps.Start_Time
AND	  (childMaterialLots.Timestamp < ps.End_Time OR ps.end_time is NULL)
JOIN	[dbo].[products] Product
ON	  Product.prod_Id = COALESCE(childMaterialLots.Applied_Product, PS.prod_ID)
JOIN	[dbo].Production_Status materialLotStatus
ON	  materialLotStatus.ProdStatus_Id = childMaterialLots.Event_Status -- Retrieve lot status   
LEFT JOIN [dbo].[Product_Serialized] serialized
ON	  serialized.product_id = Product.Prod_Id
JOIN  [dbo].[Event_Details] ED
ON	  ED.Event_Id = childMaterialLots.Event_id
AND	  ED.PP_Id IS NULL  
WHERE 1=1 
'
+CASE WHEN @receiverId IS NOT NULL  THEN ' AND receiver.Event_Id = '+cast(@receiverId as nvarchar) ELSE '' END
--+Case when @productCode IS NOT NULL THEN ' AND Product.Prod_Code= '+@productCode ELSE '' END /* If @receiverid is mandatory input then no need to check this*/
+CASE WHEN @ProdStatus IS NOT NULL  THEN ' AND receiverStatus.prodStatus_desc IN ('+ @ProdStatus+')' ELSE '' END
+' ORDER BY childMaterialLots.Entry_On'

INSERT INTO @output
EXEC (@SQL)


UPDATE T SET T.event_subtype_desc = subtype.Event_Subtype_Desc
FROM	@output T
JOIN	Event_Configuration config 
ON	  T.source_Event_unitId = config.PU_Id
JOIN	Event_Subtypes subtype 
ON	  subtype.Event_Subtype_Id = config.Event_Subtype_Id;

--Return the search criteria  
SELECT
  source_Event_id,
  source_event_num,
  source_Event_timestamp,
  source_Event_unitId,
  source_Event_status,
  source_event_status_id,
  target_event_id,
  target_event_number,
  target_event_quantity,
  target_event_unit_id,
  target_event_comment_id,
  target_Event_status,
  target_event_status_id,
  target_Event_entry_on,
  product_id,
  isSerialized

FROM @output
WHERE event_subtype_desc = N'Receiver';
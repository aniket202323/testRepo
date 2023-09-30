
CREATE PROCEDURE [dbo].[spRIS_GetReceiverMaterialLotsByWildCardSearch]
	@searchCriteria NVARCHAR(255) = NULL,       
	@status         NVARCHAR(50) = NULL           
AS   

/*---------------------------------------------------------------------------------------------------------------------
    This stored procedure returns receivers by receiver or product name with a wildcard search
  
    Date         Ver/Build   Author              Story/Defect        Remarks
    Multiple	 001         Multiple                                Initial Development
    28-Aug-2020  002         Evgeniy Kim         DE139175            Only return RI events
    29-Sep-2020	 003		 Evgeniy Kim		 DE143111			 Completed receivers will work with a new status
																	 of 'Receiver Complete' now as well
    12- JAN-2021             Chandrasekhar P     DE151680

---------------------------------------------------------------------------------------------------------------------
    NOTES: 
    1. 
    
    QUESTIONS:
    1. What if search text is found in both receiver AND product?


---------------------------------------------------------------------------------------------------------------------*/
DECLARE @SQL NVARCHAR(MAX)=''
DECLARE @receiverCount int = 0
DECLARE @productCount int = 0
DEclare @ProdStatus Nvarchar(max)     
-- Check if there are receivers with searched receiver number        
SELECT @receiverCount = COUNT(Event_Id) FROM Events WHERE Event_Num LIKE @searchCriteria + '%'
SELECT @productCount = COUNT(prod_code) FROM Products WHERE Prod_Code LIKE @searchCriteria + '%'

-- Return if no results found with provided input parameters
IF (@searchCriteria IS NOT NULL AND @receiverCount = 0 AND @productCount = 0)
BEGIN
   RETURN;
END

Declare  @productionStatus TABLE
(
	prod_status NVARCHAR(255)
);

IF (@status = N'open')
BEGIN
	INSERT INTO @productionStatus SELECT prodStatus_Desc FROM production_status  WHERE prodStatus_Desc != N'complete'
	AND prodStatus_Desc != N'receiver complete';
END
ELSE
BEGIN
	INSERT INTO @productionStatus SELECT prodStatus_Desc FROM production_status  WHERE prodStatus_Desc IN( N'complete',N'receiver complete')
	--prodStatus_Desc = N'complete' OR prodStatus_Desc = N'receiver complete';
END

Select @ProdStatus = COALESCE(@ProdStatus+''',''','')+prod_status From @productionStatus;

SELECT @ProdStatus = ''''+@ProdStatus+''''

IF (@receiverCount > 0)
BEGIN
SELECT @SQL='
	SELECT DISTINCT
		eventComponents.Source_Event_Id,
		parentReceiver.event_num source_event_num,
		Product.prod_Id product_id,
		Product.Prod_Code product_code,
		receiverStatus.prodStatus_desc receiver_status
	FROM	[dbo].[Events] parentReceiver
	JOIN	[dbo].[Event_Components] eventComponents 
	ON		parentReceiver.Event_Id = eventComponents.Source_Event_Id
	JOIN	[dbo].Production_Status receiverStatus 
	ON		receiverStatus.ProdStatus_Id = parentReceiver.Event_Status
	JOIN	[dbo].[Events] childMaterialLots 
	ON		eventComponents.Event_id = childMaterialLots.Event_Id
	JOIN	[dbo].[Production_Starts]  ps          -- Find out what product was running at the child PE timestamp                 
	ON		childMaterialLots.PU_Id = ps.PU_Id                 
	AND	childMaterialLots.TimeStamp >= ps.Start_Time               
	AND	(childMaterialLots.Timestamp < ps.End_Time  OR ps.end_time IS NULL)
	JOIN	[dbo].[products] Product 
	ON		Product.prod_Id = COALESCE(childMaterialLots.Applied_Product, PS.prod_ID)
	JOIN	Event_Configuration config
	ON		config.PU_Id = parentReceiver.PU_Id
	JOIN	Event_Subtypes subtype
	ON		subtype.Event_Subtype_Id = config.Event_Subtype_Id
	AND	subtype.Event_Subtype_Desc = N''Receiver''
	JOIN	Event_Details  ED
	ON		ED.Event_Id = childMaterialLots.Event_id
	AND	ED.PP_Id IS NULL
	WHERE	parentReceiver.Event_Id IN (SELECT Event_Id FROM Events WHERE Event_Num LIKE ' +''''+@searchCriteria + '%' + ''')
	AND	receiverStatus.prodStatus_desc IN ('+ @ProdStatus+')
	GROUP BY eventComponents.Event_Id, 
			 eventComponents.Source_Event_Id,
			 parentReceiver.event_num,
			 Product.prod_Id,
			 Product.Prod_Code,
			 receiverStatus.prodStatus_desc;'
			 EXECUTE(@SQL)
END
ELSE IF (@receiverCount <= 0 AND @productCount > 0)
BEGIN
SELECT @SQL='
	SELECT DISTINCT
		eventComponents.Source_Event_Id,
		parentReceiver.event_num source_event_num,
		Product.prod_Id product_id,
		Product.Prod_Code product_code,
		receiverStatus.prodStatus_desc receiver_status
	FROM	[dbo].[Events] parentReceiver
	JOIN	[dbo].[Event_Components] eventComponents 
	ON		parentReceiver.Event_Id = eventComponents.Source_Event_Id
	JOIN	[dbo].Production_Status receiverStatus 
	ON		receiverStatus.ProdStatus_Id = parentReceiver.Event_Status
	JOIN	[dbo].[Events] childMaterialLots 
	ON		eventComponents.Event_id = childMaterialLots.Event_Id
	JOIN	[dbo].[Production_Starts] ps          -- Find out what product was running at the child PE timestamp                 
	ON		childMaterialLots.PU_Id = ps.PU_Id                 
	AND	childMaterialLots.TimeStamp >= ps.Start_Time               
	AND	(childMaterialLots.Timestamp < ps.End_Time OR ps.end_time IS NULL)
	JOIN	[dbo].[products] Product 
	ON		Product.prod_Id = COALESCE(childMaterialLots.Applied_Product, PS.prod_ID)
	JOIN	Event_Configuration config
	ON		config.PU_Id = parentReceiver.PU_Id
	JOIN	Event_Subtypes subtype
	ON		subtype.Event_Subtype_Id = config.Event_Subtype_Id
	AND	subtype.Event_Subtype_Desc = N''Receiver''
	JOIN	Event_Details  ED
	ON		ED.Event_Id = childMaterialLots.Event_id
	AND	ED.PP_Id IS NULL
	WHERE	Product.Prod_Code IN (SELECT prod_code from products WHERE Prod_Code LIKE ' +''''+@searchCriteria + '%' + ''')
	AND	receiverStatus.prodStatus_desc IN ('+ @ProdStatus+')
	GROUP BY eventComponents.Event_Id, 
			 eventComponents.Source_Event_Id,
			 parentReceiver.event_num,
			 Product.prod_Id,
			 Product.Prod_Code,
			 receiverStatus.prodStatus_desc;'
			 EXECUTE(@SQL)
END
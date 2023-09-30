 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KIT_GetStatusesForCarrier
	
	Calculate the status of kits, and POs on the carrier.
	
	Date			Version		Build	Author  
	20-05-2017		001			001		Susan Lee (GE Digital)		Initial development	
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(255)
EXEC dbo.spLocal_MPWS_KIT_GetStatusesForCarrier @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 152674
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_KIT_GetStatusesForCarrier_20170620]
	@ErrorCode			INT				OUTPUT,		-- Flag to indicate Success or Failure (1-Success,0-Failure)
	@ErrorMessage		VARCHAR(255)	OUTPUT,		-- Error Message to Write to Log File
	@CarrierEventId		INT							-- the Event_Id of the carrier to get the status of
	
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------
DECLARE @StatusToUpdate TABLE
(
	Type		VARCHAR(10)	,
	Id			INT			,
	StatusDesc	VARCHAR(50),
	StatusId	INT
)
 
DECLARE @CarrierStatusId	INT,
		@CarrierStatusDesc	VARCHAR(50),
		@MatchingPPStatusId	INT
 
------------------------------------------------------------------------------
-- Get Carrier Status
------------------------------------------------------------------------------
SELECT	@CarrierStatusId	= e.Event_Status,
		@CarrierStatusDesc	= ps.ProdStatus_Desc	
FROM	dbo.Events e
JOIN	dbo.Production_Status ps on e.Event_Status = ps.ProdStatus_Id
WHERE	e.Event_Id = @CarrierEventId
 
IF @CarrierStatusDesc NOT IN ('Ready For Production','Staged')
BEGIN
	SELECT	@ErrorCode = -1,
			@ErrorMessage = 'Carrier not in Ready for Production or Staged'
	RETURN
END
 
------------------------------------------------------------------------------
-- Get production plan status Id
------------------------------------------------------------------------------
SELECT	@MatchingPPStatusId	= PP_Status_Id
FROM	dbo.Production_Plan_Statuses
WHERE	PP_Status_Desc	= @CarrierStatusDesc
 
------------------------------------------------------------------------------
-- Get all kit events on the carrier
------------------------------------------------------------------------------
INSERT INTO @StatusToUpdate
			(Type,Id)
SELECT		'EVENT',
			k.event_id
FROM		dbo.events c 
JOIN		dbo.event_Components	c_cs	ON c_cs.source_event_id = c.event_id
JOIN		dbo.events				cs		ON cs.event_id = c_cs.event_id
JOIN		dbo.event_components	cs_k	ON cs_k.event_id = cs.event_id
JOIN		dbo.events				k		ON k.event_id = cs_k.source_event_id and k.event_num not like 'CA%'
WHERE		c.event_id = @CarrierEventId
 
------------------------------------------------------------------------------
-- Get all carrier status on each kit... if all carriers in the kit are RFP 
-- or Staged, update the kit to RFP or Staged.
------------------------------------------------------------------------------
-- TODO: are all the carriers in the kit (kits can span carriers) in RFP or Staged?
UPDATE @StatusToUpdate 
SET StatusDesc	=	@CarrierStatusDesc,
	StatusId	=	@CarrierStatusId
WHERE Type		=	'EVENT'
------------------------------------------------------------------------------
-- Get POs
------------------------------------------------------------------------------
 
INSERT INTO @StatusToUpdate
(Type,Id)
SELECT DISTINCT 'PO',pp.PP_Id
FROM	dbo.Production_Plan	pp
JOIN	dbo.Event_Details	kit			  ON kit.PP_Id = pp.PP_Id	
JOIN	@StatusToUpdate		KitsOnCarrier ON kit.Event_Id = KitsOnCarrier.Id and TYPE = 'EVENT'	
 
------------------------------------------------------------------------------
-- Get all carrier status on each PO... if all carriers in the PO are RFP 
-- or Staged, update the PO to RFP or Staged.
------------------------------------------------------------------------------
-- TODO: are all the carriers in the PO (POs can span carriers) in RFP or Staged?
 
UPDATE @StatusToUpdate 
SET StatusDesc	=	@CarrierStatusDesc,
	StatusId	=	@MatchingPPStatusId
WHERE Type		=	'PO'
 
------------------------------------------------------------------------------
-- Return statuses to be upated
------------------------------------------------------------------------------
SELECT	@ErrorCode	= 1,
		@ErrorMessage = 'Success'
SELECT	Type,
		Id,
		StatusId,
		StatusDesc
FROM	@StatusToUpdate
 

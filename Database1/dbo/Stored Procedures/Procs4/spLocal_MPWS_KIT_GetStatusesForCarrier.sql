 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KIT_GetStatusesForCarrier
	
	Calculate the status of kits, and POs on the carrier.
	
	Date			Version		Build	Author  
	20-05-2017		001			001		Susan Lee (GE Digital)		Initial development	
    10-10-2017      001         002     Susan Lee (GE Digital)      Check for other carriers that carry the same PO
	23-10-2017		001			003		Susan Lee (GE Digital)		Check for other status of carriers carrying the same PO

DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(255)
EXEC dbo.spLocal_MPWS_KIT_GetStatusesForCarrier @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 187166
--EXEC dbo.spLocal_MPWS_KIT_GetStatusesForCarrier @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 187168
--EXEC dbo.spLocal_MPWS_KIT_GetStatusesForCarrier @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 187170
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_KIT_GetStatusesForCarrier]
	@ErrorCode			INT				OUTPUT,		-- Flag to indicate Success or Failure (1-Success,0-Failure)
	@ErrorMessage		VARCHAR(255)	OUTPUT,		-- Error Message to Write to Log File
	@CarrierEventId		INT							-- the Event_Id of the carrier to get the status of
	
AS

--Test
--DECLARE
--	@ErrorCode			INT				,		-- Flag to indicate Success or Failure (1-Success,0-Failure)
--	@ErrorMessage		VARCHAR(255)	,		-- Error Message to Write to Log File
--	@CarrierEventId		INT		= 	187166				-- the Event_Id of the carrier to get the status of

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
 
DECLARE @KitsInSelectedCarrier TABLE
(
	KitEventId		INT,
	KitStatusDesc	VARCHAR(50),
	KitStatusId		INT,
	KitPPId			INT,
	OtherCarriers	INT,
	OtherCarStats	INT
);
 
DECLARE @CarriersContainingTheKits TABLE
(
	KitEventId		INT,
	CarrierId		INT,
	StatusDesc		VARCHAR(50),
	StatusId		INT
);
 
DECLARE @CarriersContainingThePOs TABLE
(
	PPId				INT,
	PPStatusId			INT,
	CarrierId			INT,
	CarrierStatusDesc	VARCHAR(50),
	CarrierStatusId		INT,
	OtherCarStats		INT
);
 
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
INSERT @KitsInSelectedCarrier (KitEventId, KitStatusDesc, KitStatusId, KitPPId, OtherCarriers,OtherCarStats)
	SELECT
		k.Event_Id, ps.ProdStatus_Desc, ps.ProdStatus_Id, ed.PP_Id, 0, 0
	FROM dbo.events c 
		JOIN dbo.Prod_Units_Base cpu ON cpu.PU_Id = c.PU_Id 
			AND cpu.Equipment_Type = 'carrier'
		JOIN dbo.Event_Components c_cs ON c_cs.Source_Event_Id = c.Event_Id
		JOIN dbo.Events cs ON cs.Event_Id = c_cs.Event_Id
		JOIN dbo.Event_Components cs_k ON cs_k.Event_Id = cs.event_id
		JOIN dbo.Events k ON k.Event_Id = cs_k.Source_Event_Id
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Id = k.Event_Status
		JOIN dbo.Event_Details ed ON ed.Event_Id = k.Event_Id
		JOIN dbo.Prod_Units_Base kpu ON kpu.PU_Id = k.PU_Id 
			AND kpu.Equipment_Type = 'kitting station'
	WHERE c.Event_Id = @CarrierEventId

------------------------------------------------------------------------------
-- Get Kits
------------------------------------------------------------------------------
 
------------------------------------------------------------------------------
-- Get all carrier status on each kit... if all carriers in the kit are RFP 
-- or Staged, update the kit to RFP or Staged.
------------------------------------------------------------------------------
INSERT @CarriersContainingTheKits (KitEventId, CarrierId, StatusDesc, StatusId)
	SELECT distinct	
		kt.KitEventId, c.Event_Id, ps.ProdStatus_Desc, ps.ProdStatus_Id
	FROM dbo.Events c 
		JOIN dbo.Prod_Units_Base cpu ON cpu.PU_Id = c.PU_Id 
			AND cpu.Equipment_Type = 'carrier'
		JOIN dbo.event_Components c_cs ON c_cs.Source_Event_Id = c.Event_Id
		JOIN dbo.Events cs ON cs.event_id = c_cs.Event_Id
		JOIN dbo.Event_Components cs_k	ON cs_k.Event_Id = cs.Event_Id
		JOIN dbo.Events k ON k.Event_Id = cs_k.Source_Event_Id
		join dbo.Prod_Units_Base kpu ON kpu.PU_Id = k.PU_Id 
			AND kpu.Equipment_Type = 'kitting station'
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Id = c.Event_Status 
			AND ps.ProdStatus_Desc NOT IN ('Returned')
		JOIN @KitsInSelectedCarrier kt ON kt.KitEventId = k.Event_Id

-- get count of other carriers kits are in. if only in selected, count will = 0
;WITH a AS
(
	SELECT
		k.KitEventId,
		COUNT(CarrierId) CarCount 
	FROM @KitsInSelectedCarrier k
		JOIN @CarriersContainingTheKits c ON c.KitEventId = k.KitEventId
	WHERE c.CarrierId <> @CarrierEventId
	GROUP BY k.KitEventId
)
UPDATE k
	SET OtherCarriers = CarCount
	FROM @KitsInSelectedCarrier k
		JOIN a ON a.KitEventId = k.KitEventId;
 
-- find out if other carriers are not in Staged or RFP (or Returned). if there are, count will be > 0
;WITH a AS
(
	SELECT
		k.KitEventId,
		COUNT(CarrierId) CarCount 
	FROM @KitsInSelectedCarrier k
		JOIN @CarriersContainingTheKits c ON c.KitEventId = k.KitEventId
	WHERE StatusDesc <> @CarrierStatusDesc 
	GROUP BY k.KitEventId
)
UPDATE k
	SET OtherCarStats = CarCount
	FROM @KitsInSelectedCarrier k
		JOIN a ON a.KitEventId = k.KitEventId;
 
-- remove kits that are in other carriers that have non- Staged/RFP status
DELETE @KitsInSelectedCarrier
	WHERE OtherCarStats > 0;
 
-- now we only have kits that can change, delete kits that are already at carrier's status
DELETE @KitsInSelectedCarrier
	WHERE KitStatusDesc = @CarrierStatusDesc;
 
-- what's left are kits that need updating
INSERT @StatusToUpdate ([Type], Id, StatusId, StatusDesc)
	SELECT
		'EVENT',
		KitEventId,
		@CarrierStatusId,
		@CarrierStatusDesc
	FROM @KitsInSelectedCarrier

 
------------------------------------------------------------------------------
-- Get POs
------------------------------------------------------------------------------
 
------------------------------------------------------------------------------
-- We have all the kits in the selected carrier that have a status change, which means we have all the PO's 
-- BUT, these PO's can be in different kits spread across different carriers
-- so we need to go find all those carriers
------------------------------------------------------------------------------
INSERT @CarriersContainingThePOs (PPId, PPStatusId, CarrierId, CarrierStatusDesc, 
CarrierStatusId)
	SELECT distinct	
		ked.PP_Id, pp.pp_status_id, c.Event_Id, ps.ProdStatus_Desc, ps.ProdStatus_Id
	FROM dbo.Events c 
		JOIN dbo.Prod_Units_Base cpu ON cpu.PU_Id = c.PU_Id 
			AND cpu.Equipment_Type = 'carrier'
		JOIN dbo.event_Components c_cs ON c_cs.Source_Event_Id = c.Event_Id
		JOIN dbo.Events cs ON cs.event_id = c_cs.Event_Id
		JOIN dbo.Event_Components cs_k	ON cs_k.Event_Id = cs.Event_Id
		JOIN dbo.Events k ON k.Event_Id = cs_k.Source_Event_Id
		JOIN dbo.Event_Details ked ON ked.Event_Id = k.Event_Id
		JOIN dbo.production_plan pp ON pp.pp_id = ked.pp_id
		JOIN dbo.Prod_Units_Base kpu ON kpu.PU_Id = k.PU_Id 
			AND kpu.Equipment_Type = 'kitting station'
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Id = c.Event_Status 
			AND ps.ProdStatus_Desc NOT IN ('Returned')
		JOIN @KitsInSelectedCarrier kt ON kt.KitPPId = ked.PP_Id

;WITH a AS
(
	SELECT
		PPId,
		COUNT(CarrierId) CarCount 
	FROM @CarriersContainingThePOs c
	WHERE CarrierStatusDesc <> @CarrierStatusDesc 
	GROUP BY PPId
)
UPDATE c
	SET OtherCarStats = CarCount
	FROM @CarriersContainingThePOs c
	JOIN a ON a.PPId = c.PPId;

-- remove carriers that have POs in other carriers that have non- Staged/RFP status
DELETE @CarriersContainingThePOs
	WHERE OtherCarStats > 0;

-- remove carriers where the PO status is not in 'Kitted','Ready For Production','Staged'
DELETE c
FROM	@CarriersContainingThePOs c
JOIN	dbo.production_plan_statuses pps ON pps.pp_status_id = c.PPStatusId
WHERE	pps.PP_Status_Desc NOT IN ('Kitted','Ready For Production','Staged')
	 
-- what's left are POs that need updating
INSERT @StatusToUpdate ([Type], Id, StatusId, StatusDesc)
	SELECT DISTINCT
		'PO',
		PPId,
		@MatchingPPStatusId,
		@CarrierStatusDesc
	FROM @CarriersContainingThePOs
 
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
 

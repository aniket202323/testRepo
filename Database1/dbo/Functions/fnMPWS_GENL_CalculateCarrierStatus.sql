 
 
 
create FUNCTION [dbo].[fnMPWS_GENL_CalculateCarrierStatus]
(
	@CarrierEventId		INT
)
RETURNS   INT
AS
-------------------------------------------------------------------------------
-- Figure out the Carrier status
--
/*

DECLARE	@CarrierStatusId INT, @CarrierEventId INT = 155083
SELECT	@CarrierStatusId = 	dbo.fnMPWS_GENL_CalculateCarrierStatus(@CarrierEventId)

SELECT
	pps.ProdStatus_Desc
FROM dbo.Production_Status pps
WHERE pps.ProdStatus_Id = @CarrierStatusId

*/
-- Date         Version Build Author  
-- 24-Oct-2017  001     001   Jim Cameron (GE Digital)  Initial development	
--
-------------------------------------------------------------------------------
BEGIN

	------------------------------------------------------------------------------
	-- Declare Variables
	------------------------------------------------------------------------------

	DECLARE
		@NewCarrierStatusId			INT,
		@POStatusId					INT,
		@POStatus					VARCHAR(50),
		@DispCount					INT,
		@KitStatusId				INT,
		@KitStatus					VARCHAR(50),
		@CurrentCarrierStatusId		INT,
		@CurrentCarrierStatus		VARCHAR(50);

	DECLARE @Carrier TABLE
	(
		CarStatusId		INT,
		CarStatus		VARCHAR(50),
		KitStatusId		INT,
		KitStatus		VARCHAR(50),
		POStatus		VARCHAR(50),
		DispCount		INT
	);

	------------------------------------------------------------------------------
	-- Initialize variables
	------------------------------------------------------------------------------
	INSERT @Carrier (CarStatusId, CarStatus, POStatus)
		SELECT
			--eCar.Event_Id CarEventId,			-- these commented out fields left in for debugging
			--eCar.Event_Num CarEventNum,
			psCar.ProdStatus_Id CarStatusId,
			psCar.ProdStatus_Desc CarStatus,
			--eKit.Event_Id KitEventId,
			--eKit.Event_Num KitEventNum,
			--psKit.ProdStatus_Id KitStatusId,
			--psKit.ProdStatus_Desc KitStatus,
			--ppPO.PP_Id PPId,
			--ppPO.Process_Order PO,
			--pps.PP_Status_Id POStatusId,
			pps.PP_Status_Desc POStatus
			--COUNT(eDisp.Event_Id) DispCount
		FROM dbo.Event_Components ecCSecToCar
			
			-- carrier
			JOIN dbo.Events eCar ON eCar.Event_Id = ecCSecToCar.Source_Event_Id
			JOIN dbo.Prod_Units_Base puCar ON puCar.PU_Id = eCar.PU_Id
				AND puCar.Equipment_Type = 'Carrier'
			JOIN dbo.Event_Details edCar ON edCar.Event_Id = eCar.Event_Id
			JOIN dbo.Production_Status psCar ON psCar.ProdStatus_Id = eCar.Event_Status
		
			-- carrier section
			JOIN dbo.Events eCSec ON eCSec.Event_Id = ecCSecToCar.Event_Id
			JOIN dbo.Prod_Units_Base puCSec ON puCSec.PU_Id = eCSec.PU_Id
				AND puCSec.Equipment_Type = 'Carrier Section'

			-- kit
			JOIN dbo.Event_Components ecCSecToKit ON ecCSecToKit.Event_Id = eCSec.Event_Id
			JOIN dbo.Events eKit ON eKit.Event_Id = ecCSecToKit.Source_Event_Id
			JOIN dbo.Prod_Units_Base puKit ON puKit.PU_Id = eKit.PU_Id
				AND puKit.Equipment_Type = 'Kitting Station'
			JOIN dbo.Event_Details edKit ON edKit.Event_Id = eKit.Event_Id
			JOIN dbo.Production_Status psKit ON psKit.ProdStatus_Id = eKit.Event_Status

			-- po
			JOIN dbo.Production_Plan ppPO ON ppPO.PP_Id = edKit.PP_Id
			JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = ppPO.PP_Status_Id

			-- dispense
			JOIN dbo.Event_Components ecCSecToDisp ON ecCSecToDisp.Event_Id = eCSec.Event_Id
			JOIN dbo.Events eDisp ON eDisp.Event_Id = ecCSecToDisp.Source_Event_Id		
			JOIN dbo.Prod_Units_Base puDisp ON puDisp.PU_Id = eDisp.PU_Id
				AND puDisp.Equipment_Type = 'Dispense Station'

		WHERE eCar.Event_Id = @CarrierEventId

		GROUP BY --eCar.Event_Id, eCar.Event_Num, 
			psCar.ProdStatus_Id, psCar.ProdStatus_Desc, 
			--eKit.Event_Id, eKit.Event_Num, 
			--psKit.ProdStatus_Id, psKit.ProdStatus_Desc, 
			--ppPO.PP_Id, ppPO.Process_Order, pps.PP_Status_Id, 
			pps.PP_Status_Desc

	-- find minimum po status
	;WITH s AS
	(
		SELECT
			a.b StatusOrder,
			a.c StatusDesc
		FROM (VALUES (1, 'Pending'), (2, 'Released'), (3, 'Dispensing'), (4, 'Dispensed'), (5, 'Kitting'), (6, 'Kitted'), (7, 'Ready for production'), (8, 'staged'), (9, 'complete')) a(b, c)
	)
	, c AS
	(
		SELECT
			MIN(s.StatusOrder) MinPOStatus
		FROM @Carrier c
			JOIN s ON s.StatusDesc = c.POStatus
	)
	, c2 AS
	(
		SELECT
			s.StatusDesc
		FROM s
			JOIN c ON c.MinPOStatus = s.StatusOrder
	)
	SELECT
		@NewCarrierStatusId = ps.ProdStatus_Id
	FROM dbo.Production_Status ps
		JOIN c2 ON c2.StatusDesc = ps.ProdStatus_Desc;

	RETURN @NewCarrierStatusId;

END
 
 

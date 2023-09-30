
 
 
 
CREATE FUNCTION [dbo].[fnMPWS_GENL_CalculateKitStatus]
(
	@KitEventId		INT
)
RETURNS   INT
--WITH ENCRYPTION
AS
-------------------------------------------------------------------------------
-- Figure out the Kit status
--
/*

DECLARE	@KitStatusId INT, @KitEventId INT = 155083
SELECT	@KitStatusId = 	dbo.fnMPWS_GENL_CalculateKitStatus(@KitEventId)

SELECT
	pps.ProdStatus_Desc
FROM dbo.Production_Status pps
WHERE pps.ProdStatus_Id = @KitStatusId

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
		@NewKitStatusId		INT,
		@POStatusId			INT,
		@POStatus			VARCHAR(50),
		@DispCount			INT,
		@CurrentKitStatusId	INT;

	------------------------------------------------------------------------------
	-- Initialize variables
	------------------------------------------------------------------------------

	-- get the kit, it's PO Status and number of Dispenses. GROUP BY should return only 1 row but use TOP 1 just in case.
	SELECT TOP 1
		@CurrentKitStatusId = eKit.Event_Status,
		@POStatusId = pps.PP_Status_Id,
		@POStatus = pps.PP_Status_Desc,
		@DispCount = COUNT(eDisp.Event_Num)
	FROM dbo.Event_Components ecKitToDisp		-- genealogy links, kit to dispense

		-- kit data
		JOIN dbo.Events eKit ON eKit.Event_Id = ecKitToDisp.Event_Id					
		JOIN dbo.Prod_Units_Base puKit ON puKit.PU_Id = eKit.PU_Id
			AND puKit.Equipment_Type = 'Kitting Station'
		JOIN dbo.Event_Details edKit ON edKit.Event_Id = eKit.Event_Id
		
		-- po data
		JOIN dbo.Production_Plan ppPO ON ppPO.PP_Id = edKit.PP_Id						
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = ppPO.PP_Status_Id
		
		-- dispense data
		LEFT JOIN dbo.Events eDisp ON eDisp.Event_Id = ecKitToDisp.Source_Event_Id		
		LEFT JOIN dbo.Prod_Units_Base puDisp ON puDisp.PU_Id = eDisp.PU_Id
			AND puDisp.Equipment_Type = 'Dispense Station'
	WHERE eKit.Event_Id = @KitEventId
	GROUP BY eKit.Event_Status, pps.PP_Status_Id, pps.PP_Status_Desc
		
	IF @POStatus IN ('Pending', 'Released', 'Dispensing', 'Dispensed')
	BEGIN
			
		IF @DispCount = 0
		BEGIN

			SELECT
				@NewKitStatusId = ps.ProdStatus_Id
			FROM dbo.Production_Status ps
			WHERE ps.ProdStatus_Desc = 'Created';

		END
		ELSE
		BEGIN

			SELECT
				@NewKitStatusId = ps.ProdStatus_Id
			FROM dbo.Production_Status ps
			WHERE ps.ProdStatus_Desc = 'Kitting';

		END

	END
	ELSE IF @POStatus IN ('Kitted', 'Ready for production', 'Staged', 'Complete')
	BEGIN

		-- need to translate po pplan status id to equivalent kit event status id
		SELECT
			@NewKitStatusId = ps.ProdStatus_Id
		FROM dbo.Production_Status ps
			JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Desc = ps.ProdStatus_Desc
		WHERE ps.ProdStatus_Desc = pps.PP_Status_Desc
			AND pps.PP_Status_Id = @POStatusId;

	END
	ELSE
	BEGIN

		-- if po status is not one of the above checks, just return the existing kit status
		SET @NewKitStatusId = @CurrentKitStatusId;

	END;

	RETURN @NewKitStatusId;

END
 
 


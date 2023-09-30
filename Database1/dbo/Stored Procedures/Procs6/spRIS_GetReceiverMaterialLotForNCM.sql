/*
	Copyright (c) 2020 GE Digital. All Rights Reserved.
	=============================================================================

	=============================================================================
	Author				212517152, Rabindra Kumar
	Create On			09-APRIL-2020
	Last Modified		09-APRIL-2020
	Description			Returns Production Events.
	Procedure_name		[spRIS_GetReceiverMaterialLotForNCM]

	================================================================================
	Input Parameter:
	=================================================================================
	@receiver_number                --NVARCHAR--		    Optional input paramater
	
	================================================================================
	Result Set:- 1
	=================================================================================
	--Event_Id
	--Evvent_Num
	--Pu_Id
*/


CREATE PROCEDURE [dbo].[spRIS_GetReceiverMaterialLotForNCM]
         @receiver_number                NVARCHAR(50) = NULL
AS
BEGIN
		SET NOCOUNT ON

		DECLARE @tempEvent TABLE(
			Event_Id INT NULL
			,Event_Num NVARCHAR(50) NULL
			,Pu_Id INT NULL
		)

		INSERT INTO @tempEvent
		SELECT TOP 1
				receiver.EVENT_ID
				,receiver.Event_Num
				,receiver.Pu_Id
		FROM [dbo].[Events] receiver    
				JOIN [dbo].[Event_Components] EC	ON EC.Source_Event_Id = receiver.event_id    
				JOIN [dbo].[Events] CH_LOTS			ON EC.Event_id = CH_LOTS.Event_Id AND CH_LOTS.event_num = CH_LOTS.Lot_Identifier 
		WHERE 
			receiver.EVENT_NUM = @receiver_number

		INSERT INTO @tempEvent
		SELECT 
				CH_LOTS.EVENT_ID Event_Id
				,CH_LOTS.Event_Num
				,CH_LOTS.Pu_Id
		FROM [dbo].[Events] receiver    
				JOIN [dbo].[Event_Components] EC	ON EC.Source_Event_Id = receiver.event_id    
				JOIN [dbo].[Events] CH_LOTS			ON EC.Event_id = CH_LOTS.Event_Id AND CH_LOTS.event_num = CH_LOTS.Lot_Identifier 
		WHERE 
			receiver.EVENT_NUM = @receiver_number

		IF NOT EXISTS(SELECT 1 FROM @tempEvent)
		BEGIN
			INSERT INTO @tempEvent
				SELECT TOP 1 
					E.EVENT_ID
					,E.Event_Num
					,E.Pu_Id
			FROM [dbo].[Events] E    
		WHERE 
			E.EVENT_NUM = @receiver_number
		END

		SELECT * FROM @tempEvent

	
		--DECLARE @receiver_event_id INT
		--SET @receiver_event_id = (SELECT TOP 1 E.Event_Id FROM [dbo].[Events] E WHERE E.Event_Num = @receiver_number) 
		
		--SELECT 
		--	E.Event_Id, E.Event_Num, E.Pu_Id
		--FROM
		--	 [dbo].[Events] E
		--WHERE
		--	E.Event_Id = @receiver_event_id 
		--	OR (E.Event_Id IN (SELECT Event_Id FROM [Event_Components] WHERE Source_Event_Id = @receiver_event_id))
		--	AND (E.Event_Num = E.Lot_Identifier))
 

END
GRANT EXECUTE ON [dbo].[spRIS_GetReceiverMaterialLotForNCM] TO [ComXClient]
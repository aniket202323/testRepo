
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE 	PROCEDURE [dbo].[spLocal_PCMT_Get_EventType]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_EventType
											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Rick Perreault, Solutions et Technologies Industrielles inc.
Date ALTERd	:	13-Nov-2002	
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp return the possible event type for PCMT.
						PCMT Version 2.1.0 and 3.0.0
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-05-17
Version		:	1.2.0
Purpose		: 	Now also returns the user-defined event
-------------------------------------------------------------------------------------------------
Updated By	:	Jonathan Corriveau (System Technologies for Industry Inc)
Date			:	2008-12-23
Version		:	1.3.0
Purpose		: 	Now returns all event types the proficy administrator shows
-------------------------------------------------------------------------------------------------
Updated By	:	Alberto Ledesma (System Technologies for Industry Inc)
Date		:	2010-09-17
Version		:	1.3.0
Purpose		: 	Now returns only the event types that are configureted on the selected production unit
-------------------------------------------------------------------------------------------------
*/


@intVarId			INT,
@Band				INT

AS
SET NOCOUNT ON

Declare 
@ctrlEvent			INT


--SELECT et_id, et_desc
--FROM dbo.Event_Types
--WHERE et_desc IN ('Time', 'Production Event', 'Downtime', 'Waste', 'Product Change', 'Product/Time', 'User-Defined Event', 'Process Order', 'Uptime', 'Process Order/Time')

IF @BAND=0 
	BEGIN
		SELECT @ctrlEvent = COUNT(EC.ET_id)
		FROM variables v
			JOIN event_configuration EC ON EC.PU_id = v.PU_id
		WHERE var_id=@intVarId

		IF @ctrlEvent = 0 
			BEGIN
				SELECT et_id, et_desc
				FROM dbo.Event_Types e
					JOIN variables v ON v.Event_Type = e.et_id
				WHERE var_id=@intVarId				
			END	
		ELSE
			BEGIN
				SELECT et_id, et_desc
				FROM dbo.Event_Types
				WHERE et_id IN (	
									SELECT distinct EC.ET_id
									FROM variables v
										JOIN event_configuration EC ON EC.PU_id = v.PU_id
									WHERE var_id=@intVarId
								)
			END
	END
ELSE
	BEGIN
		SELECT et_id, et_desc
		FROM dbo.Event_Types
	END


SET NOCOUNT OFF


-------------------------------------------------------------------------------------------------



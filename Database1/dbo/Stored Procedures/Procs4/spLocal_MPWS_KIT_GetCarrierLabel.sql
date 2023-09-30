 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetCarrierLabel]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@CarrierEventId	INT
AS	
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get the lable Info for the Carrier (Event ID) Passed in
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetCarrierLabel @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 5739184
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 08-JUN-2016	001		001		Chris Donnelly (GE Digital)  Initial development	
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	CarrierSectionEvent_Id	INT					NULL,
	CarrierSection			VARCHAR(50)			NULL,
	[Level]					VARCHAR(1)			NULL,
	[Row]					INT					NULL,
	Section					INT					NULL,
	Kit						VARCHAR(50)			NULL
)
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
-------------------------------------------------------------------------------
-- Get carrier section events
-------------------------------------------------------------------------------
INSERT INTO @tOutput
(CarrierSectionEvent_Id, CarrierSection,[Level],[Row],Section,Kit)
	SELECT cse.Event_Id as CarrierSectionEvent_Id, cse.Event_Num,CHARINDEX (LEFT(RIGHT(cse.Event_Num,3),1),'ABCDEFGHIJKL') as [Level], LEFT(RIGHT(cse.Event_Num,2),1),RIGHT(cse.Event_Num,1), NULL as Kit
	FROM dbo.[Events] ce
		JOIN dbo.Event_Components ec on ec.Source_Event_Id = ce.Event_Id	--G-Link Carrier to Carrier Section
		JOIN dbo.[Events] cse ON cse.Event_Id = ec.Event_Id					--Carrier Section
		--LEFT JOIN dbo.Event_Components kec on kec.Event_Id = cse.Event_Id	--G-Link Carrier Section to Kit
		--LEFT JOIN dbo.[Events] ke ON ke.Event_Id = kec.Source_Event_Id		--Kit
		--LEFT JOIN dbo.Prod_Units_Base p on p.PU_Id = ke.PU_Id AND p.PU_Desc LIKE '%Kit%'
	WHERE 
		ce.Event_Id = @CarrierEventId
 
--Get Kits when assigned
UPDATE t
	SET t.Kit = ke.Event_Num
		--(
		--	SELECT 
		--		ke.Event_Num as Kit
			FROM 
				@tOutput t
				JOIN dbo.Event_Components kec on kec.Event_Id = t.CarrierSectionEvent_Id	--G-Link Carrier Section to Kit
				JOIN dbo.[Events] ke ON ke.Event_Id = kec.Source_Event_Id	--Kit
				JOIN dbo.Prod_Units_Base p on p.PU_Id = ke.PU_Id AND p.PU_Desc LIKE '%Kit%'
			--WHERE t.CarrierSectionEvent_Id = tout.CarrierSectionEvent_Id
		--)
 
------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT	CarrierSection	CarrierSection,
		[Level]			[Level],
		[Row]			Row,
		Section			Section,	
		Kit				Kit
	FROM @tOutput 
 
 
 
 
 

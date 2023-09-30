 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetCarrierSectionLabel]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@CarrierSectionId	VARCHAR(255)
AS	
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get the lable Info for the Carrier (Event ID) Passed in
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetCarrierSectionLabel @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'ca20170818_001_a11'
select @ErrorCode, @ErrorMessage
 
select * from dbo.events where event_num = 'ca20170122_004'
select * from dbo.production_status where prodstatus_id = 58
select * from dbo.prod_units_Base where pu_id = 4310*/
-- Date         Version Build Author  
-- 15-JUL-2016	001		001		Avinash Munagala (GE Digital)  Initial development	
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
 
--INSERT dbo.Local_Debug ([Timestamp],[CallingSP],[Message],[Msg])
--VALUES (GETDATE(), 'spLocal_MPWS_KIT_GetCarrierSectionLabel', @CarrierSectionId, 'Carrier Section Id');
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	CarrierSectionEvent_Id	INT					NULL,
	CarrierSection			VARCHAR(50)			NULL,
	[Level]					VARCHAR(1)			NULL,
	[Row]					INT					NULL,
	Section					INT					NULL,
	Kit						VARCHAR(50)			NULL,
	KitEventId				INT					NULL,
	PONum					VARCHAR(50)			NULL,
	ProductionLine		    VARCHAR(50)			NULL
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
	SELECT DISTINCT cse.Event_Id as CarrierSectionEvent_Id, cse.Event_Num,LEFT(RIGHT(cse.Event_Num,3),1) as [Level], LEFT(RIGHT(cse.Event_Num,2),1),RIGHT(cse.Event_Num,1), NULL as Kit
	FROM dbo.[Events] ce
		JOIN dbo.Event_Components ec on ec.Source_Event_Id = ce.Event_Id	--G-Link Carrier to Carrier Section
		JOIN dbo.[Events] cse ON cse.Event_Id = ec.Event_Id					--Carrier Section
		--LEFT JOIN dbo.Event_Components kec on kec.Event_Id = cse.Event_Id	--G-Link Carrier Section to Kit
		--LEFT JOIN dbo.[Events] ke ON ke.Event_Id = kec.Source_Event_Id		--Kit
		--LEFT JOIN dbo.Prod_Units_Base p on p.PU_Id = ke.PU_Id AND p.PU_Desc LIKE '%Kit%'
	WHERE 
		cse.Event_Num = @CarrierSectionId
 
--Get Kits when assigned
UPDATE t
	SET t.Kit = ke.Event_Num,t.PONum = pp.Process_Order,t.KitEventId = ke.Event_Id, t.ProductionLine = info.ProdLineDesc --		t.ProductionLine = pl.PL_Desc
		--(
		--	SELECT 
		--		ke.Event_Num as Kit
			FROM 
				@tOutput t
				JOIN dbo.Event_Components kec on kec.Event_Id = t.CarrierSectionEvent_Id	--G-Link Carrier Section to Kit
				JOIN dbo.[Events] ke ON ke.Event_Id = kec.Source_Event_Id	--Kit
				JOIN dbo.[Event_Details] ked ON ked.Event_Id = ke.Event_Id
				JOIN dbo.Production_Plan pp on pp.PP_Id = ked.PP_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(pp.PP_Id) info
				JOIN dbo.Prod_Units_Base p on p.PU_Id = ke.PU_Id AND p.PU_Desc LIKE '%Kit%'
				--JOIN dbo.Prod_Lines_Base pl on pl.PL_id = p.pl_id 
			--WHERE t.CarrierSectionEvent_Id = tout.CarrierSectionEvent_Id
		--)
 
------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT	CarrierSectionEvent_Id CarrierSectionEventId,
        CarrierSection	CarrierSection,
		[Level]			[Level],
		[Row]			Row,
		Section			Section,	
		Kit				Kit,
		KitEventId      KitEventId,
		PONum			PONum,
		ProductionLine	ProductionLine
	FROM @tOutput 
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_KIT_GetCarrierLabel] TO [public]
 
 
 




--------------------------------------------------------------------------------------------------
-- Local Function: fnLocal_CTS_Location_Movements
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-11-05
-- Version 				:	1.0
-- Description			:	For testing purposes
--							The purpose of this function is to retreive movements to and from locations
--							
-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-10-05		F.Bergeron				Initial Release 



--------------------------------------------------------------------------------------------------
--Testing Code
--------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fnLocal_CTS_Location_Movements] 
(
	@LocationId 				INTEGER,
	@Start_time					DATETIME = NULL,
	@End_time					DATETIME = NULL
)
RETURNS @Output TABLE 
(
	LocationId							INTEGER,
	LocationStatus						VARCHAR(25),
	ApplianceId							INTEGER,
	ApplianceSerial						VARCHAR(25),
	ApplianceType						VARCHAR(25),
	ApplianceStatus						VARCHAR(25),
	ApplianceProcessOrderId				INTEGER,
	ApplianceProcessOrder				VARCHAR(50),
	ApplianceProductId					INTEGER,
	ApplianceProductCode				VARCHAR(50),
	ApplianceProductDesc				VARCHAR(50),
	MovementDirection					VARCHAR(10),
	MovementTime						DATETIME,
	FromLocationId						INTEGER,
	FromLocationDesc					VARCHAR(50),
	FromLocationProcessOrderId			INTEGER,
	FromLocationProcessOrder			VARCHAR(50),
	FromLocationProcessOrderProductId	INTEGER,
	FromLocationProcessOrderProductCode	VARCHAR(50),
	FromLocationProcessOrderProductDesc	VARCHAR(50),
	ToLocationId						INTEGER,
	ToLocationDesc						VARCHAR(50),
	ToLocationProcessOrderId			INTEGER,
	ToLocationProcessOrder				VARCHAR(50),
	ToLocationProcessOrderProductId		INTEGER,
	ToLocationProcessOrderProductCode	VARCHAR(50),
	ToLocationProcessOrderProductDesc	VARCHAR(50)
)
					
AS
BEGIN
--------------------------------------------------------------------------------------------------
--GET INBOUND MOVEMENTS
--------------------------------------------------------------------------------------------------
INSERT INTO @Output
(
LocationId,
ApplianceId,
ApplianceSerial,
MovementDirection,
MovementTime
)
SELECT 
		@LocationId,
		EC.source_event_Id,
		EDA.alternate_event_num,
		'INBOUND',
		EC.timestamp
FROM	dbo.event_components EC WITH(NOLOCK)
		JOIN dbo.events EI WITH(NOLOCK) 	 -- INBOUND
			ON EC.event_id = EI.event_id 
			AND EI.pu_id = @LocationId
		JOIN dbo.event_details EDA
			ON EDA.event_id = EC.source_event_id
WHERE	EI.pu_id = @LocationId		 

--------------------------------------------------------------------------------------------------
--GET INBOUND MOVEMENTS SOURCE LOCATION
--------------------------------------------------------------------------------------------------

UPDATE	@Output
SET		FromLocationId = Q.pu_id,
		FromLocationDesc = Q.pu_desc,
		FromLocationProcessOrderId = Q.PP_Id,
		FromLocationProcessOrder = Q.process_order,
		FromLocationProcessOrderProductId = Q.prod_id,
		FromLocationProcessOrderProductCode = Q.prod_Code,
		FromLocationProcessOrderProductDesc = Q.prod_desc
FROM	@output O
		OUTER APPLY (
		SELECT 
		TOP 1	EI.pu_id, PUB.pu_desc, PP.PP_id, PP.process_order,PP.prod_id , PB.prod_code, PB.prod_desc
		FROM	dbo.event_components EC WITH(NOLOCK)
				JOIN dbo.events EI WITH(NOLOCK) 	 -- INBOUND
					ON EC.event_id = EI.event_id 
					AND EI.pu_id = @LocationId
				JOIN dbo.prod_units_base PUB WITH(NOLOCK)
					ON PUB.pu_id = EI.pu_id
				LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK)
					ON EI.pu_id = PPS.pu_id
					AND EC.timestamp > PPS.start_time 
					AND (EC.timestamp < PPS.end_time OR PPS.end_time IS NULL)
				LEFT JOIN dbo.production_plan PP WITH(NOLOCK) 
					ON PP.PP_Id = PPS.PP_Id
				LEFT JOIN dbo.products_base PB
					ON PB.prod_id = PP.prod_id
		WHERE	EI.pu_id = @LocationId	
				AND EC.timestamp < O.MovementTime 
		ORDER 
		BY		EC.timestamp DESC
	
		) Q



	RETURN
END

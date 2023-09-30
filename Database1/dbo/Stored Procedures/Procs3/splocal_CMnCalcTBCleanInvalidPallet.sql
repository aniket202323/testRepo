

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnCalcEBFirPreviousPallet
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre
-- Date created			: 16-Jun-2016
-- Version 				: Version <1.0>
-- SP Type				: PA Calculation
-- Caller				: Called time based
-- Description			: make Unused pallet consumed
--						 
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
/*

DECLARE @OutputValue varchar(25)
EXEC [splocal_CMnCalcTBCleanInvalidPallet] @OutputValue OUTPUT, 2068,'16-Feb-2016 13:00', 'B050'
SELECT @OutputValue

*/
-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[splocal_CMnCalcTBCleanInvalidPallet]
		@OutputValue				varchar(25) OUTPUT,
		@PUId						int,
		@Timestamp					datetime,
		@OG							varchar(10)


AS
DECLARE 
@LoopBackTime		datetime

DECLARE @PalletToConsume	TABLE (
eventid			int,
eventNum		varchar(50),
prodcode		varchar(50),
prodId			int, 
OG				varchar(10)
)

SET @LoopBackTime = DATEADD(DD,-1,@Timestamp)

INSERT @PalletToConsume (eventid,eventNum,prodcode,prodId, og)
SELECT 
e.event_id, 			
CASE CHARINDEX('_',e.Event_Num,0)
	WHEN 0 THEN e.Event_Num
	ELSE COALESCE(LEFT(e.Event_Num,CHARINDEX('_',e.Event_Num,0)-1),e.Event_Num)
END	, 
p.prod_code, p.prod_id, CONVERT(varchar(30),pmm.value)
FROM dbo.events	e										WITH(NOLOCK)
JOIN dbo.products p										WITH(NOLOCK) ON e.applied_product = p.prod_id
JOIN dbo.production_status ps							WITH(NOLOCK) ON e.event_status = ps.prodStatus_Id
JOIN dbo.Products_Aspect_MaterialDefinition	asp			WITH(NOLOCK) ON e.applied_product = asp.Prod_Id
JOIN dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK) ON asp.Origin1MaterialDefinitionId = pmm.MaterialDefinitionId
WHERE	e.pu_id = @PUId 
	AND e.timestamp > @LoopBackTime
	AND ps.ProdStatus_Desc !='Consumed'  AND ps.ProdStatus_Desc !='Returned' 
	AND pmm.Name = 'Origin Group'
	AND pmm.value = @OG


DELETE FROM @PalletToConsume WHERE LEN(eventnum) > 16

SELECT @OutputValue = COUNT(1) FROM @PalletToConsume

IF @OutputValue > 0
BEGIN
	--update the pallet matching issue
	UPDATE e
	SET event_status = 8
	FROM dbo.events e
	JOIN @PalletToConsume pc ON e.event_id = pc.eventid
END




CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulateProduction]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@varidProductionTotal		int,
		@varidProductionReject		int,
		@puidSource					int





AS
SET NOCOUNT ON

DECLARE	@ProductionTotal			int,
		@ProductionReject			int,
		@puid						int,
		@eventId					int,
		@TestId						bigint,
		@UpdateType					int




		
--Get the production unit
SET @puid		= (SELECT pu_id FROM dbo.variables_base WITH(NOLOCK) WHERE var_id = @varidProductionTotal)

--Get the pu_id
SET @EventId	= (SELECT event_id FROM dbo.events WITH(NOLOCK) WHERE pu_id = @puid AND timestamp = @ThisTime)

--get production
SET @ProductionTotal = (	SELECT COALESCE(SUM(dimension_x),0)
								FROM dbo.event_components ec	WITH(NOLOCK)
								JOIN dbo.events e				WITH(NOLOCK)	ON ec.source_event_id = e.event_id
								WHERE ec.event_id = @EventId
									AND e.pu_id = @puidSource )


SET @ProductionReject = ROUND(@ProductionTotal* 2/100,0)

--Push result sets
SET @TestId		=		(SELECT  test_id FROM dbo.tests WITH(NOLOCK) where var_id = @varidProductionTotal and event_id = @EventId)
IF @TestId IS NOT NULL
	SET @UpdateType = 2
ELSE
	SET @UpdateType = 1

	SELECT 	2,
			@varidProductionTotal,
			@puid,
			1,
			0,
			@ProductionTotal,
			@Thistime,
			@UpdateType,
			0,
			NULL,
			0,
			@EventId,
			NULL,
			NULL,
			NULL,
			NULL,
			@TestId,
			NULL,
			NULL,
			NULL

SET @TestId		=		(SELECT  test_id FROM dbo.tests WITH(NOLOCK) where var_id = @varidProductionReject and event_id = @EventId)
IF @TestId IS NOT NULL
	SET @UpdateType = 2
ELSE
	SET @UpdateType = 1

	SELECT 	2,
			@varidProductionReject,
			@puid,
			1,
			0,
			@ProductionReject,
			@Thistime,
			@UpdateType,
			0,
			NULL,
			0,
			@EventId,
			NULL,
			NULL,
			NULL,
			NULL,
			@TestId,
			NULL,
			NULL,
			NULL



SELECT	@OutputValue = CONVERT(varchar(30),@ThisTime)
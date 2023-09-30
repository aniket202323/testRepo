CREATE PROCEDURE [dbo].[spLocal_PE_SimulationCheckIn]

@OutputValue				varchar(25) OUTPUT,
@ThisTime					datetime,
@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_PE_SimulationCheckIn
	@OutputValue				OUTPUT,
	'29-Aug-2018 14:55',				
	1938

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(50),
		@Id							int,
		@Count						int,
--PO
		@PathId						int,
		@ActivePPID					int,
		@BOMFormId					int,
--Events
		@statusIdDelivered			int,
		@statusIdCheckedIn			int,
		@CntCheckIn					int,
		@CntDelivered				int,
		@ProdId						int,
		@AltprodId					int,
		@eventId					int,
		@CheckInTime				datetime

DECLARE @BOMProducts	TABLE (
id									int IDENTITY,
ProdId								int,
AltProdId							int,
NbrDelivered						int,
NbrCheckIn							int)




SET @SPNAME = 'spLocal_PE_SimulationCheckIn'
SET @Count = 0

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0001 - ' +
			' Started'	,
			@puid			)


SET @PathId = (	SELECT TOP 1 ppu.path_id
			FROM dbo.prdExec_Input_Sources peis		WITH(NOLOCK)
			JOIN dbo.prdExec_Inputs pei				WITH(NOLOCK) ON pei.pei_id = peis.pei_id AND peis.pu_id = @PuID
			JOIN dbo.PrdExec_Path_Units ppu			WITH(NOLOCK) ON pei.pu_id = ppu.pu_id 
			)


-------------------------------------------------------------
--Find the Active PPID
-------------------------------------------------------------
SET @ActivePPID =	(SELECT pp_id FROM dbo.production_plan WITH(NOLOCK) WHERE path_id = @PathId AND pp_status_id = 3)
IF @ActivePPID IS NULL
BEGIN
	--There is no Active PO
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0100 - ' +
			' No Active  PO, cannot check in'	,
			@puid			)

	SELECT	@OutputValue =  'No Active  PO, cannot check in'
	RETURN
END


-------------------------------------------------------------
--Get BOM on that unit
-------------------------------------------------------------
SET @BOMFormId = (SELECT BOM_Formulation_Id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @ActivePPID)

INSERT @BOMProducts (prodId, AltProdId)
SELECT bomfi.prod_id, bomfs.prod_id
FROM		dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK) 
LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id
WHERE bomfi.BOM_Formulation_Id = @BOMFormId

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0200 - ' +
			' BOM for the unit collected'	,
			@puid			)


IF EXISTS(SELECT 1 FROM @BOMProducts)
BEGIN
	SET @statusIdDelivered = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'Delivered')
	SET @statusIdCheckedIn = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'Checked In')
END
ELSE
BEGIN
	--There is no BOM item
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0300 - ' +
			' No BOM'	,
			@puid			)

	SELECT	@OutputValue =  'No BOM'
	RETURN
END

SET @CheckInTime = @ThisTime
-------------------------------------------------------------
--Loop in the BOM
-------------------------------------------------------------
SET @Id = (SELECT min(id) FROM @BOMProducts)
WHILE @id IS NOT NULL
BEGIN

	SELECT	@ProdId = prodId,
			@AltProdId = COALESCE(altProdId,0)
	FROM @BOMProducts
	WHERE id = @id

	--Count Checked IN
	SET @CntCheckIn = (	SELECT COUNT(event_id) 
						FROM dbo.events WITH(NOLOCK) 
						WHERE pu_id = @puid
							AND event_status = @statusIdCheckedIn
							AND applied_product IN (@ProdId,@AltProdId)
							)

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0400 - ' +
			' Number of check in: '	+ CONVERT(varchar(30),@CntCheckIn),
			@puid			)



	IF @CntCheckIn < 2
	BEGIN
		--check for delivered
		SET @eventid = (	SELECT TOP 1 event_id 
							FROM dbo.events WITH(NOLOCK) 
							WHERE pu_id = @puid 
								AND event_status = @statusIdDelivered
								AND applied_product IN (@ProdId,@AltProdId)
							ORDER by TIMESTAMP ASC)


		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'0420 - ' +
				' Event_id to check in: '	+ CONVERT(varchar(30),COALESCE(@eventid,0)),
				@puid			)


		WHILE EXISTS(SELECT event_id FROM dbo.events WITH(NOLOCK) WHERE pu_id = @puid AND timestamp = @CheckInTime )
		BEGIN
			SET @CheckInTime = (SELECT DATEADD(s,2,@CheckInTime))
		END

	

		--Check in the pallet
		IF @eventid IS NOT NULL
		BEGIN
			SELECT	1,
					NULL,
					2,
					@eventid,
					event_num,
					@puid,
					@CheckInTime,
					Applied_product,
					NULL,
					@statusIdCheckedIn,
					NULL,
					26,
					0,
					NULL,
					NULL,
					NULL,
					0,
					NULL,
					NULL,
					event_subtype_id,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL
				FROM dbo.events where event_id = @eventid

				INSERT local_debug (CallingSP,timestamp, message, msg)
				VALUES (	@SPNAME,
						GETDATE(),
						'0440 - ' +
						' Event checked in: '	+ CONVERT(varchar(30),COALESCE(@eventid,0)),
						@puid			)

				SET @Count = @Count +1

			END
	END

	SET @Id = (SELECT min(id) FROM @BOMProducts WHERE id > @Id)
END



SELECT	@OutputValue =  CONVERT(varchar(30),@count) + ' pallet(s) checked in'

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0900 - ' +
			@OutputValue,
			@puid			)
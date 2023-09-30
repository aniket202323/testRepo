-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppGetWasteByEventAndPO]
		@EventID		int,
		@PPID			int
	
AS
SET NOCOUNT ON

DECLARE @WasteAmount			decimal(20,6),
		@ProcessOrder		varchar(50)

DECLARE @CalllingSP			varchar(50),
		@DebugFlagOnline	int	


SET @DebugFlagOnline = 1 	
IF @DebugFlagOnLine = 1
	BEGIN
		INSERT intO Local_Debug([Timestamp], CallingSP, [Message]) 
			VALUES(	getdate(), 
					'spLocal_CmnMobileAppGetWasteByEventAndPO',
					'0010' +
					' EventId: ' + coalesce(convert(varchar(25),@EventId) ,'') +
					' PPID: ' + coalesce(convert(varchar(25),@PPID) ,'') )
	END	
-----------------------------------------------------------
--  Get PO information 
-----------------------------------------------------------
SELECT	@ProcessOrder			=	PP.Process_order
FROM	dbo.production_plan pp	WITH(NOLOCK)
WHERE	pp.PP_ID = @PPID

IF @ProcessOrder IS NULL
BEGIN
	IF @DebugFlagOnLine = 1
	BEGIN
		INSERT intO Local_Debug([Timestamp], CallingSP, [Message]) 
			VALUES(	getdate(), 
					'spLocal_CmnMobileAppGetWasteByEventAndPO',
					'0020 Process Order does not exists' +
					' EventId: ' + coalesce(convert(varchar(25),@EventId) ,'') +
					' PPID: ' + coalesce(convert(varchar(25),@PPID) ,'') )
	END	
	SELECT NULL AS 'WasteAmount'
	RETURN
END


IF @DebugFlagOnLine = 1
	BEGIN
		INSERT intO Local_Debug([Timestamp], CallingSP, [Message]) 
			VALUES(	getdate(), 
					'spLocal_CmnMobileAppGetWasteByEventAndPO',
					'0010' +
					' EventId: ' + coalesce(convert(varchar(25),@EventId) ,'') +
					' PPID: ' + coalesce(convert(varchar(25),@PPID) ,'') +
					' ProcessOrder ' + coalesce(convert(varchar(25),@ProcessOrder) ,'')	)
	END

SET @WasteAmount = (SELECT	SUM(Amount)
					FROM dbo.Waste_Event_details w
					WHERE	Event_ID = @EventId 
					AND		Work_Order_Number = @ProcessOrder
					)

IF @DebugFlagOnLine = 1
	BEGIN
		INSERT intO Local_Debug([Timestamp], CallingSP, [Message]) 
			VALUES(	getdate(), 
					'spLocal_CmnMobileAppGetWasteByEventAndPO',
					'0010' +
					' EventId: ' + coalesce(convert(varchar(25),@EventId) ,'') +
					' PPID: ' + coalesce(convert(varchar(25),@PPID) ,'') +
					' ProcessOrder ' + coalesce(convert(varchar(25),@ProcessOrder) ,'')	+
					' WasteAmount ' + coalesce(convert(varchar(25),@WasteAmount) ,'')	)
	END

SELECT	@WasteAmount		AS 'Waste'

SET NOCOUNT OFF
RETURN
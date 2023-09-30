

CREATE PROCEDURE [dbo].[splocal_CmnCalcTestGetSIInventory] 	
@OutputValue			varchar(25) OUTPUT


AS
SET NOCOUNT ON


DECLARE @Inventory			TABLE 
(
		S95Id						varchar(50),
		EventId						int,
		ULID						varchar(50),
		DeliveryTime				datetime,
		ProdId						int,
		ProdCode					varchar(8),
		ProdDesc					varchar(50),
		Batch						varchar(25),
		StatusId					int,
		StatusDesc					varchar(50),
		DeliveredQty				float,
		RemainingQty				float,
		UOM							varchar(20),
		OG							varchar(10),
		ppid						int,			
		ProcessOrder				varchar(50),
		POStatus					varchar(50),
		VendorLot					varchar(25)
)

INSERT INTO @Inventory
(S95Id,	
 ULID,		
 deliveryTime,
 ProdDesc,	
 Batch,		
 OG,			
 statusDesc,	
 DeliveredQty,
 RemainingQty,
 UOM,			
 ProcessOrder,
 PoStatus,	
 EventId,		
 VendorLot)	
EXEC [dbo].[spLocal_CmnMobileAppGetSIInventory] 79 -- TSH4




SET @OutputValue = convert(varchar(25),getdate())




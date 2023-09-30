CREATE TABLE [dbo].[Local_PrIME_RequestId] (
    [id]          BIGINT       IDENTITY (1, 1) NOT NULL,
    [RequestId]   VARCHAR (50) NULL,
    [requestTime] DATETIME     NULL
);


GO
CREATE TRIGGER [dbo].[Local_PrIME_RequestId_Ins] ON  [dbo].[Local_PrIME_RequestId]
	FOR INSERT
	AS

	DECLARE @Number			BigInt,
			@PAD			varchar(30),
			@Prefix			varchar(30),
			@RequestID		varchar(30)		

	SELECT @Number = id FROM Inserted

	SET @Prefix =  (SELECT	 convert(varchar(255),IsNull(pee.Value,''))	 
			FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
	JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
	WHERE	e.type = 'site' AND		
			convert(varchar(255),pee.Name) =  'PE:PrIMESite.PrIMERequestIdPrefix')	



		--pad to have 10 characters
	SET @PAD =  (10 - LEN(@Prefix) - LEN(@Number))
	
	
	IF LEN(@PAD) < 10
	BEGIN
		SET @RequestID = convert(varchar(50),@Prefix) + convert(varchar(50),(SELECT REPLICATE('0', @PAD))) + convert(varchar(10),@Number)
	END

	UPDATE [dbo].[Local_PrIME_RequestId] 
	SET RequestId = @RequestID
	WHERE Id = @Number
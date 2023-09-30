CREATE TABLE [dbo].[Local_PE_LTAfromPLC] (
    [id]           INT          IDENTITY (1, 1) NOT NULL,
    [LTApuid]      INT          NULL,
    [ULID]         VARCHAR (51) NULL,
    [ProcessOrder] VARCHAR (12) NULL,
    [QuantityUL]   FLOAT (53)   NULL,
    [Timestamp]    DATETIME     NULL,
    [Processed]    BIT          NULL,
    [processTime]  DATETIME     NULL
);


GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex]
    ON [dbo].[Local_PE_LTAfromPLC]([ULID] ASC);


GO
CREATE NONCLUSTERED INDEX [Index_ULIDPrO]
    ON [dbo].[Local_PE_LTAfromPLC]([ULID] ASC, [ProcessOrder] ASC);


GO
CREATE NONCLUSTERED INDEX [LTAfromPLC_Timestamp]
    ON [dbo].[Local_PE_LTAfromPLC]([Timestamp] ASC);


GO
CREATE TRIGGER [dbo].[Local_PE_LTAfromPLC_Upd] ON  [dbo].Local_PE_LTAfromPLC
FOR UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Processed	bit,
			@Pt			datetime,
			@ULID		varchar(50)
		
	
	SELECT	@Processed	= Processed,
			@pt			= processTime,
			@ULID		= ULID
	FROM inserted

	IF @Processed = 1 AND @pt IS NULL
	BEGIN
		SET @pt = GETDATE()

		UPDATE Local_PE_LTAfromPLC SET processTime = @pt WHERE Processed = 1 AND processTime is null

	END
END
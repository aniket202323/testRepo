CREATE TABLE [dbo].[Property_MaterialClass] (
    [PropertyName]              NVARCHAR (200)   NOT NULL,
    [Description]               NVARCHAR (255)   NULL,
    [DataType]                  INT              NULL,
    [UnitOfMeasure]             NVARCHAR (255)   NULL,
    [Constant]                  BIT              NULL,
    [IsValueOverridden]         BIT              NULL,
    [IsDescriptionOverridden]   BIT              NULL,
    [IsUnitOfMeasureOverridden] BIT              NULL,
    [TimeStamp]                 DATETIME         NULL,
    [Value]                     SQL_VARIANT      NULL,
    [Version]                   BIGINT           NULL,
    [MaterialClassName]         NVARCHAR (200)   NOT NULL,
    [ItemId]                    UNIQUEIDENTIFIER NULL,
    [CustomDataTypeValueId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialClassName] ASC, [PropertyName] ASC),
    CONSTRAINT [FK_Property_MaterialClass_QFDataType] FOREIGN KEY ([CustomDataTypeValueId]) REFERENCES [dbo].[QFDataTypePhrases] ([DataTypePhraseId]),
    CONSTRAINT [Property_MaterialClass_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [Property_MaterialClass_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[Property_MaterialClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_Property_MaterialClass_ItemId]
    ON [dbo].[Property_MaterialClass]([ItemId] ASC);


GO
CREATE TRIGGER [dbo].[trg_Property_MaterialClass]
ON [dbo].[Property_MaterialClass]
FOR INSERT, UPDATE
AS
BEGIN
	-- check that rows were actually inserted/updated
	IF (@@ROWCOUNT = 0)
		RETURN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT * FROM inserted)
		RETURN

	DECLARE @CustomDataType INT = 18;

	UPDATE pmc
	SET CustomDataTypeValueId = 
		CASE (i.DataType)
			WHEN (@CustomDataType) THEN CONVERT(UNIQUEIDENTIFIER,i.Value)
			ELSE NULL
		END
	FROM dbo.Property_MaterialClass pmc
	INNER JOIN inserted i 
		ON i.MaterialClassName = pmc.MaterialClassName 
		AND i.PropertyName = pmc.PropertyName
END
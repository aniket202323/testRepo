CREATE TABLE [dbo].[QFDataTypes] (
    [DataTypeId]          UNIQUEIDENTIFIER NOT NULL,
    [DataTypeName]        NVARCHAR (256)   NOT NULL,
    [DataTypeDescription] NVARCHAR (255)   NULL,
    [SystemTypeId]        INT              DEFAULT ((-1)) NULL,
    [IsCustomDataType]    BIT              DEFAULT ((1)) NOT NULL,
    [Version]             BIGINT           NULL,
    CONSTRAINT [PK_QFDataTypes] PRIMARY KEY CLUSTERED ([DataTypeId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_QFDataTypes_DataTypeName]
    ON [dbo].[QFDataTypes]([DataTypeName] ASC);


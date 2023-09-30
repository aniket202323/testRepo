CREATE TABLE [dbo].[StructuredTypeProperty] (
    [Name]               NVARCHAR (255)   NOT NULL,
    [DefinedBy]          UNIQUEIDENTIFIER NULL,
    [DataType]           INT              NULL,
    [LastBuiltName]      NVARCHAR (255)   NULL,
    [LastBuiltDefinedBy] UNIQUEIDENTIFIER NULL,
    [Version]            BIGINT           NULL,
    [TypeOwnerNamespace] NVARCHAR (255)   NOT NULL,
    [TypeOwnerName]      NVARCHAR (255)   NOT NULL,
    PRIMARY KEY CLUSTERED ([Name] ASC, [TypeOwnerNamespace] ASC, [TypeOwnerName] ASC),
    CONSTRAINT [StructuredTypeProperty_StructuredType_Relation1] FOREIGN KEY ([TypeOwnerNamespace], [TypeOwnerName]) REFERENCES [dbo].[StructuredType] ([Namespace], [Name]) ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [NC_StructuredTypeProperty_TypeOwnerNamespace_TypeOwnerName]
    ON [dbo].[StructuredTypeProperty]([TypeOwnerNamespace] ASC, [TypeOwnerName] ASC);


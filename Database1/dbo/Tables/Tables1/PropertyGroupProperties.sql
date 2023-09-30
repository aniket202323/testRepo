CREATE TABLE [dbo].[PropertyGroupProperties] (
    [PropertyGroupPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                    NVARCHAR (255)   NULL,
    [DataType]                INT              NULL,
    [Version]                 BIGINT           NULL,
    [PropertyGroupId]         UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PropertyGroupPropertyId] ASC),
    CONSTRAINT [PropertyGroupProperties_PropertyGroup_Relation1] FOREIGN KEY ([PropertyGroupId]) REFERENCES [dbo].[PropertyGroup] ([PropertyGroupId])
);


GO
CREATE NONCLUSTERED INDEX [NC_PropertyGroupProperties_PropertyGroupId]
    ON [dbo].[PropertyGroupProperties]([PropertyGroupId] ASC);


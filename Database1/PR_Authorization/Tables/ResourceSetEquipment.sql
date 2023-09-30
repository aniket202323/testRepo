CREATE TABLE [PR_Authorization].[ResourceSetEquipment] (
    [ResourceSetId]    UNIQUEIDENTIFIER NOT NULL,
    [EquipmentId]      UNIQUEIDENTIFIER NOT NULL,
    [Version]          BIGINT           NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_ResourceSetEquipment] PRIMARY KEY CLUSTERED ([ResourceSetId] ASC, [EquipmentId] ASC),
    CONSTRAINT [FK_ResourceSetEquipment_ResourceSet] FOREIGN KEY ([ResourceSetId]) REFERENCES [PR_Authorization].[ResourceSet] ([ResourceSetId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_ResourceGroupEquipment]
    ON [PR_Authorization].[ResourceSetEquipment]([EquipmentId] ASC, [ResourceSetId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is used to define access to element in in the Equipment Hierarchy.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'ResourceSetEquipment';


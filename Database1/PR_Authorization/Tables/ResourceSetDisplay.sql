CREATE TABLE [PR_Authorization].[ResourceSetDisplay] (
    [ResourceSetId]         UNIQUEIDENTIFIER NOT NULL,
    [DisplayHierarchyDmcId] NVARCHAR (255)   NOT NULL,
    [Version]               BIGINT           NOT NULL,
    [CreatedBy]             NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]           DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_ResourceSetDisplay] PRIMARY KEY CLUSTERED ([ResourceSetId] ASC, [DisplayHierarchyDmcId] ASC),
    CONSTRAINT [FK_ResourceSetDisplay_ResourceSet] FOREIGN KEY ([ResourceSetId]) REFERENCES [PR_Authorization].[ResourceSet] ([ResourceSetId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_ResourceGroupDisplay]
    ON [PR_Authorization].[ResourceSetDisplay]([DisplayHierarchyDmcId] ASC, [ResourceSetId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is used to define access to the rows found in DisplayHierarchyDmc.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'ResourceSetDisplay';


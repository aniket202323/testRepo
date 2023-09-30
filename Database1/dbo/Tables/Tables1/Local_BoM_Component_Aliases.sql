CREATE TABLE [dbo].[Local_BoM_Component_Aliases] (
    [AliasId]       INT           IDENTITY (1, 1) NOT NULL,
    [TypeDesc]      VARCHAR (200) NOT NULL,
    [CanonicalType] VARCHAR (50)  NOT NULL,
    [Alias]         VARCHAR (5)   NOT NULL,
    CONSTRAINT [LocalBoMComponentAliases_PK_AliasId] PRIMARY KEY CLUSTERED ([AliasId] ASC)
);


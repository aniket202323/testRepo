CREATE TABLE [dbo].[Local_E2P_Global_Elements] (
    [ElementId]   INT            IDENTITY (1, 1) NOT NULL,
    [ComponentId] INT            NOT NULL,
    [Key]         VARCHAR (1000) NOT NULL,
    [Value]       VARCHAR (1000) NOT NULL,
    CONSTRAINT [LocalE2PGlobalElements_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Elements_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);


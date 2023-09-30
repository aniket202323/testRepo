CREATE TABLE [dbo].[Local_eDH_List] (
    [Id]           INT            IDENTITY (1, 1) NOT NULL,
    [DestColumn]   NVARCHAR (255) NOT NULL,
    [GlobalName]   NVARCHAR (255) NULL,
    [GlobalDesc]   NVARCHAR (255) NULL,
    [Code]         NVARCHAR (50)  NULL,
    [L18NMasterID] INT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Local_eDH_List_Local_eDH_l18nMaster] FOREIGN KEY ([L18NMasterID]) REFERENCES [dbo].[Local_eDH_l18nMaster] ([L18NMasterID])
);


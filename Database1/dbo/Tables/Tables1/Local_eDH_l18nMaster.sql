CREATE TABLE [dbo].[Local_eDH_l18nMaster] (
    [L18NMasterID]   INT            IDENTITY (1, 1) NOT NULL,
    [l18nMasterDesc] NVARCHAR (255) NULL,
    [Type]           NVARCHAR (50)  NULL,
    CONSTRAINT [PK_l18nMaster] PRIMARY KEY CLUSTERED ([L18NMasterID] ASC) WITH (FILLFACTOR = 95)
);


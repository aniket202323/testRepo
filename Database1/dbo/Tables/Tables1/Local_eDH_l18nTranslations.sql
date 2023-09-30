CREATE TABLE [dbo].[Local_eDH_l18nTranslations] (
    [L18NID]       INT            IDENTITY (1, 1) NOT NULL,
    [LanguageID]   INT            NULL,
    [l18nMasterID] INT            NULL,
    [Translation]  NVARCHAR (255) NULL,
    CONSTRAINT [PK_l18nTranslations] PRIMARY KEY CLUSTERED ([L18NID] ASC) WITH (FILLFACTOR = 95),
    CONSTRAINT [FK_l18nTranslations_l18nMaster] FOREIGN KEY ([l18nMasterID]) REFERENCES [dbo].[Local_eDH_l18nMaster] ([L18NMasterID]),
    CONSTRAINT [FK_l18nTranslations_Languages] FOREIGN KEY ([LanguageID]) REFERENCES [dbo].[Local_eDH_Languages] ([LangID])
);


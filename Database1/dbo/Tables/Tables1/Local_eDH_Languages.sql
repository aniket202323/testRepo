CREATE TABLE [dbo].[Local_eDH_Languages] (
    [LangID]       INT            IDENTITY (1, 1) NOT NULL,
    [Language]     NVARCHAR (255) NULL,
    [l18nMasterID] INT            NULL,
    [Code]         NVARCHAR (2)   NULL,
    CONSTRAINT [PK_Languages] PRIMARY KEY CLUSTERED ([LangID] ASC) WITH (FILLFACTOR = 95)
);


CREATE TABLE [dbo].[Languages] (
    [Enabled]       TINYINT              CONSTRAINT [DF_Languages_Enabled] DEFAULT ((1)) NOT NULL,
    [Language_Desc] [dbo].[Varchar_Desc] NOT NULL,
    [Language_Id]   INT                  NOT NULL,
    [LocaleId]      INT                  CONSTRAINT [DF_Languages_LocalId] DEFAULT ((1033)) NULL,
    [Sponsor]       VARCHAR (100)        NULL,
    [Lang_Abbrev]   VARCHAR (10)         NULL,
    CONSTRAINT [Languages_PK_LangId] PRIMARY KEY NONCLUSTERED ([Language_Id] ASC),
    CONSTRAINT [Languages_UC_LangDesc] UNIQUE NONCLUSTERED ([Language_Desc] ASC)
);


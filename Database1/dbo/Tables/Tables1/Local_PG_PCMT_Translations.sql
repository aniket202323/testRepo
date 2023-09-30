CREATE TABLE [dbo].[Local_PG_PCMT_Translations] (
    [Translation_id] INT           IDENTITY (1, 1) NOT NULL,
    [Item_id]        INT           NOT NULL,
    [lang_id]        INT           NOT NULL,
    [Translation]    VARCHAR (100) NULL
);


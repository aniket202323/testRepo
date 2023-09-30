CREATE TABLE [dbo].[Dashboard_Default_XSL] (
    [XSL]          TEXT          NOT NULL,
    [XSL_Filename] VARCHAR (100) NOT NULL,
    [XSL_ID]       INT           NOT NULL,
    CONSTRAINT [Dashboard_Default_XSL_PK] PRIMARY KEY CLUSTERED ([XSL_ID] ASC)
);


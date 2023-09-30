CREATE TABLE [dbo].[Functions] (
    [Description]   [dbo].[Varchar_Desc] NOT NULL,
    [Function_Code] VARCHAR (7900)       NOT NULL,
    CONSTRAINT [Functions_PK_Desc] PRIMARY KEY NONCLUSTERED ([Description] ASC)
);


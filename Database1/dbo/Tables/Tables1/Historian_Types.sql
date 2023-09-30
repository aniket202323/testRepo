CREATE TABLE [dbo].[Historian_Types] (
    [Hist_Type_Desc]    VARCHAR (255) NOT NULL,
    [Hist_Type_DllName] VARCHAR (255) NULL,
    [Hist_Type_Id]      INT           NOT NULL,
    CONSTRAINT [PK_Historian_Types] PRIMARY KEY NONCLUSTERED ([Hist_Type_Id] ASC),
    CONSTRAINT [Historian_Types_UC_HistTypeDesc] UNIQUE NONCLUSTERED ([Hist_Type_Desc] ASC)
);


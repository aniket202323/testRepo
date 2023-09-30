CREATE TABLE [dbo].[Access_Level] (
    [AL_Desc] VARCHAR (20) NOT NULL,
    [AL_Id]   TINYINT      NOT NULL,
    CONSTRAINT [Access_Level_PK_ALId] PRIMARY KEY CLUSTERED ([AL_Id] ASC),
    CONSTRAINT [Access_Level_UC_ALDesc] UNIQUE NONCLUSTERED ([AL_Desc] ASC)
);


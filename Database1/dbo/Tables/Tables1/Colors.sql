CREATE TABLE [dbo].[Colors] (
    [Color_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Color]      INT                  NOT NULL,
    [Color_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PK_Colors] PRIMARY KEY NONCLUSTERED ([Color_Id] ASC),
    CONSTRAINT [Colors_IX_UC_Color] UNIQUE NONCLUSTERED ([Color] ASC),
    CONSTRAINT [Colors_IX_UC_Desc] UNIQUE NONCLUSTERED ([Color_Desc] ASC)
);


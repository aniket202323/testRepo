CREATE TABLE [dbo].[Production_Event_Association] (
    [PEA_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PEA_Desc] [dbo].[Varchar_Desc] NULL,
    CONSTRAINT [ProdEvtAssoc_PK_PEA_Id] PRIMARY KEY NONCLUSTERED ([PEA_Id] ASC)
);


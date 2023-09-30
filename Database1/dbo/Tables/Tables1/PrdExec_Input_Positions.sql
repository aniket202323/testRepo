CREATE TABLE [dbo].[PrdExec_Input_Positions] (
    [PEIP_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PEIP_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PrdExecInputPos_PK_PEIPId] PRIMARY KEY NONCLUSTERED ([PEIP_Id] ASC)
);


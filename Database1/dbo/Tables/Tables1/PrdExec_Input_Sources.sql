CREATE TABLE [dbo].[PrdExec_Input_Sources] (
    [PEIS_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PEI_Id]  INT NOT NULL,
    [PU_Id]   INT NOT NULL,
    CONSTRAINT [PrdExecInputSrc_PK_PEISId] PRIMARY KEY NONCLUSTERED ([PEIS_Id] ASC),
    CONSTRAINT [PrdExecInputSrc_FK_PEIId] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id]),
    CONSTRAINT [PrdExecInputSrc_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


CREATE TABLE [dbo].[PrdExec_Path_Input_Sources] (
    [PEPIS_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Path_Id]  INT NOT NULL,
    [PEI_Id]   INT NOT NULL,
    [PU_Id]    INT NULL,
    CONSTRAINT [PrdExecPathISource_PK_PEPISId] PRIMARY KEY CLUSTERED ([PEPIS_Id] ASC),
    CONSTRAINT [PrdExecPathISource_FK_PEInputs] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id]),
    CONSTRAINT [PrdExecPathISource_FK_PrdExecPath] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [PrdExecPathISource_FK_ProdUnits] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


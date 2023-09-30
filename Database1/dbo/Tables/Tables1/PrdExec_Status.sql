CREATE TABLE [dbo].[PrdExec_Status] (
    [PEXP_Id]           INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Is_Default_Status] TINYINT NULL,
    [PU_Id]             INT     NOT NULL,
    [Step]              INT     NOT NULL,
    [Valid_Status]      INT     NULL,
    CONSTRAINT [PrdExecStatus_PK_PEXPId] PRIMARY KEY CLUSTERED ([PEXP_Id] ASC),
    CONSTRAINT [PrdExecStatus_FK_Prod_Units] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [PrdExecStatus_FK_VStatus] FOREIGN KEY ([Valid_Status]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id])
);


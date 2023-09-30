CREATE TABLE [dbo].[PrdExec_Trans] (
    [PET_Id]             INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [From_ProdStatus_Id] INT NULL,
    [PU_Id]              INT NOT NULL,
    [To_ProdStatus_Id]   INT NULL,
    CONSTRAINT [PrdExecTrans_PK_PETId] PRIMARY KEY NONCLUSTERED ([PET_Id] ASC),
    CONSTRAINT [PrdExec_Trans_FK_ToStatusId] FOREIGN KEY ([To_ProdStatus_Id]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id]),
    CONSTRAINT [PrdExecTrans_FK_From_ProdStatusId] FOREIGN KEY ([From_ProdStatus_Id]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id]),
    CONSTRAINT [PrdExecTrans_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [PrdExecTrans_By_PUIdFromStatus]
    ON [dbo].[PrdExec_Trans]([PU_Id] ASC, [From_ProdStatus_Id] ASC);


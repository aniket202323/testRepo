CREATE TABLE [dbo].[Production_Status_XRef] (
    [ProdStatus_Id]          INT          NULL,
    [Production_Status_XRef] VARCHAR (50) NOT NULL,
    [PU_Id]                  INT          NULL,
    CONSTRAINT [ProdStatusXRef_FK_ProdStatusId] FOREIGN KEY ([ProdStatus_Id]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id]),
    CONSTRAINT [ProdStatusXRef_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [ProdStatusXRef_UC_ProdStatusPUID] UNIQUE NONCLUSTERED ([PU_Id] ASC, [ProdStatus_Id] ASC)
);


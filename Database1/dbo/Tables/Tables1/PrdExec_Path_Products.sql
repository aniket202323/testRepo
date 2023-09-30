CREATE TABLE [dbo].[PrdExec_Path_Products] (
    [PEPP_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Path_Id] INT NOT NULL,
    [Prod_Id] INT NOT NULL,
    CONSTRAINT [PrdExecPathProducts_PK_PEPPId] PRIMARY KEY NONCLUSTERED ([PEPP_Id] ASC),
    CONSTRAINT [p_path_products_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [PrdExecPathProducts_FK_Products] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id])
);


GO
CREATE CLUSTERED INDEX [PrdExecPathProducts_IDX_PathIdProdId]
    ON [dbo].[PrdExec_Path_Products]([Path_Id] ASC, [Prod_Id] ASC);


CREATE TABLE [dbo].[Product_Group_Data] (
    [PGD_Id]         INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Prod_Id]        INT NOT NULL,
    [Product_Grp_Id] INT NOT NULL,
    CONSTRAINT [PK___3__10] PRIMARY KEY CLUSTERED ([Product_Grp_Id] ASC, [Prod_Id] ASC),
    CONSTRAINT [ProdGrpData_FK_ProdGrpId] FOREIGN KEY ([Product_Grp_Id]) REFERENCES [dbo].[Product_Groups] ([Product_Grp_Id]),
    CONSTRAINT [ProdGrpData_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id])
);


GO
CREATE NONCLUSTERED INDEX [Product_Group_Data_By_Group]
    ON [dbo].[Product_Group_Data]([Product_Grp_Id] ASC);


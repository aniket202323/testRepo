CREATE TABLE [dbo].[tblGIP_BU_Categories] (
    [BUC_ID]           INT          IDENTITY (1, 1) NOT NULL,
    [BU_ID]            INT          NOT NULL,
    [BU_Category_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_tblGIP_BU_Categories] PRIMARY KEY CLUSTERED ([BUC_ID] ASC),
    CONSTRAINT [FK_tblGIP_BU_Categories_tblGIP_Business_Unit] FOREIGN KEY ([BU_ID]) REFERENCES [dbo].[tblGIP_Business_Unit] ([BU_ID]) NOT FOR REPLICATION
);


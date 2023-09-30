CREATE TABLE [dbo].[VendorAttributes] (
    [Attribute_Id]         INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data_Type_Id]         INT                  NULL,
    [VendorAttribute_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [VendorAttributes_PK_AttributeId] PRIMARY KEY CLUSTERED ([Attribute_Id] ASC),
    CONSTRAINT [VendorAttributes_FK_DataTypeId] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id])
);


GO
CREATE NONCLUSTERED INDEX [VendorAttributes_IDX_DataTypeId]
    ON [dbo].[VendorAttributes]([Data_Type_Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [VenderAttributes_UC_VendorAttributeDesc]
    ON [dbo].[VendorAttributes]([VendorAttribute_Desc] ASC);


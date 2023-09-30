CREATE TABLE [dbo].[ED_Attributes] (
    [ED_Attribute_Id] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Attribute_Desc]  VARCHAR (50) NOT NULL,
    CONSTRAINT [ED_Attributes_PK_AttId] PRIMARY KEY NONCLUSTERED ([ED_Attribute_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ED_Attributes_IDX_AttDesc]
    ON [dbo].[ED_Attributes]([Attribute_Desc] ASC);


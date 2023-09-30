CREATE TABLE [dbo].[PU_Characteristics] (
    [Char_Id] INT NOT NULL,
    [Prod_Id] INT NOT NULL,
    [Prop_Id] INT NOT NULL,
    [PU_Id]   INT NOT NULL,
    CONSTRAINT [PUChar_PK_PUIdProdIdPropId] PRIMARY KEY CLUSTERED ([PU_Id] ASC, [Prod_Id] ASC, [Prop_Id] ASC),
    CONSTRAINT [PUChar_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [PUChar_FK_PropId] FOREIGN KEY ([Prop_Id]) REFERENCES [dbo].[Product_Properties] ([Prop_Id]),
    CONSTRAINT [PUChar_FK_PUIdProdId] FOREIGN KEY ([Prod_Id], [PU_Id]) REFERENCES [dbo].[PU_Products] ([Prod_Id], [PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [PU_Char_CharId]
    ON [dbo].[PU_Characteristics]([Char_Id] ASC);


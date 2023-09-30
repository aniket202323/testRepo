CREATE TABLE [dbo].[Trans_Characteristics] (
    [Char_Id]             INT NULL,
    [Prod_Id]             INT NOT NULL,
    [Prop_Id]             INT NOT NULL,
    [PU_Id]               INT NOT NULL,
    [Trans_Id]            INT NOT NULL,
    [Validation_Trans_Id] INT NULL,
    CONSTRAINT [TransChar_PK_TransIdProdPropPU] PRIMARY KEY CLUSTERED ([Trans_Id] ASC, [Prod_Id] ASC, [Prop_Id] ASC, [PU_Id] ASC),
    CONSTRAINT [Trans_Chars_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [Trans_Chars_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Trans_Chars_FK_PropId] FOREIGN KEY ([Prop_Id]) REFERENCES [dbo].[Product_Properties] ([Prop_Id]),
    CONSTRAINT [Trans_Chars_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Trans_Chars_FK_TransId] FOREIGN KEY ([Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id]),
    CONSTRAINT [Trans_Chars_FK_VTransId] FOREIGN KEY ([Validation_Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id])
);


GO
CREATE NONCLUSTERED INDEX [TransCharacteristics_IDX_ValTransId]
    ON [dbo].[Trans_Characteristics]([Validation_Trans_Id] ASC);


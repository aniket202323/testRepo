CREATE TABLE [dbo].[Trans_Char_Links] (
    [From_Char_Id]        INT NOT NULL,
    [To_Char_Id]          INT NULL,
    [Trans_Id]            INT NOT NULL,
    [TransOrder]          INT NOT NULL,
    [Validation_Trans_Id] INT NULL,
    CONSTRAINT [Trans_CharsL_FK_FCharId] FOREIGN KEY ([From_Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [Trans_CharsL_FK_TCharId] FOREIGN KEY ([To_Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [Trans_CharsL_FK_TransId] FOREIGN KEY ([Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id]),
    CONSTRAINT [Trans_CharsL_FK_VTransId] FOREIGN KEY ([Validation_Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id])
);


GO
CREATE NONCLUSTERED INDEX [TransCharLinks_IDX_TransId]
    ON [dbo].[Trans_Char_Links]([Trans_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [TransCharLinks_IDX_ValTransId]
    ON [dbo].[Trans_Char_Links]([Validation_Trans_Id] ASC);


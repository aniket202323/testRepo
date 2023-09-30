CREATE TABLE [dbo].[Tag_Equivalence] (
    [Tag_Equivalence_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Var_Id]             INT NULL,
    CONSTRAINT [TagEquivalence_PK_Id] PRIMARY KEY NONCLUSTERED ([Tag_Equivalence_Id] ASC),
    CONSTRAINT [TagEquivalence_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
CREATE NONCLUSTERED INDEX [TagEquivalence_IDX_VarId]
    ON [dbo].[Tag_Equivalence]([Var_Id] ASC);


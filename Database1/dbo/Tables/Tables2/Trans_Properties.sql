CREATE TABLE [dbo].[Trans_Properties] (
    [Char_Id]             INT                   NOT NULL,
    [Comment_Id]          INT                   NULL,
    [Esignature_Level]    INT                   NULL,
    [Force_Delete]        BIT                   CONSTRAINT [Trans_Props_DF_ForceDelete] DEFAULT ((0)) NOT NULL,
    [Is_Defined]          INT                   NULL,
    [L_Control]           [dbo].[Varchar_Value] NULL,
    [L_Entry]             [dbo].[Varchar_Value] NULL,
    [L_Reject]            [dbo].[Varchar_Value] NULL,
    [L_User]              [dbo].[Varchar_Value] NULL,
    [L_Warning]           [dbo].[Varchar_Value] NULL,
    [Not_Defined]         INT                   NULL,
    [Spec_Id]             INT                   NOT NULL,
    [T_Control]           [dbo].[Varchar_Value] NULL,
    [Target]              [dbo].[Varchar_Value] NULL,
    [Test_Freq]           INT                   NULL,
    [Trans_Id]            INT                   NOT NULL,
    [U_Control]           [dbo].[Varchar_Value] NULL,
    [U_Entry]             [dbo].[Varchar_Value] NULL,
    [U_Reject]            [dbo].[Varchar_Value] NULL,
    [U_User]              [dbo].[Varchar_Value] NULL,
    [U_Warning]           [dbo].[Varchar_Value] NULL,
    [Validation_Trans_Id] INT                   NULL,
    CONSTRAINT [Trans_Props_PK_TransSpecChar] PRIMARY KEY CLUSTERED ([Trans_Id] ASC, [Spec_Id] ASC, [Char_Id] ASC),
    CONSTRAINT [Trans_Props_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [Trans_Props_FK_SpecId] FOREIGN KEY ([Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [Trans_Props_FK_TransId] FOREIGN KEY ([Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id]),
    CONSTRAINT [TransProp_FK_VTransId] FOREIGN KEY ([Validation_Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id])
);


GO
CREATE NONCLUSTERED INDEX [TransProperties_IDX_SpecId]
    ON [dbo].[Trans_Properties]([Spec_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [TransProperties_IDX_CharId]
    ON [dbo].[Trans_Properties]([Char_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [TransProperties_IDX_ValTransId]
    ON [dbo].[Trans_Properties]([Validation_Trans_Id] ASC);


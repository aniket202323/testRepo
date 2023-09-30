CREATE TABLE [dbo].[Trans_Variables] (
    [Comment_Id]          INT                   NULL,
    [Corp_Prod_Code]      VARCHAR (25)          NULL,
    [Corp_Var_Desc]       VARCHAR (50)          NULL,
    [Esignature_Level]    INT                   NULL,
    [Force_Delete]        BIT                   CONSTRAINT [Trans_Vars_DF_ForceDelete] DEFAULT ((0)) NOT NULL,
    [Is_Defined]          INT                   NULL,
    [Is_OverRidable]      INT                   NULL,
    [L_Control]           [dbo].[Varchar_Value] NULL,
    [L_Entry]             [dbo].[Varchar_Value] NULL,
    [L_Reject]            [dbo].[Varchar_Value] NULL,
    [L_User]              [dbo].[Varchar_Value] NULL,
    [L_Warning]           [dbo].[Varchar_Value] NULL,
    [Not_Defined]         INT                   NULL,
    [Prod_Id]             INT                   NOT NULL,
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
    [Var_Id]              INT                   NOT NULL,
    CONSTRAINT [PK_Trans_Variables_2__13] PRIMARY KEY CLUSTERED ([Trans_Id] ASC, [Prod_Id] ASC, [Var_Id] ASC),
    CONSTRAINT [Trans_Vars_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Trans_Vars_FK_TransId] FOREIGN KEY ([Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id]),
    CONSTRAINT [Trans_Vars_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [TransVars_FK_TransId] FOREIGN KEY ([Validation_Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id])
);


GO
CREATE NONCLUSTERED INDEX [Trans_Vars_IDX_VarId]
    ON [dbo].[Trans_Variables]([Var_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [TransVariables_IDX_ValTransId]
    ON [dbo].[Trans_Variables]([Validation_Trans_Id] ASC);


CREATE TABLE [dbo].[Staged_Sheet_Variables] (
    [Sheet_Id]           INT                  NOT NULL,
    [Title]              [dbo].[Varchar_Desc] NULL,
    [Var_Id]             INT                  NULL,
    [Var_Order]          INT                  NOT NULL,
    [Title_Var_Order_Id] INT                  NULL
);


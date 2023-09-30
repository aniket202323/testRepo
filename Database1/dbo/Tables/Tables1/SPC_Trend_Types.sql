CREATE TABLE [dbo].[SPC_Trend_Types] (
    [SPC_Trend_Type_Desc] VARCHAR (50) NOT NULL,
    [SPC_Trend_Type_Id]   INT          NOT NULL,
    [Var1_Label]          VARCHAR (50) NOT NULL,
    [Var2_Label]          VARCHAR (50) NULL,
    CONSTRAINT [PK_SPC_Trend_Types] PRIMARY KEY NONCLUSTERED ([SPC_Trend_Type_Id] ASC),
    CONSTRAINT [SPC_Trend_Types_UC_Desc] UNIQUE NONCLUSTERED ([SPC_Trend_Type_Desc] ASC)
);


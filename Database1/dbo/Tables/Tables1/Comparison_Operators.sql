CREATE TABLE [dbo].[Comparison_Operators] (
    [Comparison_Operator_Id]    TINYINT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comparison_Operator_Value] VARCHAR (50) NOT NULL,
    [Comparison_Operators_SQL]  VARCHAR (50) NULL,
    [Comparison_Operators_VB]   VARCHAR (50) NULL,
    CONSTRAINT [CompOper_PK_CompOperId] PRIMARY KEY NONCLUSTERED ([Comparison_Operator_Id] ASC)
);


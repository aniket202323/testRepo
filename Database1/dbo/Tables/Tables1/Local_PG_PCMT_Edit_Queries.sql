CREATE TABLE [dbo].[Local_PG_PCMT_Edit_Queries] (
    [Query_ID]     INT            IDENTITY (1, 1) NOT NULL,
    [PU_ID]        INT            NOT NULL,
    [Var_ID]       INT            NOT NULL,
    [Query_String] VARCHAR (5000) NOT NULL,
    [PCMT_Version] VARCHAR (50)   NULL,
    [Timestamp]    DATETIME       NOT NULL,
    CONSTRAINT [PK_Local_PG_PCMT_Edit_Queries] PRIMARY KEY CLUSTERED ([Var_ID] ASC)
);


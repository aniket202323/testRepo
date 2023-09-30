CREATE TABLE [dbo].[Local_PG_PCMT_Errors] (
    [Error_id]    INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]   DATETIME      NOT NULL,
    [Description] VARCHAR (500) NOT NULL,
    [Module]      VARCHAR (50)  NOT NULL,
    [Sub]         VARCHAR (50)  NOT NULL
);


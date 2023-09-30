CREATE TABLE [dbo].[Local_PG_PCMT_Log_Groups] (
    [Log_id]     INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]  DATETIME      NOT NULL,
    [User_id1]   INT           NOT NULL,
    [Type]       INT           NULL,
    [Group_id]   INT           NULL,
    [Group_desc] VARCHAR (255) NULL
);


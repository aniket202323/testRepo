CREATE TABLE [dbo].[Local_PG_PCMT_Log_ProductionGroups] (
    [Log_id]    INT            IDENTITY (1, 1) NOT NULL,
    [Timestamp] DATETIME       NOT NULL,
    [User_id]   INT            NOT NULL,
    [Type]      VARCHAR (50)   NOT NULL,
    [PU_Id]     INT            NULL,
    [PUG_desc]  NVARCHAR (MAX) NULL
);


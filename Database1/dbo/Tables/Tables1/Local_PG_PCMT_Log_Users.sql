CREATE TABLE [dbo].[Local_PG_PCMT_Log_Users] (
    [Log_id]              INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]           DATETIME      NOT NULL,
    [User_id1]            INT           NOT NULL,
    [Type]                INT           NULL,
    [User_id]             INT           NULL,
    [Mixed_Mode_Login]    INT           NULL,
    [Password]            VARCHAR (30)  NULL,
    [Role_Based_Security] INT           NULL,
    [User_Desc]           VARCHAR (255) NULL,
    [User_Name]           VARCHAR (30)  NULL,
    [View_Id]             INT           NULL,
    [WindowsUserInfo]     VARCHAR (200) NULL,
    [Active]              INT           NULL
);


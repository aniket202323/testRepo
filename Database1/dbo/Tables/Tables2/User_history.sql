CREATE TABLE [dbo].[User_history] (
    [User_history_Id]        BIGINT                    IDENTITY (1, 1) NOT NULL,
    [Username]               [dbo].[Varchar_Username]  NULL,
    [Active]                 BIT                       NULL,
    [Is_Role]                BIT                       NULL,
    [Mixed_Mode_Login]       BIT                       NULL,
    [Role_Based_Security]    BIT                       NULL,
    [Password]               [dbo].[Varchar_Username]  NULL,
    [SSOUserId]              VARCHAR (50)              NULL,
    [User_Desc]              [dbo].[Varchar_Long_Desc] NULL,
    [UseSSO]                 BIT                       NULL,
    [View_Id]                INT                       NULL,
    [WindowsUserInfo]        VARCHAR (200)             NULL,
    [System]                 TINYINT                   NULL,
    [User_Id]                INT                       NULL,
    [Modified_On]            DATETIME                  NULL,
    [DBTT_Id]                TINYINT                   NULL,
    [Column_Updated_BitMask] VARCHAR (15)              NULL,
    CONSTRAINT [User_history_PK_Id] PRIMARY KEY NONCLUSTERED ([User_history_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [Userhistory_IX_UserIdModifiedOn]
    ON [dbo].[User_history]([User_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[User_History_UpdDel]
 ON  [dbo].[User_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

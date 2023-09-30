CREATE TABLE [dbo].[User_Security] (
    [Security_Id]  INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Access_Level] TINYINT NOT NULL,
    [Group_Id]     INT     NOT NULL,
    [User_Id]      INT     NOT NULL,
    CONSTRAINT [User_Security_PK_SecurityId] PRIMARY KEY NONCLUSTERED ([Security_Id] ASC),
    CONSTRAINT [User_Security_FK_AccessLevel] FOREIGN KEY ([Access_Level]) REFERENCES [dbo].[Access_Level] ([AL_Id]),
    CONSTRAINT [User_Security_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [User_Security_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [User_Security_UC_UserIdGroupId] UNIQUE CLUSTERED ([User_Id] ASC, [Group_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Ix_Usersecurity_UserID]
    ON [dbo].[User_Security]([User_Id] ASC);


GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_User_Security_Sync]
  	  ON [dbo].[User_Security]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;

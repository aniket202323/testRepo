CREATE TABLE [dbo].[User_Role_Security] (
    [User_Role_Security_Id] INT           IDENTITY (1, 1) NOT NULL,
    [GroupName]             VARCHAR (200) NULL,
    [Role_User_Id]          INT           NULL,
    [User_Id]               INT           NULL,
    [Domain]                VARCHAR (100) NULL,
    CONSTRAINT [UserRoleSecurity_FK_RoleUsers] FOREIGN KEY ([Role_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UserRoleSecurity_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


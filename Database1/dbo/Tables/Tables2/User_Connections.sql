CREATE TABLE [dbo].[User_Connections] (
    [User_Connection_Id] INT IDENTITY (1, 1) NOT NULL,
    [Language_Id]        INT NOT NULL,
    [SPID]               INT NOT NULL,
    [User_Id]            INT NOT NULL,
    CONSTRAINT [UserConnections_FK_LanguageId] FOREIGN KEY ([Language_Id]) REFERENCES [dbo].[Languages] ([Language_Id]),
    CONSTRAINT [UserConnections_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


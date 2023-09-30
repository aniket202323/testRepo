CREATE TABLE [dbo].[Crews] (
    [Id]             INT          IDENTITY (1, 1) NOT NULL,
    [Description]    VARCHAR (50) NULL,
    [IsDeleted]      BIT          NULL,
    [Modified_On]    DATETIME     NOT NULL,
    [Name]           VARCHAR (50) NOT NULL,
    [Update_User_Id] INT          NOT NULL,
    CONSTRAINT [PK_Crews] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Crews2] FOREIGN KEY ([Update_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UK_CrewName] UNIQUE NONCLUSTERED ([Name] ASC)
);


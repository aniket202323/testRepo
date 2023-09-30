CREATE TABLE [dbo].[Crew_Users_Mapping] (
    [Id]             INT      IDENTITY (1, 1) NOT NULL,
    [Crew_Id]        INT      NOT NULL,
    [End_Date]       DATETIME NULL,
    [Modified_On]    DATETIME NOT NULL,
    [Start_Date]     DATETIME NULL,
    [Update_User_Id] INT      NOT NULL,
    [User_Id]        INT      NOT NULL,
    CONSTRAINT [EmpCrew_PK_AttId] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Crew_Users_Mapping] FOREIGN KEY ([Crew_Id]) REFERENCES [dbo].[Crews] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Users_Mapping] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [FK_Users_Mapping2] FOREIGN KEY ([Update_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UK_EmpCrew_Data] UNIQUE NONCLUSTERED ([User_Id] ASC, [Crew_Id] ASC, [Start_Date] ASC)
);


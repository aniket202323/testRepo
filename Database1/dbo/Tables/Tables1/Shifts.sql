CREATE TABLE [dbo].[Shifts] (
    [Id]             INT          IDENTITY (1, 1) NOT NULL,
    [Description]    VARCHAR (50) NULL,
    [Duration]       FLOAT (53)   NULL,
    [End_Time]       DATETIME     NULL,
    [IsDeleted]      BIT          NOT NULL,
    [Modified_On]    DATETIME     NOT NULL,
    [Name]           VARCHAR (50) NOT NULL,
    [Start_Time]     DATETIME     NOT NULL,
    [Update_User_Id] INT          NOT NULL,
    [UTCOffset]      INT          NULL,
    CONSTRAINT [PK_Shifts] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Shifts2] FOREIGN KEY ([Update_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UK_ShiftName] UNIQUE NONCLUSTERED ([Name] ASC)
);


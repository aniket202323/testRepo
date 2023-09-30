CREATE TABLE [dbo].[PreEvents] (
    [Event_Num] VARCHAR (50) NOT NULL,
    [PU_Id]     INT          NOT NULL,
    [TimeStamp] DATETIME     NOT NULL,
    CONSTRAINT [PreEvents_PK_PUIdEventNum] PRIMARY KEY CLUSTERED ([PU_Id] ASC, [Event_Num] ASC),
    CONSTRAINT [PreEvents_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


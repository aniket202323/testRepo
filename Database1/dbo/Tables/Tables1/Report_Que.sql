CREATE TABLE [dbo].[Report_Que] (
    [Que_Id]      INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Schedule_Id] INT NOT NULL,
    CONSTRAINT [PK___1__24] PRIMARY KEY CLUSTERED ([Que_Id] ASC),
    CONSTRAINT [FK_Report_Que_1__11] FOREIGN KEY ([Schedule_Id]) REFERENCES [dbo].[Report_Schedule] ([Schedule_Id])
);


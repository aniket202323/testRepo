CREATE TABLE [dbo].[CrewSchedule_Crew_Mapping] (
    [Crew_Id]          INT NOT NULL,
    [Crew_Schedule_Id] INT NOT NULL,
    CONSTRAINT [PK_CrewSchedule_Crew_Mapping] PRIMARY KEY CLUSTERED ([Crew_Id] ASC, [Crew_Schedule_Id] ASC),
    CONSTRAINT [FK_CrewSchedule_Crew_Mapping_Crew_Schedule] FOREIGN KEY ([Crew_Schedule_Id]) REFERENCES [dbo].[Crew_Schedule] ([CS_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_CrewSchedule_Crew_Mapping_Crews] FOREIGN KEY ([Crew_Id]) REFERENCES [dbo].[Crews] ([Id]) ON DELETE CASCADE
);


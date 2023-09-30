CREATE TABLE [dbo].[Shifts_Crew_schedule_mapping] (
    [Crew_Schedule_Id] INT NOT NULL,
    [Shift_Id]         INT NOT NULL,
    CONSTRAINT [PK_Shifts_Crew_schedule_mapping] PRIMARY KEY CLUSTERED ([Crew_Schedule_Id] ASC, [Shift_Id] ASC),
    CONSTRAINT [FK_Shifts_Crew_schedule_mapping_Crew_Schedule] FOREIGN KEY ([Crew_Schedule_Id]) REFERENCES [dbo].[Crew_Schedule] ([CS_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Shifts_Crew_schedule_mapping_Shifts] FOREIGN KEY ([Shift_Id]) REFERENCES [dbo].[Shifts] ([Id]) ON DELETE CASCADE
);


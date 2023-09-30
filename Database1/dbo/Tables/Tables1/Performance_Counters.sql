CREATE TABLE [dbo].[Performance_Counters] (
    [Counter_Id]  INT           NOT NULL,
    [Description] VARCHAR (200) NOT NULL,
    [Name]        VARCHAR (30)  NOT NULL,
    [Object_Id]   INT           NOT NULL,
    CONSTRAINT [PK_Performance_Counters] PRIMARY KEY NONCLUSTERED ([Counter_Id] ASC, [Object_Id] ASC),
    CONSTRAINT [Performance_Counters_FK_ObjectId] FOREIGN KEY ([Object_Id]) REFERENCES [dbo].[Performance_Objects] ([Object_Id])
);


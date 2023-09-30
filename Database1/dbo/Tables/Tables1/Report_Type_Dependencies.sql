CREATE TABLE [dbo].[Report_Type_Dependencies] (
    [RTD_Id]         INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RDT_Id]         INT           NOT NULL,
    [Report_Type_Id] INT           NOT NULL,
    [Value]          VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_Report_Type_Dependencies] PRIMARY KEY NONCLUSTERED ([RTD_Id] ASC),
    CONSTRAINT [FK_Report_Type_Dependencies_Report_Dependency_Types] FOREIGN KEY ([RDT_Id]) REFERENCES [dbo].[Report_Dependency_Types] ([RDT_Id]),
    CONSTRAINT [FK_Report_Type_Dependencies_Report_Types] FOREIGN KEY ([Report_Type_Id]) REFERENCES [dbo].[Report_Types] ([Report_Type_Id]),
    CONSTRAINT [Report_Type_Dependencies_UC_TypeRDTValue] UNIQUE NONCLUSTERED ([Report_Type_Id] ASC, [RDT_Id] ASC, [Value] ASC)
);


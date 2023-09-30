CREATE TABLE [dbo].[Container_Class_Data] (
    [Container_Class_Id] INT NOT NULL,
    [Container_Id]       INT NOT NULL,
    [CCD_Id]             INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    CONSTRAINT [ContainerClassData_PK_CCDId] PRIMARY KEY NONCLUSTERED ([CCD_Id] ASC),
    CONSTRAINT [ContClsData_FK_ContainerId] FOREIGN KEY ([Container_Id]) REFERENCES [dbo].[Containers] ([Container_Id]),
    CONSTRAINT [ContClsData_FK_ContClssId] FOREIGN KEY ([Container_Class_Id]) REFERENCES [dbo].[Container_Classes] ([Container_Class_Id]),
    CONSTRAINT [ContCData_UC_ContCIdContId] UNIQUE CLUSTERED ([Container_Class_Id] ASC, [Container_Id] ASC)
);


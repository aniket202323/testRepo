CREATE TABLE [dbo].[Container_Class_Status_Transitions] (
    [CCT_Id]                  INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Container_Class_Id]      INT NOT NULL,
    [From_ContainerStatus_Id] INT NOT NULL,
    [To_ContainerStatus_Id]   INT NOT NULL,
    CONSTRAINT [ContClssStatusTrans_PK_CCTId] PRIMARY KEY NONCLUSTERED ([CCT_Id] ASC),
    CONSTRAINT [ContClssStatusTrans_FK_ContClssId] FOREIGN KEY ([Container_Class_Id]) REFERENCES [dbo].[Container_Classes] ([Container_Class_Id]),
    CONSTRAINT [ContClssStatusTrans_FK_FromContStatusId] FOREIGN KEY ([From_ContainerStatus_Id]) REFERENCES [dbo].[Container_Statuses] ([Container_Status_Id]),
    CONSTRAINT [ContClssStatusTrans_FK_ToContStatusId] FOREIGN KEY ([To_ContainerStatus_Id]) REFERENCES [dbo].[Container_Statuses] ([Container_Status_Id])
);


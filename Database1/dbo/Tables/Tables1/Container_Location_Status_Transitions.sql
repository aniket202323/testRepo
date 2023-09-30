CREATE TABLE [dbo].[Container_Location_Status_Transitions] (
    [CLST_Id]             INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Container_Status_Id] INT      NOT NULL,
    [ContLoc_Id]          INT      NOT NULL,
    [End_Time]            DATETIME NULL,
    [PU_Id]               INT      NOT NULL,
    [Start_Time]          DATETIME NOT NULL,
    CONSTRAINT [ContLocStatusTrans_PK_CLST_Id] PRIMARY KEY NONCLUSTERED ([CLST_Id] ASC),
    CONSTRAINT [ContLocStatTrans_FK_ContLocId] FOREIGN KEY ([ContLoc_Id]) REFERENCES [dbo].[Container_Location] ([ContLoc_Id]),
    CONSTRAINT [ContLocStatTrans_FK_ContStatusId] FOREIGN KEY ([Container_Status_Id]) REFERENCES [dbo].[Container_Statuses] ([Container_Status_Id])
);


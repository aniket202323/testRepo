CREATE TABLE [dbo].[Container_Class_EvtSubTypeData] (
    [Container_Class_Id] INT NOT NULL,
    [Event_Subtype_Id]   INT NOT NULL,
    [CCESD_Id]           INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    CONSTRAINT [ContClassSubType_PK_CCESDId] PRIMARY KEY NONCLUSTERED ([CCESD_Id] ASC),
    CONSTRAINT [ContClassSubType_FK_ContClssId] FOREIGN KEY ([Container_Class_Id]) REFERENCES [dbo].[Container_Classes] ([Container_Class_Id]),
    CONSTRAINT [ContClassSubType_UC_ContCIdESId] UNIQUE CLUSTERED ([Container_Class_Id] ASC, [Event_Subtype_Id] ASC)
);


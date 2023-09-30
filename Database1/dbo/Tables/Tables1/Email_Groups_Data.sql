CREATE TABLE [dbo].[Email_Groups_Data] (
    [EGR_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EG_Id]  INT NOT NULL,
    [ER_Id]  INT NOT NULL,
    CONSTRAINT [EmailGroupsData_PK_EGIdERId] PRIMARY KEY CLUSTERED ([EGR_Id] ASC),
    CONSTRAINT [EmailGroupsData_FK_EGId] FOREIGN KEY ([EG_Id]) REFERENCES [dbo].[Email_Groups] ([EG_Id]),
    CONSTRAINT [EmailGroupsData_FK_ERId] FOREIGN KEY ([ER_Id]) REFERENCES [dbo].[Email_Recipients] ([ER_Id]),
    CONSTRAINT [Email_Groups_Data_IX_UC_EGIdERId] UNIQUE NONCLUSTERED ([EG_Id] ASC, [ER_Id] ASC)
);


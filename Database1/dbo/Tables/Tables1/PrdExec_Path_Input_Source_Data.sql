CREATE TABLE [dbo].[PrdExec_Path_Input_Source_Data] (
    [PEPISD_Id]    INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PEPIS_Id]     INT NOT NULL,
    [Valid_Status] INT NULL,
    CONSTRAINT [PrdExecPathISData_PK_PEPISDId] PRIMARY KEY CLUSTERED ([PEPISD_Id] ASC),
    CONSTRAINT [PrdExecPathISData_FK_PrdExecPISource] FOREIGN KEY ([PEPIS_Id]) REFERENCES [dbo].[PrdExec_Path_Input_Sources] ([PEPIS_Id]),
    CONSTRAINT [PrdExecPathISData_FK_ProductionStatus] FOREIGN KEY ([Valid_Status]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id])
);


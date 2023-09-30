CREATE TABLE [dbo].[Local_PG_MachineTypes] (
    [MachineTypeId]          INT            IDENTITY (1, 1) NOT NULL,
    [MachineTypeDescription] NVARCHAR (100) NULL,
    CONSTRAINT [PK_Local_PG_MachineTypes] PRIMARY KEY CLUSTERED ([MachineTypeId] ASC)
);


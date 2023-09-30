CREATE TABLE [dbo].[Local_PG_MachineTypes_MachineTypeInputs] (
    [MachineType_MachineTypeInputsId] INT IDENTITY (1, 1) NOT NULL,
    [MachineTypeId]                   INT NOT NULL,
    [MachineTypeInputId]              INT NOT NULL,
    CONSTRAINT [PK_Local_PG_MachineTypes_MachineTypeInputs] PRIMARY KEY CLUSTERED ([MachineType_MachineTypeInputsId] ASC),
    CONSTRAINT [FK_Local_PG_MachineTypes_MachineTypeInputs_Local_PG_MachineTypeInputs] FOREIGN KEY ([MachineTypeInputId]) REFERENCES [dbo].[Local_PG_MachineTypeInputs] ([MachineTypeInputId]),
    CONSTRAINT [FK_Local_PG_MachineTypes_MachineTypeInputs_Local_PG_MachineTypes] FOREIGN KEY ([MachineTypeId]) REFERENCES [dbo].[Local_PG_MachineTypes] ([MachineTypeId])
);


CREATE TABLE [dbo].[Local_PG_MachineTypeInputs] (
    [MachineTypeInputId] INT            IDENTITY (1, 1) NOT NULL,
    [InputType]          NVARCHAR (10)  NOT NULL,
    [Description]        NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Local_PG_MachineTypeInputs] PRIMARY KEY CLUSTERED ([MachineTypeInputId] ASC)
);


CREATE TABLE [dbo].[Local_ULIDSerialNumber] (
    [PU_Id]        INT NOT NULL,
    [SerialNumber] INT CONSTRAINT [DF_Local_ULIDSerialNumber_SerialNumber] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Local_ULIDSerialNumber] PRIMARY KEY CLUSTERED ([PU_Id] ASC)
);


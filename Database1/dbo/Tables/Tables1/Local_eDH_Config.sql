CREATE TABLE [dbo].[Local_eDH_Config] (
    [ConfigId]    INT            IDENTITY (1, 1) NOT NULL,
    [ConfigName]  NVARCHAR (255) NULL,
    [ConfigValue] NVARCHAR (MAX) NOT NULL,
    [UserName]    NVARCHAR (255) NULL,
    [Global]      BIT            DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([ConfigId] ASC)
);


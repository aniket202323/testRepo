CREATE TABLE [dbo].[Activity_Configuration] (
    [Activity_Config_Id]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Activity_Config_Type_Id] INT            NOT NULL,
    [Activity_Config_Value]   NVARCHAR (100) NOT NULL,
    [Activity_Id]             BIGINT         NOT NULL,
    CONSTRAINT [ActivityConfig_PK_ActivityConfigId] PRIMARY KEY CLUSTERED ([Activity_Config_Id] ASC),
    CONSTRAINT [ActivityConfig_FK_ActivityId] FOREIGN KEY ([Activity_Id]) REFERENCES [dbo].[Activities] ([Activity_Id]),
    CONSTRAINT [ActivityConfig_FK_ConfigType] FOREIGN KEY ([Activity_Config_Type_Id]) REFERENCES [dbo].[Activity_Configuration_Types] ([Activity_Config_Type_Id])
);


GO
CREATE NONCLUSTERED INDEX [ActivityConfig_IDX_ActivityId]
    ON [dbo].[Activity_Configuration]([Activity_Id] ASC);


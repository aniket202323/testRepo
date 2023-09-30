CREATE TABLE [dbo].[Local_E2P_Global_ControlClasses] (
    [ControlClassId] INT           IDENTITY (1, 1) NOT NULL,
    [ComponentId]    INT           NOT NULL,
    [Type]           VARCHAR (25)  NOT NULL,
    [Name]           VARCHAR (255) NOT NULL,
    CONSTRAINT [LocalE2PGlobalControlClasses_PK_ControlClassId] PRIMARY KEY CLUSTERED ([ControlClassId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_ControlClasses_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);


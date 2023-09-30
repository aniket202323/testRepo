CREATE TABLE [ecs].[pa_customcalls_configuration] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [action_id]        BIGINT        NOT NULL,
    [action_type_id]   BIGINT        NOT NULL,
    [config_data]      VARCHAR (MAX) NULL,
    [deleted]          BIT           NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME      NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME      NULL,
    CONSTRAINT [PK_pa_customcalls_configuration] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_pa_customcalls_configuration_ActionId_pa_customcalls_action_id] FOREIGN KEY ([action_id]) REFERENCES [ecs].[pa_customcalls_action] ([id]),
    CONSTRAINT [FK_pa_customcalls_configuration_ActionTypeId_pa_customcalls_actionType_id] FOREIGN KEY ([action_type_id]) REFERENCES [ecs].[pa_customcalls_actiontype] ([id]),
    CONSTRAINT [UC_pa_customcalls_configuration] UNIQUE NONCLUSTERED ([id] ASC, [action_id] ASC, [action_type_id] ASC, [deleted] ASC)
);


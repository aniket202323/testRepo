CREATE TABLE [ecs].[pa_customconfig_parameter] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [name]             VARCHAR (50)  NULL,
    [description]      VARCHAR (200) NULL,
    [data_type]        VARCHAR (20)  NULL,
    [created_by]       VARCHAR (50)  NOT NULL,
    [created_on]       DATETIME      NOT NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME      NULL,
    CONSTRAINT [PK_pa_customconfig_parameter_id] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UC_pa_customconfig_parameter] UNIQUE NONCLUSTERED ([id] ASC, [name] ASC, [data_type] ASC)
);


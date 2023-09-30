CREATE TABLE [ecs].[pa_customcalls_actiontype] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [name]             VARCHAR (50)  NOT NULL,
    [description]      VARCHAR (200) NULL,
    [deleted]          BIT           NOT NULL,
    [created_by]       VARCHAR (50)  NOT NULL,
    [created_on]       DATETIME      NOT NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME      NULL,
    CONSTRAINT [PK_pa_customcalls_actiontype] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UC_pa_customcalls_actionType] UNIQUE NONCLUSTERED ([id] ASC, [name] ASC, [deleted] ASC)
);

